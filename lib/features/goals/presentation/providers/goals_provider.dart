import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goals_repository.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) => GoalsRepository());

final goalsProvider = AsyncNotifierProvider<GoalsNotifier, List<GoalModel>>(GoalsNotifier.new);

class GoalsNotifier extends AsyncNotifier<List<GoalModel>> {
  late GoalsRepository _repo;

  @override
  Future<List<GoalModel>> build() async {
    _repo = ref.watch(goalsRepositoryProvider);
    return _repo.getGoals();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getGoals());
  }

  Future<void> createGoal(GoalModel goal) async {
    final created = await _repo.createGoal(goal);
    state = AsyncData([...state.valueOrNull ?? [], created]);
  }

  Future<void> updateGoal(GoalModel goal) async {
    final updated = await _repo.updateGoal(goal);
    state = AsyncData(
      (state.valueOrNull ?? []).map((g) => g.id == updated.id ? updated : g).toList(),
    );
  }

  Future<void> addAmount(String goalId, double amount) async {
    final updated = await _repo.addAmount(goalId, amount);
    state = AsyncData(
      (state.valueOrNull ?? []).map((g) => g.id == updated.id ? updated : g).toList(),
    );
  }

  Future<void> deleteGoal(String id) async {
    await _repo.deleteGoal(id);
    state = AsyncData((state.valueOrNull ?? []).where((g) => g.id != id).toList());
  }
}
