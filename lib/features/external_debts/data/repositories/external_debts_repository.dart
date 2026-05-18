import '../../../../core/supabase/supabase_service.dart';
import '../models/external_debt_model.dart';

class ExternalDebtsRepository {
  static const _table = 'external_debts';

  Future<List<ExternalDebtModel>> getDebts({bool includeSettled = false}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    var query = SupabaseService.client.from(_table).select().eq('user_id', userId);
    if (!includeSettled) query = query.neq('status', 'paid');

    final data = await query.order('negativated_at', ascending: false);
    return (data as List).map((e) => ExternalDebtModel.fromMap(e)).toList();
  }

  Future<ExternalDebtModel> createDebt(ExternalDebtModel debt) async {
    final data = await SupabaseService.client
        .from(_table)
        .insert(debt.toMap())
        .select()
        .single();
    return ExternalDebtModel.fromMap(data);
  }

  Future<ExternalDebtModel> updateDebt(ExternalDebtModel debt) async {
    final data = await SupabaseService.client
        .from(_table)
        .update({...debt.toMap(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', debt.id)
        .select()
        .single();
    return ExternalDebtModel.fromMap(data);
  }

  Future<void> deleteDebt(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }

  Future<Map<String, double>> getSummary() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return {};

    final data = await SupabaseService.client
        .from(_table)
        .select('source, original_amount, current_amount, status')
        .eq('user_id', userId)
        .neq('status', 'paid');

    double serasaTotal = 0;
    double spcTotal = 0;
    double protestTotal = 0;
    double otherTotal = 0;

    for (final row in (data as List)) {
      final amount = row['current_amount'] != null
          ? (row['current_amount'] as num).toDouble()
          : (row['original_amount'] as num).toDouble();
      switch (row['source'] as String) {
        case 'serasa':
          serasaTotal += amount;
        case 'spc':
          spcTotal += amount;
        case 'protest':
          protestTotal += amount;
        default:
          otherTotal += amount;
      }
    }

    return {
      'serasa': serasaTotal,
      'spc': spcTotal,
      'protest': protestTotal,
      'other': otherTotal,
      'total': serasaTotal + spcTotal + protestTotal + otherTotal,
    };
  }
}
