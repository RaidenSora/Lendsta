import 'package:flutter/material.dart';

import '../models/loan.dart';
import '../models/payment.dart';

typedef OnSavePayment = Future<void> Function(Payment payment);

Future<void> showAddPaymentSheet({
  required BuildContext context,
  required Loan loan,
  required double paidTotal,
  required OnSavePayment onSave,
}) async {
  final formKey = GlobalKey<FormState>();
  DateTime date = DateTime.now();
  final amountController = TextEditingController();

  final total = loan.amount;
  final remaining = (total - paidTotal).clamp(0, double.infinity);
  amountController.text = remaining.toStringAsFixed(2);

  final cs = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setModalState) {
        Future<void> pickDate() async {
          final picked = await showDatePicker(
            context: ctx,
            firstDate: DateTime(2020, 1, 1),
            lastDate: DateTime(2100, 12, 31),
            initialDate: date,
            helpText: 'Payment date',
          );
          if (picked != null) {
            date = DateTime(picked.year, picked.month, picked.day);
            setModalState(() {});
          }
        }

        String yyyyMmDd(DateTime d) =>
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 8,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.payments, color: cs.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Record Payment',
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${loan.borrower} • ${loan.item}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: .7), width: .6),
                    ),
                    child: DefaultTextStyle(
                      style: text.bodyMedium!,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Total:', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              const Spacer(),
                              Text('₱${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Paid so far:', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              const Spacer(),
                              Text('₱${paidTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Remaining:', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              const Spacer(),
                              Text('₱${remaining.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Payment amount (₱)',
                      prefixIcon: Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final x = double.tryParse(v ?? '');
                      if (x == null || x <= 0) return 'Enter a valid amount';
                      if (x > remaining + 1e-6) return 'Cannot exceed remaining';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: .7), width: .6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            yyyyMmDd(date),
                            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Pick date'),
                          visualDensity: VisualDensity.compact,
                          onPressed: pickDate,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save payment'),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final amount = double.parse(amountController.text.trim());
                        await onSave(Payment(
                          loanId: loan.id!,
                          amount: amount,
                          date: date,
                        ));
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}

