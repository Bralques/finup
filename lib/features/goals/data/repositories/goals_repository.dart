import '../../../../core/supabase/supabase_service.dart';
import '../models/goal_model.dart';

class GoalsRepository {
  static const _table = 'goals';

  Future<List<GoalModel>> getGoals({bool includeCompleted = false}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    var query = SupabaseService.client.from(_table).select().eq('user_id', userId);

    if (!includeCompleted) query = query.eq('is_completed', false);

    final data = await query.order('created_at');
    return (data as List).map((e) => GoalModel.fromMap(e)).toList();
  }

  Future<GoalModel> createGoal(GoalModel goal) async {
    final data = await SupabaseService.client
        .from(_table)
        .insert(goal.toMap())
        .select()
        .single();

    return GoalModel.fromMap(data);
  }

  Future<GoalModel> updateGoal(GoalModel goal) async {
    final data = await SupabaseService.client
        .from(_table)
        .update({...goal.toMap(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', goal.id)
        .select()
        .single();

    return GoalModel.fromMap(data);
  }

  Future<GoalModel> addAmount(String goalId, double amount) async {
    final current = await SupabaseService.client
        .from(_table)
        .select('current_amount, target_amount')
        .eq('id', goalId)
        .single();

    final newAmount = (current['current_amount'] as num).toDouble() + amount;
    final target = (current['target_amount'] as num).toDouble();

    final data = await SupabaseService.client
        .from(_table)
        .update({
          'current_amount': newAmount,
          'is_completed': newAmount >= target,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', goalId)
        .select()
        .single();

    return GoalModel.fromMap(data);
  }

  Future<void> deleteGoal(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }
}
