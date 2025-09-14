class NumberFormatHelper {
  static String currency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final frac = parts[1];
    final buf = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      final idxFromEnd = whole.length - i;
      buf.write(whole[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return '${buf.toString()}.$frac';
  }
}
