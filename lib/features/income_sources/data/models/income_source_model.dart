class IncomeSourceType {
  static const salary = 'salary';
  static const freelance = 'freelance';
  static const rental = 'rental';
  static const investment = 'investment';
  static const other = 'other';

  static const labels = {
    salary: 'Salário',
    freelance: 'Freelance',
    rental: 'Aluguel',
    investment: 'Investimentos',
    other: 'Outros',
  };

  static String labelFor(String type) => labels[type] ?? 'Outros';
}

class IncomeSourceModel {
  final String id;
  final String userId;
  final String name;
  final String type;
  final double? expectedAmount;
  final int? dayOfMonth;
  final bool isActive;
  final DateTime createdAt;

  const IncomeSourceModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.expectedAmount,
    this.dayOfMonth,
    this.isActive = true,
    required this.createdAt,
  });

  factory IncomeSourceModel.fromMap(Map<String, dynamic> map) {
    return IncomeSourceModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      expectedAmount: map['expected_amount'] != null ? (map['expected_amount'] as num).toDouble() : null,
      dayOfMonth: map['day_of_month'] as int?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'type': type,
        'expected_amount': expectedAmount,
        'day_of_month': dayOfMonth,
        'is_active': isActive,
      };

  IncomeSourceModel copyWith({
    String? name,
    String? type,
    double? expectedAmount,
    int? dayOfMonth,
    bool? isActive,
  }) {
    return IncomeSourceModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
