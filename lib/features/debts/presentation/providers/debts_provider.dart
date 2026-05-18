import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/debt_model.dart';
import '../../data/repositories/debts_repository.dart';

final debtsRepositoryProvider = Provider<DebtsRepository>((ref) => DebtsRepository());

final debtsProvider = AsyncNotifierProvider<DebtsNotifier, List<DebtModel>>(DebtsNotifier.new);

class DebtsNotifier extends AsyncNotifier<List<DebtModel>> {
  late DebtsRepository _repo;

  @override
  Future<List<DebtModel>> build() async {
    _repo = ref.watch(debtsRepositoryProvider);
    return _repo.getDebts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getDebts());
  }

  Future<void> createDebt(DebtModel debt) async {
    final created = await _repo.createDebt(debt);
    state = AsyncData([created, ...state.valueOrNull ?? []]);
  }

  Future<void> registerPayment(String debtId) async {
    final updated = await _repo.registerPayment(debtId);
    state = AsyncData(
      (state.valueOrNull ?? []).map((d) => d.id == debtId ? updated : d).toList(),
    );
    ref.invalidate(pendingDebtsAmountProvider);
  }

  Future<void> deleteDebt(String id) async {
    await _repo.deleteDebt(id);
    state = AsyncData((state.valueOrNull ?? []).where((d) => d.id != id).toList());
    ref.invalidate(pendingDebtsAmountProvider);
  }
}

final pendingDebtsAmountProvider = FutureProvider<double>((ref) {
  final repo = ref.watch(debtsRepositoryProvider);
  return repo.getTotalPendingOwedToMe();
});
