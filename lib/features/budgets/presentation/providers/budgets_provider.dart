import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/budgets_repository.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) => BudgetsRepository());

final budgetsProvider = AsyncNotifierProvider<BudgetsNotifier, List<BudgetModel>>(
  BudgetsNotifier.new,
);

class BudgetsNotifier extends AsyncNotifier<List<BudgetModel>> {
  late BudgetsRepository _repo;

  @override
  Future<List<BudgetModel>> build() async {
    _repo = ref.watch(budgetsRepositoryProvider);
    final month = ref.watch(selectedMonthProvider);

    final budgets = await _repo.getBudgets(month.month, month.year);
    final spending = await ref.watch(categorySpendingProvider(month).future);

    for (final budget in budgets) {
      budget.spent = spending[budget.categoryId] ?? 0;
    }

    return budgets;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final month = ref.read(selectedMonthProvider);
    final budgets = await _repo.getBudgets(month.month, month.year);
    final spending = await ref.read(categorySpendingProvider(month).future);
    for (final b in budgets) {
      b.spent = spending[b.categoryId] ?? 0;
    }
    state = AsyncData(budgets);
  }

  Future<void> createBudget(BudgetModel budget) async {
    final created = await _repo.createBudget(budget);
    state = AsyncData([...state.valueOrNull ?? [], created]);
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final updated = await _repo.updateBudget(budget);
    state = AsyncData(
      (state.valueOrNull ?? []).map((b) => b.id == updated.id ? updated : b).toList(),
    );
  }

  Future<void> deleteBudget(String id) async {
    await _repo.deleteBudget(id);
    state = AsyncData((state.valueOrNull ?? []).where((b) => b.id != id).toList());
  }
}
