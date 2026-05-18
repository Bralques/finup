import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/income_source_model.dart';
import '../../data/repositories/income_sources_repository.dart';

final incomeSourcesRepositoryProvider = Provider<IncomeSourcesRepository>(
  (ref) => IncomeSourcesRepository(),
);

final incomeSourcesProvider =
    AsyncNotifierProvider<IncomeSourcesNotifier, List<IncomeSourceModel>>(
  IncomeSourcesNotifier.new,
);

class IncomeSourcesNotifier extends AsyncNotifier<List<IncomeSourceModel>> {
  late IncomeSourcesRepository _repo;

  @override
  Future<List<IncomeSourceModel>> build() async {
    _repo = ref.watch(incomeSourcesRepositoryProvider);
    return _repo.getIncomeSources();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getIncomeSources());
  }

  Future<void> createIncomeSource(IncomeSourceModel source) async {
    final created = await _repo.createIncomeSource(source);
    state = AsyncData([...state.valueOrNull ?? [], created]);
  }

  Future<void> updateIncomeSource(IncomeSourceModel source) async {
    final updated = await _repo.updateIncomeSource(source);
    state = AsyncData(
      (state.valueOrNull ?? []).map((s) => s.id == updated.id ? updated : s).toList(),
    );
  }

  Future<void> deleteIncomeSource(String id) async {
    await _repo.deleteIncomeSource(id);
    state = AsyncData((state.valueOrNull ?? []).where((s) => s.id != id).toList());
  }
}
