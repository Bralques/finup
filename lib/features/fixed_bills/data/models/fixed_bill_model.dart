class FixedBillModel {
  final String id;
  final String userId;
  final String? accountId;
  final String? categoryId;
  final String name;
  final double amount;
  final int dayOfMonth;
  final DateTime startDate;
  final DateTime? endDate;
  final String recurrence;
  final bool isActive;
  final int reminderDaysBefore;
  final bool whatsappReminder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FixedBillModel({
    required this.id,
    required this.userId,
    this.accountId,
    this.categoryId,
    required this.name,
    required this.amount,
    required this.dayOfMonth,
    required this.startDate,
    this.endDate,
    this.recurrence = 'monthly',
    this.isActive = true,
    this.reminderDaysBefore = 3,
    this.whatsappReminder = false,
    required this.createdAt,
    required this.updatedAt,
  });

  DateTime nextDueDate(DateTime from) {
    final now = from;
    var candidate = DateTime(now.year, now.month, dayOfMonth);
    if (candidate.isBefore(now)) {
      candidate = DateTime(now.year, now.month + 1, dayOfMonth);
    }
    return candidate;
  }

  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());

  factory FixedBillModel.fromMap(Map<String, dynamic> map) {
    return FixedBillModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      accountId: map['account_id'] as String?,
      categoryId: map['category_id'] as String?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      dayOfMonth: map['day_of_month'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      recurrence: map['recurrence'] as String? ?? 'monthly',
      isActive: map['is_active'] as bool? ?? true,
      reminderDaysBefore: map['reminder_days_before'] as int? ?? 3,
      whatsappReminder: map['whatsapp_reminder'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'account_id': accountId,
        'category_id': categoryId,
        'name': name,
        'amount': amount,
        'day_of_month': dayOfMonth,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'recurrence': recurrence,
        'is_active': isActive,
        'reminder_days_before': reminderDaysBefore,
        'whatsapp_reminder': whatsappReminder,
      };

  FixedBillModel copyWith({
    String? accountId,
    String? categoryId,
    String? name,
    double? amount,
    int? dayOfMonth,
    DateTime? startDate,
    DateTime? endDate,
    String? recurrence,
    bool? isActive,
    int? reminderDaysBefore,
    bool? whatsappReminder,
  }) {
    return FixedBillModel(
      id: id,
      userId: userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      recurrence: recurrence ?? this.recurrence,
      isActive: isActive ?? this.isActive,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      whatsappReminder: whatsappReminder ?? this.whatsappReminder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
