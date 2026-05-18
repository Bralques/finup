enum DebtType {
  owedToMe('owed_to_me'),  // me devem
  iOwe('i_owe');           // eu devo

  final String value;
  const DebtType(this.value);

  static DebtType fromValue(String v) =>
      DebtType.values.firstWhere((e) => e.value == v, orElse: () => DebtType.owedToMe);
}

class DebtModel {
  final String id;
  final String userId;
  final String personName;
  final String? description;
  final double totalAmount;
  final int installmentsCount;
  final int paidInstallments;
  final DateTime? dueDate;
  final DebtType type;
  final String? notes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DebtModel({
    required this.id,
    required this.userId,
    required this.personName,
    this.description,
    required this.totalAmount,
    this.installmentsCount = 1,
    this.paidInstallments = 0,
    this.dueDate,
    this.type = DebtType.owedToMe,
    this.notes,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double get installmentAmount => installmentsCount > 0 ? totalAmount / installmentsCount : totalAmount;
  double get paidAmount => installmentAmount * paidInstallments;
  double get remainingAmount => totalAmount - paidAmount;
  double get progress => installmentsCount > 0 ? paidInstallments / installmentsCount : 0;
  int get remainingInstallments => installmentsCount - paidInstallments;
  bool get isPaid => paidInstallments >= installmentsCount;

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      personName: map['person_name'] as String,
      description: map['description'] as String?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      installmentsCount: map['installments_count'] as int? ?? 1,
      paidInstallments: map['paid_installments'] as int? ?? 0,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      type: DebtType.fromValue(map['type'] as String? ?? 'owed_to_me'),
      notes: map['notes'] as String?,
      isCompleted: map['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'person_name': personName,
        'description': description,
        'total_amount': totalAmount,
        'installments_count': installmentsCount,
        'paid_installments': paidInstallments,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'type': type.value,
        'notes': notes,
        'is_completed': isCompleted,
      };

  DebtModel copyWith({
    String? personName,
    String? description,
    double? totalAmount,
    int? installmentsCount,
    int? paidInstallments,
    DateTime? dueDate,
    DebtType? type,
    String? notes,
    bool? isCompleted,
  }) {
    return DebtModel(
      id: id,
      userId: userId,
      personName: personName ?? this.personName,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      installmentsCount: installmentsCount ?? this.installmentsCount,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
