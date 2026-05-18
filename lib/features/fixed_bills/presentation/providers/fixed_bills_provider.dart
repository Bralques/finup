import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fixed_bill_model.dart';
import '../../data/repositories/fixed_bills_repository.dart';

final fixedBillsRepositoryProvider = Provider<FixedBillsRepository>(
  (ref) => FixedBillsRepository(),
);

final fixedBillsProvider = AsyncNotifierProvider<FixedBillsNotifier, List<FixedBillModel>>(
  FixedBillsNotifier.new,
);

class FixedBillsNotifier extends AsyncNotifier<List<FixedBillModel>> {
  late FixedBillsRepository _repo;

  @override
  Future<List<FixedBillModel>> build() async {
    _repo = ref.watch(fixedBillsRepositoryProvider);
    return _repo.getFixedBills();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getFixedBills());
  }

  Future<void> createFixedBill(FixedBillModel bill) async {
    final created = await _repo.createFixedBill(bill);
    state = AsyncData([...state.valueOrNull ?? [], created]);
  }

  Future<void> updateFixedBill(FixedBillModel bill) async {
    final updated = await _repo.updateFixedBill(bill);
    state = AsyncData(
      (state.valueOrNull ?? []).map((b) => b.id == updated.id ? updated : b).toList(),
    );
  }

  Future<void> deleteFixedBill(String id) async {
    await _repo.deleteFixedBill(id);
    state = AsyncData((state.valueOrNull ?? []).where((b) => b.id != id).toList());
  }
}

final upcomingBillsProvider = FutureProvider<List<FixedBillModel>>((ref) {
  final repo = ref.watch(fixedBillsRepositoryProvider);
  return repo.getUpcomingBills(7);
});
