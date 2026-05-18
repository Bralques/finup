import '../../../../core/supabase/supabase_service.dart';
import '../models/diary_entry_model.dart';

class DiaryRepository {
  static const _table = 'expense_diary';

  Future<DiaryEntryModel?> getEntryForDate(DateTime date) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    final dateStr = date.toIso8601String().split('T').first;
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .maybeSingle();

    if (data == null) return null;
    return DiaryEntryModel.fromMap(data);
  }

  Future<List<DiaryEntryModel>> getEntriesForMonth(int month, int year) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final from = DateTime(year, month, 1).toIso8601String().split('T').first;
    final to = DateTime(year, month + 1, 0).toIso8601String().split('T').first;

    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .gte('date', from)
        .lte('date', to)
        .order('date', ascending: false);

    return (data as List).map((e) => DiaryEntryModel.fromMap(e)).toList();
  }

  Future<DiaryEntryModel> upsertEntry(DiaryEntryModel entry) async {
    final data = await SupabaseService.client
        .from(_table)
        .upsert(
          {...entry.toMap(), 'updated_at': DateTime.now().toIso8601String()},
          onConflict: 'user_id,date',
        )
        .select()
        .single();

    return DiaryEntryModel.fromMap(data);
  }

  Future<void> deleteEntry(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }
}
