import 'package:flutter/material.dart';

class LoanListSkeleton extends StatelessWidget {
  const LoanListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget line({double h = 12, double w = 120}) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder:
          (_, __) => Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: cs.outlineVariant.withOpacity(.6),
                width: .6,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.surfaceVariant.withOpacity(.8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        line(w: 180),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            line(w: 80),
                            const SizedBox(width: 8),
                            line(w: 60),
                            const SizedBox(width: 8),
                            line(w: 70),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
