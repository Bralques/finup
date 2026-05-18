import '../../../../core/supabase/supabase_service.dart';
import '../models/account_model.dart';

class AccountsRepository {
  static const _table = 'accounts';

  Future<List<AccountModel>> getAccounts() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('name');

    return (data as List).map((e) => AccountModel.fromMap(e)).toList();
  }

  Future<AccountModel> createAccount(AccountModel account) async {
    final data = await SupabaseService.client
        .from(_table)
        .insert(account.toMap())
        .select()
        .single();

    return AccountModel.fromMap(data);
  }

  Future<AccountModel> updateAccount(AccountModel account) async {
    final data = await SupabaseService.client
        .from(_table)
        .update({...account.toMap(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', account.id)
        .select()
        .single();

    return AccountModel.fromMap(data);
  }

  Future<void> updateBalance(String accountId, double newBalance) async {
    await SupabaseService.client
        .from(_table)
        .update({'balance': newBalance, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', accountId);
  }

  Future<void> deleteAccount(String id) async {
    await SupabaseService.client
        .from(_table)
        .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
