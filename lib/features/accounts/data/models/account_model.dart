import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

enum AccountType {
  checking('checking', AppStrings.checking, Icons.account_balance),
  savings('savings', AppStrings.savings, Icons.savings),
  creditCard('credit_card', AppStrings.creditCard, Icons.credit_card),
  wallet('wallet', AppStrings.wallet, Icons.account_balance_wallet);

  final String value;
  final String label;
  final IconData icon;
  const AccountType(this.value, this.label, this.icon);

  static AccountType fromValue(String value) =>
      AccountType.values.firstWhere((e) => e.value == value, orElse: () => AccountType.checking);
}

class AccountModel {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final Color color;
  final bool isActive;
  final double? creditLimit;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'BRL',
    required this.color,
    this.isActive = true,
    this.creditLimit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: AccountType.fromValue(map['type'] as String),
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'BRL',
      color: Color(int.parse((map['color'] as String? ?? '0xFF1E88E5').replaceFirst('#', '0xFF'))),
      isActive: map['is_active'] as bool? ?? true,
      creditLimit: (map['credit_limit'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'type': type.value,
        'balance': balance,
        'currency': currency,
        'color': '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
        'is_active': isActive,
        'credit_limit': creditLimit,
      };

  AccountModel copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    Color? color,
    bool? isActive,
    double? creditLimit,
    bool clearCreditLimit = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      creditLimit: clearCreditLimit ? null : (creditLimit ?? this.creditLimit),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static AccountModel empty() => AccountModel(
        id: '',
        userId: '',
        name: '',
        type: AccountType.checking,
        balance: 0,
        color: AppColors.primary,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
