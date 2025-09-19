import 'package:flutter/material.dart';
import '../data/loans_db.dart';
import '../models/person.dart';
import 'dashboard.dart';
import 'person_detail_page.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});
  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final LoansDatabase _db = LoansDatabase();
  late Future<List<Person>> _peopleFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _peopleFuture = _db.getAllPeople();
    });
  }

  Future<void> _addPersonDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final added = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Add Person'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Full name'),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await _db.insertPerson(controller.text);
                  if (context.mounted) Navigator.pop(context, true);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
    if (added == true && mounted) {
      _refresh();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Person added')));
    }
  }

  Future<void> _deletePerson(Person p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete person?'),
            content: Text('Remove "${p.name}" from your list?'),
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
    if (ok == true) {
      await _db.deletePerson(p.id!);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Person deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            } else {
              nav.pushReplacement(
                MaterialPageRoute(builder: (_) => const Dashboard()),
              );
            }
          },
        ),
      ),
      body: FutureBuilder<List<Person>>(
        future: _peopleFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final people = snap.data ?? [];
          if (people.isEmpty) {
            return const Center(child: Text('No people yet. Tap + to add.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: people.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final p = people[i];
              return Card(
                elevation: 0.2,
                child: ListTile(
                  title: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deletePerson(p),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PersonDetailPage(personName: p.name),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPersonDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Person'),
      ),
    );
  }
}
