import 'package:flutter/material.dart';
import '../models/person.dart';

Future<String?> showBorrowerPickerSheet(
  BuildContext context,
  List<Person> people,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      String query = '';
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered =
              people
                  .where(
                    (p) => p.name.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Borrower',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search people',
                  ),
                  onChanged: (v) {
                    query = v;
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child:
                      filtered.isEmpty
                          ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'No matches. Add people via the People screen.',
                            ),
                          )
                          : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final person = filtered[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    person.name.isNotEmpty
                                        ? person.name[0].toUpperCase()
                                        : '?',
                                  ),
                                ),
                                title: Text(
                                  person.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => Navigator.of(ctx).pop(person.name),
                              );
                            },
                          ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  );
}
