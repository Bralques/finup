import '../../../../core/supabase/supabase_service.dart';
import '../models/notification_settings_model.dart';

class NotificationsRepository {
  static const _table = 'notification_settings';

  Future<NotificationSettingsModel?> getSettings() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return NotificationSettingsModel.fromMap(data);
  }

  Future<NotificationSettingsModel> upsertSettings(NotificationSettingsModel settings) async {
    final data = await SupabaseService.client
        .from(_table)
        .upsert(
          {...settings.toMap(), 'updated_at': DateTime.now().toIso8601String()},
          onConflict: 'user_id',
        )
        .select()
        .single();

    return NotificationSettingsModel.fromMap(data);
  }
}
