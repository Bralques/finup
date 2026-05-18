import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/currency_extension.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final bool isIncome;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showSign;
  final bool obscure;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.isIncome = true,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.showSign = false,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    final sign = showSign ? (isIncome ? '+' : '-') : '';
    final text = obscure ? '••••••' : '$sign${amount.toCurrency()}';

    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}

class BalanceDisplay extends StatelessWidget {
  final double balance;
  final double fontSize;
  final FontWeight fontWeight;
  final bool obscure;

  const BalanceDisplay({
    super.key,
    required this.balance,
    this.fontSize = 28,
    this.fontWeight = FontWeight.w700,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = obscure ? 'R\$ ••••••' : balance.toCurrency();
    final color = balance >= 0
        ? Theme.of(context).colorScheme.onSurface
        : AppColors.expense;

    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
