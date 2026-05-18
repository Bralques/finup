import '../../../../core/supabase/supabase_service.dart';
import '../models/budget_model.dart';

class BudgetsRepository {
  static const _table = 'budgets';

  Future<List<BudgetModel>> getBudgets(int month, int year) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('month', month)
        .eq('year', year);

    return (data as List).map((e) => BudgetModel.fromMap(e)).toList();
  }

  Future<BudgetModel> createBudget(BudgetModel budget) async {
    final data = await SupabaseService.client
        .from(_table)
        .insert(budget.toMap())
        .select()
        .single();

    return BudgetModel.fromMap(data);
  }

  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    final data = await SupabaseService.client
        .from(_table)
        .update(budget.toMap())
        .eq('id', budget.id)
        .select()
        .single();

    return BudgetModel.fromMap(data);
  }

  Future<void> deleteBudget(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }
}
