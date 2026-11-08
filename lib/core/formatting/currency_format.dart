import 'package:flutter/widgets.dart';

class CurrencyScope extends InheritedWidget {
  const CurrencyScope({
    required this.currencyCode,
    required super.child,
    super.key,
  });

  final String currencyCode;

  static String codeOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<CurrencyScope>()
            ?.currencyCode ??
        'PHP';
  }

  @override
  bool updateShouldNotify(CurrencyScope oldWidget) {
    return currencyCode != oldWidget.currencyCode;
  }
}

String currencySymbolFor(String currencyCode) {
  final normalizedCode = currencyCode.trim().toUpperCase();
  return switch (normalizedCode) {
    'USD' => r'$',
    'EUR' => '€',
    'GBP' => '£',
    'CAD' => r'CA$',
    'AUD' => r'A$',
    'JPY' => '¥',
    'SGD' => r'S$',
    'AED' => 'د.إ ',
    'INR' => '₹',
    'KRW' => '₩',
    'CHF' => 'CHF ',
    'PHP' => '₱',
    _ => '$normalizedCode ',
  };
}

String currencySymbolOf(BuildContext context) {
  return currencySymbolFor(CurrencyScope.codeOf(context));
}

String formatCurrency(
  BuildContext context,
  num amount, {
  int decimalDigits = 2,
}) {
  return '${currencySymbolOf(context)}${amount.toStringAsFixed(decimalDigits)}';
}
