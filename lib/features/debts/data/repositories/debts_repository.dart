import '../../../../core/supabase/supabase_service.dart';
import '../models/debt_model.dart';

class DebtsRepository {
  static const _table = 'debts';

  Future<List<DebtModel>> getDebts({bool includeCompleted = false}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    var query = SupabaseService.client.from(_table).select().eq('user_id', userId);
    if (!includeCompleted) query = query.eq('is_completed', false);

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => DebtModel.fromMap(e)).toList();
  }

  Future<DebtModel> createDebt(DebtModel debt) async {
    final data = await SupabaseService.client
        .from(_table)
        .insert(debt.toMap())
        .select()
        .single();
    return DebtModel.fromMap(data);
  }

  Future<DebtModel> updateDebt(DebtModel debt) async {
    final data = await SupabaseService.client
        .from(_table)
        .update({...debt.toMap(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', debt.id)
        .select()
        .single();
    return DebtModel.fromMap(data);
  }

  Future<DebtModel> registerPayment(String debtId) async {
    final current = await SupabaseService.client
        .from(_table)
        .select('paid_installments, installments_count')
        .eq('id', debtId)
        .single();

    final paid = (current['paid_installments'] as int) + 1;
    final total = current['installments_count'] as int;
    final isCompleted = paid >= total;

    final data = await SupabaseService.client
        .from(_table)
        .update({
          'paid_installments': paid,
          'is_completed': isCompleted,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', debtId)
        .select()
        .single();

    return DebtModel.fromMap(data);
  }

  Future<void> deleteDebt(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }

  Future<double> getTotalPendingOwedToMe() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return 0;

    final data = await SupabaseService.client
        .from(_table)
        .select('total_amount, paid_installments, installments_count')
        .eq('user_id', userId)
        .eq('type', 'owed_to_me')
        .eq('is_completed', false);

    double total = 0;
    for (final row in (data as List)) {
      final t = (row['total_amount'] as num).toDouble();
      final paid = row['paid_installments'] as int;
      final count = row['installments_count'] as int;
      final installmentAmount = count > 0 ? t / count : t;
      total += t - (installmentAmount * paid);
    }
    return total;
  }
}
