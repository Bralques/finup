class NotificationSettingsModel {
  final String id;
  final String userId;
  final String? whatsappNumber;
  final String? telegramChatId;
  final String? defaultAccountId;
  final bool whatsappEnabled;
  final bool dailySummary;
  final bool weeklySummary;
  final bool billReminder;
  final bool budgetAlert;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationSettingsModel({
    required this.id,
    required this.userId,
    this.whatsappNumber,
    this.telegramChatId,
    this.defaultAccountId,
    this.whatsappEnabled = false,
    this.dailySummary = false,
    this.weeklySummary = false,
    this.billReminder = true,
    this.budgetAlert = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      whatsappNumber: map['whatsapp_number'] as String?,
      telegramChatId: map['telegram_chat_id'] as String?,
      defaultAccountId: map['default_account_id'] as String?,
      whatsappEnabled: map['whatsapp_enabled'] as bool? ?? false,
      dailySummary: map['daily_summary'] as bool? ?? false,
      weeklySummary: map['weekly_summary'] as bool? ?? false,
      billReminder: map['bill_reminder'] as bool? ?? true,
      budgetAlert: map['budget_alert'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'whatsapp_number': whatsappNumber,
        'telegram_chat_id': telegramChatId,
        'default_account_id': defaultAccountId,
        'whatsapp_enabled': whatsappEnabled,
        'daily_summary': dailySummary,
        'weekly_summary': weeklySummary,
        'bill_reminder': billReminder,
        'budget_alert': budgetAlert,
      };

  NotificationSettingsModel copyWith({
    String? whatsappNumber,
    String? telegramChatId,
    String? defaultAccountId,
    bool? whatsappEnabled,
    bool? dailySummary,
    bool? weeklySummary,
    bool? billReminder,
    bool? budgetAlert,
  }) {
    return NotificationSettingsModel(
      id: id,
      userId: userId,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      defaultAccountId: defaultAccountId ?? this.defaultAccountId,
      whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
      dailySummary: dailySummary ?? this.dailySummary,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      billReminder: billReminder ?? this.billReminder,
      budgetAlert: budgetAlert ?? this.budgetAlert,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static NotificationSettingsModel defaults(String userId) => NotificationSettingsModel(
        id: '',
        userId: userId,
        whatsappEnabled: false,
        dailySummary: false,
        weeklySummary: false,
        billReminder: true,
        budgetAlert: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
