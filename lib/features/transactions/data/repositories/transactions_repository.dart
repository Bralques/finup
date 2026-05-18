import 'package:uuid/uuid.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/transaction_model.dart';

class TransactionsRepository {
  static const _table = 'transactions';
  static const _uuid = Uuid();

  Future<List<TransactionModel>> getTransactions({
    DateTime? from,
    DateTime? to,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    int limit = 100,
    int offset = 0,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    var query = SupabaseService.client.from(_table).select().eq('user_id', userId);

    if (from != null) query = query.gte('date', from.toIso8601String().split('T').first);
    if (to != null) query = query.lte('date', to.toIso8601String().split('T').first);
    if (accountId != null) query = query.eq('account_id', accountId);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (type != null) query = query.eq('type', type.value);

    final data = await query.order('date', ascending: false).range(offset, offset + limit - 1);
    return (data as List).map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final data = await SupabaseService.client
        .from(_table)
        .insert(transaction.toMap())
        .select()
        .single();

    return TransactionModel.fromMap(data);
  }

  Future<List<TransactionModel>> createInstallments({
    required TransactionModel base,
    required int totalInstallments,
  }) async {
    final groupId = _uuid.v4();
    final installmentAmount = base.amount;

    final rows = List.generate(totalInstallments, (i) {
      final date = DateTime(base.date.year, base.date.month + i, base.date.day);
      return {
        ...base.copyWith(
          installmentGroupId: groupId,
          installmentNumber: i + 1,
          totalInstallments: totalInstallments,
          date: date,
          isPaid: i == 0,
        ).toMap(),
        'user_id': base.userId,
      };
    });

    final data = await SupabaseService.client.from(_table).insert(rows).select();
    return (data as List).map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> createRecurringTransactions({
    required TransactionModel base,
    required DateTime endDate,
  }) async {
    final groupId = _uuid.v4();
    final rows = <Map<String, dynamic>>[];
    var current = base.date;

    while (!current.isAfter(endDate)) {
      rows.add({
        ...base.copyWith(date: current).toMap(),
        'user_id': base.userId,
        'recurrence_group_id': groupId,
      });
      current = _nextDate(current, base.recurrence);
    }

    if (rows.isNotEmpty) {
      await SupabaseService.client.from(_table).insert(rows);
    }
  }

  DateTime _nextDate(DateTime date, RecurrenceType recurrence) {
    switch (recurrence) {
      case RecurrenceType.daily:
        return date.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return date.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return DateTime(date.year, date.month + 1, date.day);
      case RecurrenceType.yearly:
        return DateTime(date.year + 1, date.month, date.day);
      default:
        return date;
    }
  }

  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    final data = await SupabaseService.client
        .from(_table)
        .update({...transaction.toMap(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', transaction.id)
        .select()
        .single();

    return TransactionModel.fromMap(data);
  }

  Future<void> markAsPaid(String id, bool paid) async {
    await SupabaseService.client
        .from(_table)
        .update({'is_paid': paid, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> deleteTransaction(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }

  Future<void> deleteInstallmentGroup(String groupId) async {
    await SupabaseService.client.from(_table).delete().eq('installment_group_id', groupId);
  }

  Future<void> deleteRecurrenceGroup(String groupId) async {
    await SupabaseService.client.from(_table).delete().eq('recurrence_group_id', groupId);
  }

  Future<Map<String, double>> getMonthlySummary(int month, int year) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return {'income': 0, 'expense': 0};

    final from = DateTime(year, month, 1).toIso8601String().split('T').first;
    final to = DateTime(year, month + 1, 0).toIso8601String().split('T').first;

    final data = await SupabaseService.client
        .from(_table)
        .select('amount, type')
        .eq('user_id', userId)
        .gte('date', from)
        .lte('date', to)
        .eq('is_paid', true)
        .neq('type', 'transfer');

    double income = 0;
    double expense = 0;

    for (final row in (data as List)) {
      final amount = (row['amount'] as num).toDouble();
      if (row['type'] == 'income') {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {'income': income, 'expense': expense};
  }

  Future<Map<String, double>> getCategorySpending(int month, int year) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return {};

    final from = DateTime(year, month, 1).toIso8601String().split('T').first;
    final to = DateTime(year, month + 1, 0).toIso8601String().split('T').first;

    final data = await SupabaseService.client
        .from(_table)
        .select('category_id, amount')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .eq('is_paid', true)
        .gte('date', from)
        .lte('date', to)
        .not('category_id', 'is', null);

    final result = <String, double>{};
    for (final row in (data as List)) {
      final catId = row['category_id'] as String;
      final amount = (row['amount'] as num).toDouble();
      result[catId] = (result[catId] ?? 0) + amount;
    }

    return result;
  }
}
