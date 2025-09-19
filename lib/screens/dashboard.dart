import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../data/loans_db.dart';
import '../models/loan.dart';
import '../models/person.dart';
import '../sheets/add_loan_sheet.dart';
import '../sheets/add_payment_sheet.dart';
import '../widgets/loan_card.dart';
import '../widgets/loan_list_skeleton.dart';
import '../widgets/state_card.dart';
import '../widgets/summary_card.dart';
import 'people_page.dart';
import '../utils/csv_export.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<Dashboard> {
  final LoansDatabase _db = LoansDatabase();

  // Range state
  bool _allTime = false;
  late DateTime _start;
  late DateTime _end;

  late Future<List<Loan>> _loansFuture;
  late Future<LoanSummary> _summaryFuture;

  List<Person> _people = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
    _refresh();
    _loadPeople();
  }

  void _refresh() {
    setState(() {
      final DateTime? start = _allTime ? null : _start;
      final DateTime? end = _allTime ? null : _end;
      _loansFuture = _db.getLoansBetween(start, end);
      _summaryFuture = _db.getSummaryBetween(start, end);
    });
  }

  Future<void> _loadPeople() async {
    final list = await _db.getAllPeople();
    if (!mounted) return;
    setState(() => _people = list);
  }

  Future<void> _pickRange() async {
    // If currently all-time, turn it off so a picked range applies
    if (_allTime) {
      setState(() => _allTime = false);
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      helpText: 'Select loan summary range',
      saveText: 'Apply',
    );
    if (picked == null) return;
    _start = DateTime(picked.start.year, picked.start.month, picked.start.day);
    _end = DateTime(picked.end.year, picked.end.month, picked.end.day);
    if (!mounted) return;
    _refresh();
  }

  void _toggleAllTime(bool v) {
    setState(() => _allTime = v);
    _refresh();
  }

  void _openLoan(Loan loan) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        final amountStr = loan.amount.toStringAsFixed(2);
        final dueStr =
            '${loan.dueDate.year}-${loan.dueDate.month.toString().padLeft(2, '0')}-${loan.dueDate.day.toString().padLeft(2, '0')}';

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        loan.borrower.isNotEmpty
                            ? loan.borrower[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${loan.borrower} • ${loan.item}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Amount: ₱$amountStr'),
                Text('Interest: ${loan.interest.toStringAsFixed(2)}%'),
                Text('Date: $dueStr'),
                const SizedBox(height: 8),
                FutureBuilder<double>(
                  future:
                      loan.id == null
                          ? Future.value(0)
                          : _db.getPaidTotalForLoan(loan.id!),
                  builder: (context, snap) {
                    final paid = (snap.data ?? 0).toDouble();
                    final remaining = (loan.amount - paid).clamp(
                      0,
                      double.infinity,
                    );
                    final cs = Theme.of(context).colorScheme;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: .35,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: .7),
                          width: .6,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Paid: ₱${paid.toStringAsFixed(2)}'),
                                Text(
                                  'Remaining: ₱${remaining.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (loan.status != 'paid')
                            FilledButton.tonalIcon(
                              onPressed:
                                  snap.connectionState ==
                                          ConnectionState.waiting
                                      ? null
                                      : () async {
                                        if (loan.id == null) return;
                                        await showAddPaymentSheet(
                                          context: context,
                                          loan: loan,
                                          paidTotal: paid,
                                          onSave:
                                              (p) async => _db.insertPayment(p),
                                        );
                                        if (!mounted) return;
                                        Navigator.of(context).pop();
                                        _refresh();
                                        _snack('Payment recorded');
                                      },
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text('Record payment'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (loan.imagePath != null)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => Dialog(
                              child: InteractiveViewer(
                                child: Image.file(File(loan.imagePath!)),
                              ),
                            ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(loan.imagePath!),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  const Text('No attachment'),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (loan.status != 'paid')
                        FilledButton.icon(
                          onPressed: () async {
                            await _db.updateLoanStatus(loan.id!, 'paid');
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            _refresh();
                            _snack('Marked as paid');
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark as paid'),
                        ),
                      if (loan.status != 'paid') const SizedBox(width: 8),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _delete(loan);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1200)),
  );

  Future<void> _delete(Loan loan) async {
    if (loan.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete loan?'),
            content: Text('Delete "${loan.borrower} • ${loan.item}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    await _db.deleteLoan(loan.id!);
    if (!mounted) return;
    _refresh();
    _snack('Loan deleted');
  }

  String _formatRangeShort(DateTime s, DateTime e) {
    String mmdd(DateTime d) =>
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    final sameYear = s.year == e.year;
    final yearPart = sameYear ? '${s.year}' : '${s.year}-${e.year}';
    return '${mmdd(s)}–${mmdd(e)} $yearPart';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 4,
        centerTitle: false,
        titleSpacing: 12,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary.withValues(alpha: .12),
              child: Icon(Icons.list_alt, color: cs.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lendsta',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: .2,
                  ),
                ),
                Text(
                  'Loan Ledger',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Export CSV',
            waitDuration: const Duration(milliseconds: 400),
            child: IconButton.filledTonal(
              onPressed: _exportCsv,
              icon: const Icon(Icons.download_outlined),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Manage people',
            waitDuration: const Duration(milliseconds: 400),
            child: IconButton.filledTonal(
              onPressed: () async {
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const PeoplePage()));
                if (!mounted) return;
                _loadPeople();
              },
              icon: const Icon(Icons.people_alt_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Range / All-time indicator chip (read-only)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: .8),
                        width: .7,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _allTime ? Icons.all_inclusive : Icons.schedule,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _allTime
                              ? 'All time'
                              : _formatRangeShort(_start, _end),
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // NEW: "All time" FilterChip inline
                  FilterChip(
                    selected: _allTime,
                    onSelected: (v) => _toggleAllTime(v),
                    label: const Text('All time'),
                    avatar: const Icon(Icons.all_inclusive, size: 16),
                    selectedColor: cs.primary.withValues(alpha: .14),
                    checkmarkColor: cs.primary,
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: .8),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),

                  // Change range chip (always visible; if you prefer, disable when all-time)
                  ActionChip(
                    avatar: const Icon(Icons.edit_calendar, size: 16),
                    label: const Text('Change range'),
                    onPressed: _pickRange,
                    visualDensity: VisualDensity.compact,
                    labelStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // Summary
          FutureBuilder<LoanSummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Summary error: ${snapshot.error}'),
                );
              }
              final s =
                  snapshot.data ??
                  const LoanSummary(
                    totalCount: 0,
                    totalAmount: 0,
                    avgInterest: 0,
                    paidCount: 0,
                    unpaidAmount: 0,
                  );
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                // pass allTime so your SummaryCard can optionally show a badge or hint
                child: SummaryCard(summary: s, allTime: _allTime),
              );
            },
          ),
          const Divider(height: 1),

          // Loans list
          Expanded(
            child: FutureBuilder<List<Loan>>(
              future: _loansFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoanListSkeleton();
                }
                if (snapshot.hasError) {
                  return StateCard(
                    icon: Icons.error_outline,
                    title: 'Something went wrong',
                    message: '${snapshot.error}',
                    actions: [
                      FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  );
                }
                final loans = snapshot.data ?? [];
                if (loans.isEmpty) {
                  return StateCard(
                    icon: Icons.inbox_outlined,
                    title:
                        _allTime
                            ? 'No loans (all time)'
                            : 'No loans in this date range',
                    message:
                        _allTime
                            ? 'Add your first loan to get started.'
                            : 'Try changing the date range or add a new loan.',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: _pickRange,
                        icon: const Icon(Icons.date_range),
                        label: const Text('Change range'),
                      ),
                      const SizedBox(width: 0),
                      FilledButton.icon(
                        onPressed: _showAdd,
                        icon: const Icon(Icons.add),
                        label: const Text('Add loan'),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: loans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder:
                      (_, i) => LoanCard(
                        loan: loans[i],
                        onOpen: () => _openLoan(loans[i]),
                        onRecordPayment:
                            loans[i].status == 'paid'
                                ? null
                                : () async {
                                  final loan = loans[i];
                                  if (loan.id == null) return;
                                  final paid = await _db.getPaidTotalForLoan(
                                    loan.id!,
                                  );
                                  if (!mounted) return;
                                  await showAddPaymentSheet(
                                    context: context,
                                    loan: loan,
                                    paidTotal: paid,
                                    onSave: (p) async => _db.insertPayment(p),
                                  );
                                  if (!mounted) return;
                                  _refresh();
                                  _snack('Payment recorded');
                                },
                        onMarkPaid:
                            loans[i].status == 'paid'
                                ? null
                                : () => _markPaid(loans[i]),
                        onDelete: () => _delete(loans[i]),
                      ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Future<void> _showAdd() async {
    await showAddLoanSheet(
      context: context,
      people: _people,
      onSave: (loan) async => _db.insertLoan(loan),
    );
    if (!mounted) return;
    _refresh();
    _snack('Loan added');
  }

  Future<void> _markPaid(Loan loan) async {
    if (loan.id == null) return;
    await _db.updateLoanStatus(loan.id!, 'paid');
    if (!mounted) return;
    _refresh();
    _snack('Marked as paid');
  }

  Future<void> _exportCsv() async {
    // Fetch loans for current range
    final DateTime? start = _allTime ? null : _start;
    final DateTime? end = _allTime ? null : _end;
    final loans = await _db.getLoansBetween(start, end);
    final csv = loansToCsv(loans);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Export CSV'),
          content: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview (copy or save to file):',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csv,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (!context.mounted) return;
                Navigator.of(context).pop();
                _snack('CSV copied to clipboard');
              },
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Copy'),
            ),
            TextButton.icon(
              onPressed: () async {
                await _shareCsv(csv);
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final savedPath = await _saveCsvToDownloads(csv);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                _snack(
                  savedPath == null
                      ? 'Saved to app storage'
                      : 'Saved: $savedPath',
                );
              },
              icon: const Icon(Icons.save_alt),
              label: const Text('Save to Downloads'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _saveCsvToDownloads(String csv) async {
    final ts = DateTime.now();
    final fname =
        'loans_export_${ts.year.toString().padLeft(4, '0')}'
        '${ts.month.toString().padLeft(2, '0')}'
        '${ts.day.toString().padLeft(2, '0')}_'
        '${ts.hour.toString().padLeft(2, '0')}'
        '${ts.minute.toString().padLeft(2, '0')}'
        '${ts.second.toString().padLeft(2, '0')}';

    final bytes = Uint8List.fromList(utf8.encode(csv));

    // Android method channel to save into Downloads with MediaStore (primary path)
    try {
      const ch = MethodChannel('listah/downloads');
      final saved = await ch.invokeMethod<String>('saveCsv', {
        'name': fname,
        'bytes': bytes,
      });
      if (saved != null && saved.isNotEmpty) return saved;
    } catch (_) {
      // ignore and fallback
    }

    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final filePath = p.join(downloadsDir.path, '$fname.csv');
        await File(filePath).writeAsString(csv);
        return filePath;
      }
    } catch (_) {}

    // Last resort: app storage next to database, so it’s still retrievable
    try {
      final dir = await getDatabasesPath();
      final filePath = p.join(dir, '$fname.csv');
      await File(filePath).writeAsString(csv);
      return filePath;
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareCsv(String csv) async {
    final ts = DateTime.now();
    final fname =
        'loans_export_${ts.year.toString().padLeft(4, '0')}'
        '${ts.month.toString().padLeft(2, '0')}'
        '${ts.day.toString().padLeft(2, '0')}_'
        '${ts.hour.toString().padLeft(2, '0')}'
        '${ts.minute.toString().padLeft(2, '0')}'
        '${ts.second.toString().padLeft(2, '0')}.csv';

    try {
      final tmpDir = await getTemporaryDirectory();
      final path = p.join(tmpDir.path, fname);
      final file = File(path);
      await file.writeAsString(csv);

      final xFile = XFile(path, name: fname, mimeType: 'text/csv');
      await Share.shareXFiles([xFile], text: 'Loans export');
    } catch (e) {
      if (!mounted) return;
      _snack('Share failed: $e');
    }
  }
}
