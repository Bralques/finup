import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/categories_repository.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(),
);

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<CategoryModel>>(
  CategoriesNotifier.new,
);

class CategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  late CategoriesRepository _repo;

  @override
  Future<List<CategoryModel>> build() async {
    _repo = ref.watch(categoriesRepositoryProvider);
    return _repo.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getCategories());
  }

  Future<void> createCategory(CategoryModel category) async {
    final created = await _repo.createCategory(category);
    state = AsyncData([...state.valueOrNull ?? [], created]);
  }

  Future<void> updateCategory(CategoryModel category) async {
    final updated = await _repo.updateCategory(category);
    state = AsyncData(
      (state.valueOrNull ?? []).map((c) => c.id == updated.id ? updated : c).toList(),
    );
  }

  Future<void> deleteCategory(String id) async {
    await _repo.deleteCategory(id);
    state = AsyncData((state.valueOrNull ?? []).where((c) => c.id != id).toList());
  }

  Future<void> seedDefaults(String userId) async {
    await _repo.seedDefaultCategories(userId);
    await refresh();
  }
}

final expenseCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return (ref.watch(categoriesProvider).valueOrNull ?? [])
      .where((c) => c.type == CategoryType.expense && c.parentId == null)
      .toList();
});

final incomeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return (ref.watch(categoriesProvider).valueOrNull ?? [])
      .where((c) => c.type == CategoryType.income && c.parentId == null)
      .toList();
});

final categoryByIdProvider = Provider.family<CategoryModel?, String?>((ref, id) {
  if (id == null) return null;
  final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
  try {
    return cats.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});
