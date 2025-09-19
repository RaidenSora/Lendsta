import 'dart:io';
import 'package:flutter/material.dart';

import '../data/loans_db.dart';
import '../models/loan.dart';

// Shared widgets
import '../widgets/loan_card.dart';
import '../widgets/loan_list_skeleton.dart';
import '../widgets/state_card.dart';
import '../widgets/status_pill.dart';
import '../widgets/person_summary_card.dart';
import '../sheets/add_payment_sheet.dart';

class PersonDetailPage extends StatefulWidget {
  final String personName;
  const PersonDetailPage({super.key, required this.personName});

  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends State<PersonDetailPage> {
  final LoansDatabase _db = LoansDatabase();

  // Range state
  bool _allTime = false;
  late DateTime _start;
  late DateTime _end;

  late Future<List<Loan>> _loansFuture;
  late Future<PersonSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
    _refresh();
  }

  void _refresh() {
    setState(() {
      final start = _allTime ? null : _start;
      final end = _allTime ? null : _end;
      _loansFuture = _db.getLoansForPersonBetween(
        widget.personName,
        start: start,
        end: end,
      );
      _summaryFuture = _db.getSummaryForPersonBetween(
        widget.personName,
        start: start,
        end: end,
      );
    });
  }

  Future<void> _pickRange() async {
    // If currently "All time", turn it off so the picker applies a range
    if (_allTime) {
      setState(() => _allTime = false);
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      helpText: 'Select date range',
      saveText: 'Apply',
    );
    if (picked == null) return;
    _start = DateTime(picked.start.year, picked.start.month, picked.start.day);
    _end = DateTime(picked.end.year, picked.end.month, picked.end.day);
    if (!mounted) return;
    _refresh();
  }

  void _toggleAllTime(bool value) {
    setState(() => _allTime = value);
    _refresh();
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
              child: Icon(Icons.person, color: cs.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.personName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: .2,
                    ),
                  ),
                  Text(
                    _allTime
                        ? 'All time'
                        : 'Range: ${_formatRangeShort(_start, _end)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Keep the AppBar actions minimal; chips live in the bottom bar now.
        actions: const [SizedBox(width: 8)],
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
                  // Current range / all-time chip (read-only)
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

                  // NEW: "All time" button (FilterChip) inline with "Change range"
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

                  // "Change range" stays available; if all-time is ON, we turn it OFF then open picker
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
          FutureBuilder<PersonSummary>(
            future: _summaryFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Summary error: ${snap.error}'),
                );
              }
              final s =
                  snap.data ??
                  const PersonSummary(
                    totalCount: 0,
                    totalAmount: 0,
                    avgInterest: 0,
                    paidCount: 0,
                    unpaidAmount: 0,
                  );

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: PersonSummaryCard(summary: s),
              );
            },
          ),

          const Divider(height: 1),

          // Loans list
          Expanded(
            child: FutureBuilder<List<Loan>>(
              future: _loansFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoanListSkeleton();
                }
                if (snap.hasError) {
                  return StateCard(
                    icon: Icons.error_outline,
                    title: 'Something went wrong',
                    message: '${snap.error}',
                    actions: [
                      FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  );
                }
                final loans = snap.data ?? [];
                if (loans.isEmpty) {
                  return StateCard(
                    icon: Icons.inbox_outlined,
                    title: 'No loans for this selection',
                    message:
                        _allTime
                            ? 'No loans found for ${widget.personName}.'
                            : 'Try widening the date range.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: loans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final loan = loans[i];
                    return LoanCard(
                      loan: loan,
                      onOpen: () => _openLoan(loan),
                      onRecordPayment:
                          loan.status == 'paid'
                              ? null
                              : () async {
                                  if (loan.id == null) return;
                                  final paid = await _db.getPaidTotalForLoan(loan.id!);
                                  if (!mounted) return;
                                  await showAddPaymentSheet(
                                    context: context,
                                    loan: loan,
                                    paidTotal: paid,
                                    onSave: (p) async => _db.insertPayment(p),
                                  );
                                  if (!mounted) return;
                                  _refresh();
                                },
                      onMarkPaid:
                          loan.status == 'paid'
                              ? null
                              : () async {
                                await _db.updateLoanStatus(loan.id!, 'paid');
                                if (!mounted) return;
                                _refresh();
                              },
                      onDelete: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text('Delete loan?'),
                                content: Text(
                                  'Delete "${loan.borrower} • ${loan.item}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                        );
                        if (ok == true) {
                          await _db.deleteLoan(loan.id!);
                          if (!mounted) return;
                          _refresh();
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Bottom sheet for a single loan ----------
  void _openLoan(Loan loan) {
    final cs = Theme.of(context).colorScheme;
    final amountStr = loan.amount.toStringAsFixed(2);
    final dueStr =
        '${loan.dueDate.year}-${loan.dueDate.month.toString().padLeft(2, '0')}-${loan.dueDate.day.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FutureBuilder<double>(
            future: loan.id == null ? Future.value(0) : _db.getPaidTotalForLoan(loan.id!),
            builder: (context, snap) {
              final paid = (snap.data ?? 0).toDouble();
              final remaining = (loan.amount - paid).clamp(0, double.infinity);
              return Column(
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
                  StatusPill(status: loan.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Amount: ₱$amountStr',
                style: TextStyle(color: cs.onSurface),
              ),
              Text(
                'Interest: ${loan.interest.toStringAsFixed(2)}%',
                style: TextStyle(color: cs.onSurface),
              ),
              Text('Date: $dueStr', style: TextStyle(color: cs.onSurface)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: .7), width: .6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paid: ₱${paid.toStringAsFixed(2)}', style: TextStyle(color: cs.onSurface)),
                          Text('Remaining: ₱${remaining.toStringAsFixed(2)}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    if (loan.status != 'paid')
                      FilledButton.tonalIcon(
                        onPressed: snap.connectionState == ConnectionState.waiting
                            ? null
                            : () async {
                                if (loan.id == null) return;
                                await showAddPaymentSheet(
                                  context: context,
                                  loan: loan,
                                  paidTotal: paid,
                                  onSave: (p) async => _db.insertPayment(p),
                                );
                                if (!mounted) return;
                                Navigator.of(context).pop();
                                _refresh();
                              },
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Record payment'),
                      ),
                  ],
                ),
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
                Text(
                  'No attachment',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
              );
            },
          ),
          ),
        );
      },
    );
  }
}
