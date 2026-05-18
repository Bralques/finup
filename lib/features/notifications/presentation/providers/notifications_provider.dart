import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_settings_model.dart';
import '../../data/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(),
);

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationSettingsModel?>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<NotificationSettingsModel?> {
  late NotificationsRepository _repo;

  @override
  Future<NotificationSettingsModel?> build() async {
    _repo = ref.watch(notificationsRepositoryProvider);
    return _repo.getSettings();
  }

  Future<void> saveSettings(NotificationSettingsModel settings) async {
    final saved = await _repo.upsertSettings(settings);
    state = AsyncData(saved);
  }
}
