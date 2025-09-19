import '../models/loan.dart';

/// Build a CSV string for a list of loans.
/// Columns: id, borrower, item, amount, interest, dueDate, status, imagePath
String loansToCsv(List<Loan> loans) {
  final buffer = StringBuffer();

  // Header
  buffer.writeln(
    _row([
      'id',
      'borrower',
      'item',
      'amount',
      'interest',
      'dueDate',
      'status',
      'imagePath',
    ]),
  );

  for (final l in loans) {
    buffer.writeln(
      _row([
        l.id?.toString() ?? '',
        l.borrower,
        l.item,
        l.amount.toStringAsFixed(2),
        l.interest.toStringAsFixed(2),
        l.dueDate.toIso8601String(),
        l.status,
        l.imagePath ?? '',
      ]),
    );
  }

  return buffer.toString();
}

String _row(List<String> cols) => cols.map(_escape).join(',');

String _escape(String value) {
  final needsQuotes =
      value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r');
  var v = value.replaceAll('"', '""');
  if (needsQuotes) v = '"$v"';
  return v;
}
