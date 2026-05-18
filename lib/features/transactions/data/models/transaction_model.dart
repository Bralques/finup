import '../../../../core/constants/app_strings.dart';

enum TransactionType {
  income('income', AppStrings.income),
  expense('expense', AppStrings.expense),
  transfer('transfer', AppStrings.transfer);

  final String value;
  final String label;
  const TransactionType(this.value, this.label);

  static TransactionType fromValue(String v) =>
      TransactionType.values.firstWhere((e) => e.value == v, orElse: () => TransactionType.expense);
}

enum RecurrenceType {
  none('none', AppStrings.none),
  daily('daily', AppStrings.daily),
  weekly('weekly', AppStrings.weekly),
  monthly('monthly', AppStrings.monthly),
  yearly('yearly', AppStrings.yearly);

  final String value;
  final String label;
  const RecurrenceType(this.value, this.label);

  static RecurrenceType fromValue(String v) =>
      RecurrenceType.values.firstWhere((e) => e.value == v, orElse: () => RecurrenceType.none);
}

class TransactionModel {
  final String id;
  final String userId;
  final String accountId;
  final String? categoryId;
  final String? incomeSourceId;
  final double amount;
  final TransactionType type;
  final String? description;
  final DateTime date;
  final bool isPaid;

  // Recurrence
  final RecurrenceType recurrence;
  final DateTime? recurrenceEndDate;
  final String? recurrenceGroupId;

  // Installments
  final String? installmentGroupId;
  final int? installmentNumber;
  final int? totalInstallments;

  // Transfer
  final String? transferAccountId;

  // Fixed bill origin
  final String? fixedBillId;

  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.accountId,
    this.categoryId,
    this.incomeSourceId,
    required this.amount,
    required this.type,
    this.description,
    required this.date,
    this.isPaid = true,
    this.recurrence = RecurrenceType.none,
    this.recurrenceEndDate,
    this.recurrenceGroupId,
    this.installmentGroupId,
    this.installmentNumber,
    this.totalInstallments,
    this.transferAccountId,
    this.fixedBillId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isInstallment => installmentGroupId != null;
  bool get isRecurring => recurrence != RecurrenceType.none;

  String get installmentLabel {
    if (!isInstallment) return '';
    return '${installmentNumber}/${totalInstallments}';
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      accountId: map['account_id'] as String,
      categoryId: map['category_id'] as String?,
      incomeSourceId: map['income_source_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromValue(map['type'] as String),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      isPaid: map['is_paid'] as bool? ?? true,
      recurrence: RecurrenceType.fromValue(map['recurrence'] as String? ?? 'none'),
      recurrenceEndDate: map['recurrence_end_date'] != null
          ? DateTime.parse(map['recurrence_end_date'] as String)
          : null,
      recurrenceGroupId: map['recurrence_group_id'] as String?,
      installmentGroupId: map['installment_group_id'] as String?,
      installmentNumber: map['installment_number'] as int?,
      totalInstallments: map['total_installments'] as int?,
      transferAccountId: map['transfer_account_id'] as String?,
      fixedBillId: map['fixed_bill_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'account_id': accountId,
        'category_id': categoryId,
        'income_source_id': incomeSourceId,
        'amount': amount,
        'type': type.value,
        'description': description,
        'date': date.toIso8601String().split('T').first,
        'is_paid': isPaid,
        'recurrence': recurrence.value,
        'recurrence_end_date': recurrenceEndDate?.toIso8601String().split('T').first,
        'recurrence_group_id': recurrenceGroupId,
        'installment_group_id': installmentGroupId,
        'installment_number': installmentNumber,
        'total_installments': totalInstallments,
        'transfer_account_id': transferAccountId,
        'fixed_bill_id': fixedBillId,
      };

  TransactionModel copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    String? incomeSourceId,
    double? amount,
    TransactionType? type,
    String? description,
    DateTime? date,
    bool? isPaid,
    RecurrenceType? recurrence,
    DateTime? recurrenceEndDate,
    String? installmentGroupId,
    int? installmentNumber,
    int? totalInstallments,
    String? transferAccountId,
    String? fixedBillId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      incomeSourceId: incomeSourceId ?? this.incomeSourceId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      isPaid: isPaid ?? this.isPaid,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceGroupId: recurrenceGroupId,
      installmentGroupId: installmentGroupId ?? this.installmentGroupId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      transferAccountId: transferAccountId ?? this.transferAccountId,
      fixedBillId: fixedBillId ?? this.fixedBillId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
