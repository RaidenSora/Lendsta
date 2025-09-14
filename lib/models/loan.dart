class Loan {
  final int? id;
  final String borrower;
  final String item; // NEW
  final double amount;
  final double interest; // percent, e.g., 5.5
  final DateTime dueDate; // used here as the “loan date” per your spec
  final String status; // 'unpaid' | 'paid'
  final String? imagePath; // NEW: local file path to attachment/photo

  Loan({
    this.id,
    required this.borrower,
    required this.item,
    required this.amount,
    required this.interest,
    required this.dueDate,
    this.status = 'unpaid',
    this.imagePath,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'borrower': borrower,
    'item': item,
    'amount': amount,
    'interest': interest,
    'dueDate': dueDate.toIso8601String(),
    'status': status,
    'imagePath': imagePath,
  };

  static Loan fromMap(Map<String, dynamic> map) => Loan(
    id: map['id'] as int?,
    borrower: map['borrower'] as String,
    item: map['item'] as String? ?? '', // backward-safety
    amount: (map['amount'] as num).toDouble(),
    interest: (map['interest'] as num).toDouble(),
    dueDate: DateTime.parse(map['dueDate'] as String),
    status: map['status'] as String,
    imagePath: map['imagePath'] as String?,
  );
}
