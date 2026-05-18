import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/budget_model.dart';
import '../providers/budgets_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _MonthBar(month: selectedMonth),
        ),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (budgets) => budgets.isEmpty
            ? EmptyState(
                icon: Icons.pie_chart_outline,
                title: 'Nenhum orçamento',
                subtitle: 'Defina limites de gastos por categoria',
                action: ElevatedButton(
                  onPressed: () => _showAddBudgetSheet(context, ref),
                  child: const Text('Adicionar Orçamento'),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: budgets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _BudgetCard(budget: budgets[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBudgetSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddBudgetSheet(
        onSave: (categoryId, limit) async {
          final month = ref.read(selectedMonthProvider);
          final budget = BudgetModel(
            id: '',
            userId: SupabaseService.currentUserId!,
            categoryId: categoryId,
            month: month.month,
            year: month.year,
            amountLimit: limit,
            createdAt: DateTime.now(),
          );
          await ref.read(budgetsProvider.notifier).createBudget(budget);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _MonthBar extends ConsumerWidget {
  final DateTime month;

  const _MonthBar({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1),
          ),
          Text(month.toMonthYear(), style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month + 1),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetModel budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(budget.categoryId));
    final color = budget.isOverBudget
        ? AppColors.expense
        : budget.isNearLimit
            ? AppColors.moodNeutral
            : AppColors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category?.name ?? 'Categoria',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (budget.isOverBudget)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Excedido',
                        style: TextStyle(color: AppColors.expense, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: budget.percentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${budget.spent.toCurrency()} de ${budget.amountLimit.toCurrency()}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  '${(budget.percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBudgetSheet extends ConsumerStatefulWidget {
  final Future<void> Function(String categoryId, double limit) onSave;

  const _AddBudgetSheet({required this.onSave});

  @override
  ConsumerState<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<_AddBudgetSheet> {
  String? _categoryId;
  final _limitCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(expenseCategoriesProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Novo Orçamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _categoryId,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _limitCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Limite (R\$)', prefixText: 'R\$ '),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving || _categoryId == null ? null : () async {
              final limit = double.tryParse(_limitCtrl.text.replaceAll(',', '.')) ?? 0;
              if (limit <= 0) return;
              setState(() => _saving = true);
              await widget.onSave(_categoryId!, limit);
            },
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
