import '../../../../core/supabase/supabase_service.dart';
import '../models/category_model.dart';

class CategoriesRepository {
  static const _table = 'categories';

  Future<List<CategoryModel>> getCategories({CategoryType? type}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    var query = SupabaseService.client.from(_table).select().eq('user_id', userId);

    if (type != null) {
      query = query.eq('type', type.value);
    }

    final data = await query.order('name');
    return (data as List).map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    final data = await SupabaseService.client
        .from(_table)
        .insert(category.toMap())
        .select()
        .single();

    return CategoryModel.fromMap(data);
  }

  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final data = await SupabaseService.client
        .from(_table)
        .update(category.toMap())
        .eq('id', category.id)
        .select()
        .single();

    return CategoryModel.fromMap(data);
  }

  Future<void> deleteCategory(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }

  Future<void> seedDefaultCategories(String userId) async {
    final existing = await SupabaseService.client
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    if ((existing as List).isNotEmpty) return;

    final incomeRows = defaultIncomeCategories.map((c) => {
          'user_id': userId,
          'name': c.name,
          'type': 'income',
          'icon': c.icon,
          'color': '#${c.colorValue.toRadixString(16).substring(2).toUpperCase()}',
        });

    final expenseRows = defaultExpenseCategories.map((c) => {
          'user_id': userId,
          'name': c.name,
          'type': 'expense',
          'icon': c.icon,
          'color': '#${c.colorValue.toRadixString(16).substring(2).toUpperCase()}',
        });

    await SupabaseService.client.from(_table).insert([...incomeRows, ...expenseRows]);
  }
}
