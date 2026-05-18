import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/diary_entry_model.dart';
import '../../data/repositories/diary_repository.dart';

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) => DiaryRepository());

final diaryMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final diaryEntriesProvider =
    AsyncNotifierProvider<DiaryNotifier, List<DiaryEntryModel>>(DiaryNotifier.new);

class DiaryNotifier extends AsyncNotifier<List<DiaryEntryModel>> {
  late DiaryRepository _repo;

  @override
  Future<List<DiaryEntryModel>> build() async {
    _repo = ref.watch(diaryRepositoryProvider);
    final month = ref.watch(diaryMonthProvider);
    return _repo.getEntriesForMonth(month.month, month.year);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final month = ref.read(diaryMonthProvider);
    state = await AsyncValue.guard(() => _repo.getEntriesForMonth(month.month, month.year));
  }

  Future<void> upsertEntry(DiaryEntryModel entry) async {
    final saved = await _repo.upsertEntry(entry);
    final current = state.valueOrNull ?? [];
    final exists = current.any((e) => e.id == saved.id || e.date.toIso8601String().split('T').first == saved.date.toIso8601String().split('T').first);

    if (exists) {
      state = AsyncData(
        current.map((e) {
          final eDate = e.date.toIso8601String().split('T').first;
          final savedDate = saved.date.toIso8601String().split('T').first;
          return eDate == savedDate ? saved : e;
        }).toList(),
      );
    } else {
      state = AsyncData([saved, ...current]);
    }
  }

  Future<void> deleteEntry(String id) async {
    await _repo.deleteEntry(id);
    state = AsyncData((state.valueOrNull ?? []).where((e) => e.id != id).toList());
  }
}

final todayDiaryProvider = FutureProvider<DiaryEntryModel?>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  return repo.getEntryForDate(DateTime.now());
});
