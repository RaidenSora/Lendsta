import 'package:flutter/material.dart';
import '../models/loan.dart';
import 'status_pill.dart';
import 'meta_chip.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onOpen;
  final VoidCallback? onMarkPaid;
  final VoidCallback onDelete;

  const LoanCard({
    super.key,
    required this.loan,
    required this.onOpen,
    required this.onMarkPaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amountStr = loan.amount.toStringAsFixed(2);
    final dueStr =
        '${loan.dueDate.year}-${loan.dueDate.month.toString().padLeft(2, '0')}-${loan.dueDate.day.toString().padLeft(2, '0')}';

    return Semantics(
      button: true,
      label:
          'Loan for ${loan.borrower}, ${loan.item}, ₱$amountStr, due $dueStr',
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant.withOpacity(.6), width: .6),
        ),
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primary.withOpacity(.10),
                    child: Text(
                      loan.borrower.isNotEmpty
                          ? loan.borrower[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${loan.borrower} • ${loan.item}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill(status: loan.status),
                          const SizedBox(width: 4),
                          _MoreMenu(onMarkPaid: onMarkPaid, onDelete: onDelete),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '₱$amountStr',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                          MetaChip(
                            icon: Icons.percent,
                            label: '${loan.interest.toStringAsFixed(2)}%',
                          ),
                          MetaChip(icon: Icons.event, label: dueStr),
                          if (loan.imagePath != null)
                            const MetaChip(
                              icon: Icons.attachment,
                              label: 'Attachment',
                            ),
                        ],
                      ),
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
  final VoidCallback? onMarkPaid;
  final VoidCallback onDelete;
  const _MoreMenu({required this.onMarkPaid, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      offset: const Offset(0, 28),
      itemBuilder:
          (context) => [
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
        if (v == 'paid' && onMarkPaid != null) onMarkPaid!();
        if (v == 'delete') onDelete();
      },
      child: IconButton(onPressed: null, icon: const Icon(Icons.more_vert)),
    );
  }
}
