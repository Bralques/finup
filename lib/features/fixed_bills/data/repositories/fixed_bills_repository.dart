import '../../../../core/supabase/supabase_service.dart';
import '../models/fixed_bill_model.dart';

class FixedBillsRepository {
  static const _table = 'fixed_bills';

  Future<List<FixedBillModel>> getFixedBills({bool onlyActive = true}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    var query = SupabaseService.client.from(_table).select().eq('user_id', userId);

    if (onlyActive) query = query.eq('is_active', true);

    final data = await query.order('name');
    return (data as List).map((e) => FixedBillModel.fromMap(e)).toList();
  }

  Future<List<FixedBillModel>> getUpcomingBills(int daysAhead) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_active', true);

    final bills = (data as List).map((e) => FixedBillModel.fromMap(e)).toList();
    final now = DateTime.now();

    return bills.where((b) {
      final due = b.nextDueDate(now);
      final diff = due.difference(now).inDays;
      return diff >= 0 && diff <= daysAhead;
    }).toList()
      ..sort((a, b) => a.nextDueDate(now).compareTo(b.nextDueDate(now)));
  }

  Future<FixedBillModel> createFixedBill(FixedBillModel bill) async {
    final data = await SupabaseService.client
        .from(_table)
        .insert(bill.toMap())
        .select()
        .single();

    return FixedBillModel.fromMap(data);
  }

  Future<FixedBillModel> updateFixedBill(FixedBillModel bill) async {
    final data = await SupabaseService.client
        .from(_table)
        .update({...bill.toMap(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', bill.id)
        .select()
        .single();

    return FixedBillModel.fromMap(data);
  }

  Future<void> deleteFixedBill(String id) async {
    await SupabaseService.client
        .from(_table)
        .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
