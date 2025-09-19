import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/loan.dart';
import '../models/person.dart';
import '../sheets/borrower_picker_sheet.dart';

typedef OnSaveLoan = Future<void> Function(Loan loan);

Future<void> showAddLoanSheet({
  required BuildContext context,
  required List<Person> people,
  required OnSaveLoan onSave,
}) async {
  final formKey = GlobalKey<FormState>();

  String? borrower;
  String item = '';
  double amount = 0;
  double interest = 0;
  DateTime date = DateTime.now();
  String? imagePath;

  final itemController = TextEditingController();
  final amountController = TextEditingController();
  final interestController = TextEditingController(text: '0');

  final cs = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          // ---- Actions ----
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: ctx,
              firstDate: DateTime(2020, 1, 1),
              lastDate: DateTime(2100, 12, 31),
              initialDate: date,
              helpText: 'Select date',
            );
            if (picked != null) {
              date = DateTime(picked.year, picked.month, picked.day);
              setModalState(() {});
            }
          }

          Future<void> pickImage(ImageSource source) async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
              source: source,
              imageQuality: 85,
            );
            if (picked != null) {
              imagePath = picked.path;
              setModalState(() {});
            }
          }

          Future<void> openBorrowerPicker() async {
            final selection = await showBorrowerPickerSheet(ctx, people);
            if (selection != null) {
              borrower = selection;
              setModalState(() {});
            }
          }

          // ---- Widgets (small helpers) ----
          String yyyyMmDd(DateTime d) =>
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

          Widget sectionLabel(String label) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: text.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: .2,
              ),
            ),
          );

          Widget borrowerField() {
            return Semantics(
              button: true,
              label: 'Borrower, ${borrower ?? 'none selected'}',
              child: GestureDetector(
                onTap: openBorrowerPicker,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Borrower',
                    prefixIcon: const Icon(Icons.person_search),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(
                    borrower ?? 'Tap to select',
                    style: TextStyle(
                      color:
                          borrower == null
                              ? Theme.of(ctx).hintColor
                              : Theme.of(ctx).colorScheme.onSurface,
                      fontWeight:
                          borrower == null ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }

          Widget dateRow() {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: .7),
                  width: .6,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      yyyyMmDd(date),
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Compact actions
                  Wrap(
                    spacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Pick date'),
                        visualDensity: VisualDensity.compact,
                        onPressed: pickDate,
                      ),
                      if (date.difference(DateTime.now()).inDays != 0)
                        ActionChip(
                          avatar: const Icon(Icons.today, size: 16),
                          label: const Text('Today'),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            date = DateTime.now();
                            setModalState(() {});
                          },
                        ),
                    ],
                  ),
                ],
              ),
            );
          }

          Widget attachmentRow() {
            final hasImg = imagePath != null;
            return Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () => pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 12),
                if (hasImg)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              File(
                                imagePath!,
                              ).path.split(Platform.pathSeparator).last,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: () {
                              imagePath = null;
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.close),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }

          // Use SingleChildScrollView to prevent bottom overflow on small screens.
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---------- Header ----------
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
                          child: Icon(
                            Icons.receipt_long,
                            color: cs.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Add Loan',
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Close',
                          child: IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fill the details below to record a new loan.',
                      style: text.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---------- Borrower ----------
                    sectionLabel('Borrower'),
                    borrowerField(),
                    const SizedBox(height: 14),

                    // ---------- Date ----------
                    sectionLabel('Date'),
                    dateRow(),
                    const SizedBox(height: 14),

                    // ---------- Item ----------
                    sectionLabel('Item'),
                    TextFormField(
                      controller: itemController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Laptop, Cash, Tools…',
                        labelText: 'Item borrowed',
                        prefixIcon: Icon(Icons.inventory_2),
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Item is required'
                                  : null,
                      onChanged: (v) => item = v.trim(),
                    ),
                    const SizedBox(height: 14),

                    // ---------- Amount & Interest (responsive side-by-side) ----------
                    // ---------- Amount & Interest (responsive side-by-side) ----------
                    LayoutBuilder(
                      builder: (_, c) {
                        final twoCols = c.maxWidth > 420;

                        // Build raw fields (no Expanded here)
                        final amountField = TextFormField(
                          controller: amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount (₱)',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.payments),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            final x = double.tryParse(v ?? '');
                            if (x == null || x <= 0) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                          onChanged: (v) => amount = double.tryParse(v) ?? 0,
                        );

                        final interestField = TextFormField(
                          controller: interestController,
                          decoration: const InputDecoration(
                            labelText: 'Interest % (optional)',
                            hintText: '0',
                            prefixIcon: Icon(Icons.percent),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (v) => interest = double.tryParse(v) ?? 0,
                        );

                        // Use Row+Expanded on wide; plain Column on narrow
                        if (twoCols) {
                          return Row(
                            children: [
                              Expanded(child: amountField),
                              const SizedBox(width: 12),
                              Expanded(child: interestField),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              amountField,
                              const SizedBox(height: 12),
                              interestField,
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    // ---------- Attachment ----------
                    sectionLabel('Attachment'),
                    attachmentRow(),
                    const SizedBox(height: 18),

                    // ---------- Save ----------
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        onPressed: () async {
                          if (borrower == null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a borrower.'),
                                duration: Duration(milliseconds: 1200),
                              ),
                            );
                            return;
                          }
                          item = itemController.text.trim();
                          amount =
                              double.tryParse(amountController.text.trim()) ??
                              0;
                          interest =
                              double.tryParse(interestController.text.trim()) ??
                              0;

                          if (!formKey.currentState!.validate()) return;

                          await onSave(
                            Loan(
                              borrower: borrower!,
                              item: item,
                              amount: amount,
                              interest: interest,
                              dueDate: date,
                              status: 'unpaid',
                              imagePath: imagePath,
                            ),
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtle hint / help text
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Images are stored as local file paths and shown for quick reference.',
                            style: text.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
