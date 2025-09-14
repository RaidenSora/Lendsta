import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final isPaid = s == 'paid';
    final bg = isPaid ? Colors.green.withOpacity(.12) : Colors.orange.withOpacity(.12);
    final fg = isPaid ? Colors.green.shade700 : Colors.orange.shade800;
    final label = isPaid ? 'Paid' : 'Unpaid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
