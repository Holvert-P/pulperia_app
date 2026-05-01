String formatMoney(double value) {
  return 'C\$ ${formatNumber(value, decimals: 2)}';
}

String formatNumber(num value, {int decimals = 2}) {
  if (value is double && !value.isFinite) {
    return value.toString();
  }

  final isNegative = value < 0;
  final absValue = value.abs();
  final fixed = absValue.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts[0];
  final fraction = parts.length > 1 ? parts[1] : '';

  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    buffer.write(whole[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  final formattedWhole = buffer.toString();
  final formatted = fraction.isEmpty
      ? formattedWhole
      : '$formattedWhole.$fraction';
  return isNegative ? '-$formatted' : formatted;
}

String formatPercent(double value) {
  return '${formatNumber(value, decimals: 2)}%';
}

String formatDateTime(DateTime dateTime) {
  final d = dateTime.day.toString().padLeft(2, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  final y = dateTime.year.toString().padLeft(4, '0');

  final hour = dateTime.hour;
  final hour12 = (hour % 12) == 0 ? 12 : (hour % 12);
  final hh = hour12.toString().padLeft(2, '0');
  final mm = dateTime.minute.toString().padLeft(2, '0');
  final period = hour < 12 ? 'AM' : 'PM';

  return '$d/$m/$y $hh:$mm $period';
}

String formatDate(DateTime dateTime) {
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  final y = dateTime.year.toString().padLeft(4, '0');
  return '$d/$m/$y';
}
