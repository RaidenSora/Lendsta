import 'package:flutter/material.dart';
import '../data/loans_db.dart';
import '../utils/format.dart';

class SummaryCard extends StatelessWidget {
  final LoanSummary summary;
  final bool allTime;
  const SummaryCard({super.key, required this.summary, required this.allTime});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final columns =
        width < 360
            ? 1
            : width < 720
            ? 2
            : 3;
    const gap = 14.0;

    Widget tile(
      String label,
      String value,
      IconData icon, {
      Color? badgeColor,
    }) {
      final accent = badgeColor ?? cs.primary;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: cs.surfaceVariant.withOpacity(.25),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(.7),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withOpacity(.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: .1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: cs.surface,
      surfaceTintColor: cs.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Summary',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                Tooltip(
                  message:
                      allTime
                          ? 'Aggregated totals for all time'
                          : 'Aggregated totals for the selected date range',
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (_, c) {
                final tileW = (c.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: tileW,
                      child: tile(
                        'Loans',
                        '${summary.totalCount}',
                        Icons.list_alt,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: tile(
                        'Total Amount',
                        '₱${NumberFormatHelper.currency(summary.totalAmount)}',
                        Icons.payments_outlined,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: tile(
                        'Avg Interest',
                        '${summary.avgInterest.toStringAsFixed(2)}%',
                        Icons.percent,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: tile(
                        'Paid',
                        '${summary.paidCount}',
                        Icons.check_circle,
                        badgeColor: Colors.green,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: tile(
                        'Unpaid Amount',
                        '₱${NumberFormatHelper.currency(summary.unpaidAmount)}',
                        Icons.account_balance_wallet_outlined,
                        badgeColor: Colors.purple,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
