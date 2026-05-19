import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/accounts_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/repositories/transactions_repository.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) => AccountsRepository());

final accountsProvider = AsyncNotifierProvider<AccountsNotifier, List<AccountModel>>(
  AccountsNotifier.new,
);

class AccountsNotifier extends AsyncNotifier<List<AccountModel>> {
  late AccountsRepository _repo;

  @override
  Future<List<AccountModel>> build() async {
    _repo = ref.watch(accountsRepositoryProvider);
    return _repo.getAccounts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAccounts());
  }

  Future<void> createAccount({
    required String name,
    required AccountType type,
    required double balance,
    required Color color,
    String currency = 'BRL',
  }) async {
    final userId = SupabaseService.currentUserId!;
    final newAccount = AccountModel(
      id: '',
      userId: userId,
      name: name,
      type: type,
      balance: balance,
      currency: currency,
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final created = await _repo.createAccount(newAccount);
    state = AsyncData([...state.valueOrNull ?? [], created]);
  }

  Future<void> updateAccount(AccountModel account) async {
    final updated = await _repo.updateAccount(account);
    state = AsyncData(
      (state.valueOrNull ?? []).map((a) => a.id == updated.id ? updated : a).toList(),
    );
  }

  Future<void> adjustBalance(String accountId, double newBalance) async {
    await _repo.updateBalance(accountId, newBalance);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((a) => a.id == accountId ? a.copyWith(balance: newBalance) : a)
          .toList(),
    );
  }

  Future<void> deleteAccount(String id) async {
    await _repo.deleteAccount(id);
    state = AsyncData((state.valueOrNull ?? []).where((a) => a.id != id).toList());
  }

  double get totalBalance {
    return (state.valueOrNull ?? [])
        .where((a) => a.type != AccountType.creditCard)
        .fold(0.0, (sum, a) => sum + a.balance);
  }
}

final totalBalanceProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
  return accounts
      .where((a) => a.type != AccountType.creditCard)
      .fold(0.0, (sum, a) => sum + a.balance);
});

final accountByIdProvider = Provider.family<AccountModel?, String>((ref, id) {
  final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
  try {
    return accounts.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
});

// Provider for credit card invoice (current month expenses)
final _txRepoProvider = Provider<TransactionsRepository>((ref) => TransactionsRepository());

final cardInvoiceProvider = FutureProvider.family<_CardInvoice, String>((ref, accountId) async {
  final repo = ref.read(_txRepoProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, 1);
  final to = DateTime(now.year, now.month + 1, 0);

  final transactions = await repo.getTransactions(
    accountId: accountId,
    from: from,
    to: to,
    type: TransactionType.expense,
    limit: 200,
  );

  final total = transactions.fold<double>(0, (sum, t) => sum + t.amount);
  return _CardInvoice(total: total, transactions: transactions);
});

class _CardInvoice {
  final double total;
  final List<TransactionModel> transactions;
  const _CardInvoice({required this.total, required this.transactions});
}

// Default colors for new accounts
const accountDefaultColors = [
  AppColors.primary,
  AppColors.income,
  AppColors.transfer,
  Color(0xFF8E24AA),
  Color(0xFFFF8F00),
  Color(0xFF546E7A),
];
