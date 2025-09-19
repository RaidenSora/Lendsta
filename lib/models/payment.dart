class Payment {
  final int? id;
  final int loanId;
  final double amount;
  final DateTime date;
  final String? note;

  const Payment({
    this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'loanId': loanId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  static Payment fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] as int?,
        loanId: map['loanId'] as int,
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        note: map['note'] as String?,
      );
}

