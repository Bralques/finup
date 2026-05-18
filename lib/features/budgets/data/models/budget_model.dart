class BudgetModel {
  final String id;
  final String userId;
  final String categoryId;
  final int month;
  final int year;
  final double amountLimit;
  final DateTime createdAt;

  // Computed field — filled in provider
  double spent;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.amountLimit,
    required this.createdAt,
    this.spent = 0,
  });

  double get remaining => amountLimit - spent;
  double get percentage => amountLimit > 0 ? (spent / amountLimit).clamp(0.0, 1.0) : 0;
  bool get isOverBudget => spent > amountLimit;
  bool get isNearLimit => percentage >= 0.8 && !isOverBudget;

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String,
      month: map['month'] as int,
      year: map['year'] as int,
      amountLimit: (map['amount_limit'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'category_id': categoryId,
        'month': month,
        'year': year,
        'amount_limit': amountLimit,
      };

  BudgetModel copyWith({
    String? categoryId,
    int? month,
    int? year,
    double? amountLimit,
    double? spent,
  }) {
    return BudgetModel(
      id: id,
      userId: userId,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      year: year ?? this.year,
      amountLimit: amountLimit ?? this.amountLimit,
      createdAt: createdAt,
      spent: spent ?? this.spent,
    );
  }
}
