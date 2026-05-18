import 'package:intl/intl.dart';

extension CurrencyExtension on double {
  String toCurrency({String locale = 'pt_BR', String symbol = 'R\$'}) {
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 2,
    ).format(this);
  }

  String toCompactCurrency({String locale = 'pt_BR', String symbol = 'R\$'}) {
    if (abs() >= 1000000) {
      return '$symbol${(this / 1000000).toStringAsFixed(1)}M';
    } else if (abs() >= 1000) {
      return '$symbol${(this / 1000).toStringAsFixed(1)}K';
    }
    return toCurrency(locale: locale, symbol: symbol);
  }

  String toPercentage({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }
}

extension CurrencyStringExtension on String {
  double toCurrencyDouble() {
    final cleaned = replaceAll(RegExp(r'[^0-9,.-]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
