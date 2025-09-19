import 'package:flutter/material.dart';
import '../models/loan.dart';
import 'status_pill.dart';
import 'meta_chip.dart';
import '../data/loans_db.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onOpen;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onMarkPaid;
  final VoidCallback onDelete;

  const LoanCard({
    super.key,
    required this.loan,
    required this.onOpen,
    this.onRecordPayment,
    required this.onMarkPaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amountStr = loan.amount.toStringAsFixed(2);
    String yyyyMmDd(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final dueStr = yyyyMmDd(loan.dueDate);

    return Semantics(
      button: true,
      label:
          'Loan for ${loan.borrower}, ${loan.item}, ₱$amountStr, due $dueStr',
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: .6),
            width: .7,
          ),
        ),
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    loan.borrower.isNotEmpty
                        ? loan.borrower[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: title + status + menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loan.borrower,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: .2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loan.item,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill(status: loan.status),
                          const SizedBox(width: 4),
                          _MoreMenu(
                            onRecordPayment: onRecordPayment,
                            onMarkPaid: onMarkPaid,
                            onDelete: onDelete,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Always show a compact summary when collapsed
                      Row(
                        children: [
                          Text(
                            '₱$amountStr',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: cs.primary,
                              letterSpacing: .2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          MetaChip(icon: Icons.event, label: dueStr),
                          const SizedBox(width: 6),
                          MetaChip(
                            icon: Icons.percent,
                            label: '${loan.interest.toStringAsFixed(2)}%',
                          ),
                          if (loan.imagePath != null) ...[
                            const SizedBox(width: 6),
                            const MetaChip(icon: Icons.attachment, label: 'Attachment'),
                          ],
                        ],
                      ),

                      // Progress (paid vs remaining) for unpaid loans
                      if (loan.status != 'paid' && loan.id != null) ...[
                        const SizedBox(height: 8),
                        FutureBuilder<double>(
                          future: LoansDatabase().getPaidTotalForLoan(loan.id!),
                          builder: (context, snap) {
                            final paid = (snap.data ?? 0).toDouble();
                            final total = loan.amount <= 0 ? 1.0 : loan.amount;
                            final progress = (paid / total).clamp(0.0, 1.0);
                            final cs2 = Theme.of(context).colorScheme;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: snap.connectionState == ConnectionState.waiting ? null : progress,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Paid ₱${paid.toStringAsFixed(2)} of ₱${loan.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: cs2.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final VoidCallback? onRecordPayment;
  final VoidCallback? onMarkPaid;
  final VoidCallback onDelete;
  const _MoreMenu({this.onRecordPayment, required this.onMarkPaid, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      offset: const Offset(0, 28),
      itemBuilder:
          (context) => [
            if (onRecordPayment != null)
              const PopupMenuItem(
                value: 'pay',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.payments_outlined),
                  title: Text('Record payment'),
                ),
              ),
            if (onMarkPaid != null)
              const PopupMenuItem(
                value: 'paid',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.check_circle),
                  title: Text('Mark as paid'),
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.delete_outline),
                title: Text('Delete'),
              ),
            ),
          ],
      onSelected: (v) {
        if (v == 'pay' && onRecordPayment != null) onRecordPayment!();
        if (v == 'paid' && onMarkPaid != null) onMarkPaid!();
        if (v == 'delete') onDelete();
      },
      child: IconButton(onPressed: null, icon: const Icon(Icons.more_vert)),
    );
  }
}
