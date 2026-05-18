import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transactions_repository.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(),
);

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(
  TransactionsNotifier.new,
);

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  late TransactionsRepository _repo;

  @override
  Future<List<TransactionModel>> build() async {
    _repo = ref.watch(transactionsRepositoryProvider);
    final month = ref.watch(selectedMonthProvider);
    return _repo.getTransactions(
      from: DateTime(month.year, month.month, 1),
      to: DateTime(month.year, month.month + 1, 0),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final month = ref.read(selectedMonthProvider);
    state = await AsyncValue.guard(() => _repo.getTransactions(
          from: DateTime(month.year, month.month, 1),
          to: DateTime(month.year, month.month + 1, 0),
        ));
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final created = await _repo.createTransaction(transaction);
    state = AsyncData([created, ...state.valueOrNull ?? []]);
  }

  Future<void> addInstallments(TransactionModel base, int totalInstallments) async {
    await _repo.createInstallments(base: base, totalInstallments: totalInstallments);
    await refresh();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final updated = await _repo.updateTransaction(transaction);
    state = AsyncData(
      (state.valueOrNull ?? []).map((t) => t.id == updated.id ? updated : t).toList(),
    );
  }

  Future<void> togglePaid(String id, bool paid) async {
    await _repo.markAsPaid(id, paid);
    state = AsyncData(
      (state.valueOrNull ?? []).map((t) => t.id == id ? t.copyWith(isPaid: paid) : t).toList(),
    );
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.deleteTransaction(id);
    state = AsyncData((state.valueOrNull ?? []).where((t) => t.id != id).toList());
  }

  Future<void> deleteInstallmentGroup(String groupId) async {
    await _repo.deleteInstallmentGroup(groupId);
    state = AsyncData(
      (state.valueOrNull ?? []).where((t) => t.installmentGroupId != groupId).toList(),
    );
  }
}

final monthlySummaryProvider = FutureProvider.family<Map<String, double>, DateTime>((ref, month) {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.getMonthlySummary(month.month, month.year);
});

final categorySpendingProvider = FutureProvider.family<Map<String, double>, DateTime>((ref, month) {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.getCategorySpending(month.month, month.year);
});
