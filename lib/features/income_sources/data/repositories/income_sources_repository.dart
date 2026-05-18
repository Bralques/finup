import '../../../../core/supabase/supabase_service.dart';
import '../models/income_source_model.dart';

class IncomeSourcesRepository {
  static const _table = 'income_sources';

  Future<List<IncomeSourceModel>> getIncomeSources({bool onlyActive = true}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    var query = SupabaseService.client.from(_table).select().eq('user_id', userId);
    if (onlyActive) query = query.eq('is_active', true);

    final data = await query.order('name');
    return (data as List).map((e) => IncomeSourceModel.fromMap(e)).toList();
  }

  Future<IncomeSourceModel> createIncomeSource(IncomeSourceModel source) async {
    final data = await SupabaseService.client
        .from(_table)
        .insert(source.toMap())
        .select()
        .single();

    return IncomeSourceModel.fromMap(data);
  }

  Future<IncomeSourceModel> updateIncomeSource(IncomeSourceModel source) async {
    final data = await SupabaseService.client
        .from(_table)
        .update(source.toMap())
        .eq('id', source.id)
        .select()
        .single();

    return IncomeSourceModel.fromMap(data);
  }

  Future<void> deleteIncomeSource(String id) async {
    await SupabaseService.client
        .from(_table)
        .update({'is_active': false})
        .eq('id', id);
  }
}
