import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/external_debt_model.dart';
import '../../data/repositories/external_debts_repository.dart';

final externalDebtsRepositoryProvider = Provider<ExternalDebtsRepository>(
  (ref) => ExternalDebtsRepository(),
);

final externalDebtsProvider =
    AsyncNotifierProvider<ExternalDebtsNotifier, List<ExternalDebtModel>>(
  ExternalDebtsNotifier.new,
);

class ExternalDebtsNotifier extends AsyncNotifier<List<ExternalDebtModel>> {
  late ExternalDebtsRepository _repo;

  @override
  Future<List<ExternalDebtModel>> build() async {
    _repo = ref.watch(externalDebtsRepositoryProvider);
    return _repo.getDebts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getDebts());
  }

  Future<void> createDebt(ExternalDebtModel debt) async {
    final created = await _repo.createDebt(debt);
    state = AsyncData([created, ...state.valueOrNull ?? []]);
    ref.invalidate(externalDebtsSummaryProvider);
  }

  Future<void> updateDebt(ExternalDebtModel debt) async {
    final updated = await _repo.updateDebt(debt);
    state = AsyncData(
      (state.valueOrNull ?? []).map((d) => d.id == updated.id ? updated : d).toList(),
    );
    ref.invalidate(externalDebtsSummaryProvider);
  }

  Future<void> markAsPaid(ExternalDebtModel debt) async {
    await updateDebt(debt.copyWith(status: ExternalDebtStatus.paid));
    state = AsyncData((state.valueOrNull ?? []).where((d) => d.id != debt.id).toList());
  }

  Future<void> deleteDebt(String id) async {
    await _repo.deleteDebt(id);
    state = AsyncData((state.valueOrNull ?? []).where((d) => d.id != id).toList());
    ref.invalidate(externalDebtsSummaryProvider);
  }
}

final externalDebtsSummaryProvider = FutureProvider<Map<String, double>>((ref) {
  final repo = ref.watch(externalDebtsRepositoryProvider);
  return repo.getSummary();
});
