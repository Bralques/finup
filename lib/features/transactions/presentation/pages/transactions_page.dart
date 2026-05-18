import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transactions_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final summary = ref.watch(monthlySummaryProvider(selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _MonthSelector(selectedMonth: selectedMonth),
        ),
      ),
      body: Column(
        children: [
          _SummaryBar(summary: summary),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (transactions) => transactions.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Nenhuma transação neste mês',
                      action: ElevatedButton(
                        onPressed: () => context.go('/transactions/add'),
                        child: const Text('Adicionar'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (_, i) => _TransactionCard(transaction: transactions[i]),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/transactions/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  final DateTime selectedMonth;

  const _MonthSelector({required this.selectedMonth});

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
                DateTime(selectedMonth.year, selectedMonth.month - 1),
          ),
          Text(
            selectedMonth.toMonthYear(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(selectedMonth.year, selectedMonth.month + 1),
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final AsyncValue<Map<String, double>> summary;

  const _SummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final income = summary.valueOrNull?['income'] ?? 0;
    final expense = summary.valueOrNull?['expense'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('Receitas', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text(income.toCurrency(),
                    style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          Expanded(
            child: Column(
              children: [
                Text('Despesas', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text(expense.toCurrency(),
                    style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          Expanded(
            child: Column(
              children: [
                Text('Saldo', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text((income - expense).toCurrency(),
                    style: TextStyle(
                      color: (income - expense) >= 0 ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends ConsumerWidget {
  final TransactionModel transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));

    final color = isTransfer
        ? AppColors.transfer
        : isIncome
            ? AppColors.income
            : AppColors.expense;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.expense,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir transação?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        ),
      ),
      onDismissed: (_) => ref.read(transactionsProvider.notifier).deleteTransaction(transaction.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: transaction.isPaid
              ? null
              : Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isTransfer
                    ? Icons.swap_horiz
                    : isIncome
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? transaction.type.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        transaction.date.toShortDate(),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      if (category != null) ...[
                        const Text(' · ', style: TextStyle(color: Colors.grey)),
                        Text(
                          category.name,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                      if (transaction.isInstallment) ...[
                        const Text(' · ', style: TextStyle(color: Colors.grey)),
                        Text(
                          transaction.installmentLabel,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${transaction.amount.toCurrency()}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!transaction.isPaid)
                  Text('pendente',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
