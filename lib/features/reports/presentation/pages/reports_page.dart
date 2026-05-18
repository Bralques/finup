import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Por Categoria'),
            Tab(text: 'Mensal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CategoryReportTab(),
          _MonthlyReportTab(),
        ],
      ),
    );
  }
}

class _CategoryReportTab extends ConsumerWidget {
  const _CategoryReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final spendingAsync = ref.watch(categorySpendingProvider(selectedMonth));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                    DateTime(selectedMonth.year, selectedMonth.month - 1),
              ),
              Text(selectedMonth.toMonthYear(),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                    DateTime(selectedMonth.year, selectedMonth.month + 1),
              ),
            ],
          ),
        ),
        spendingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (spending) {
            if (spending.isEmpty) {
              return const Expanded(
                child: Center(child: Text('Sem gastos neste mês')),
              );
            }

            final total = spending.values.fold(0.0, (a, b) => a + b);
            final sections = <PieChartSectionData>[];
            final legendItems = <_LegendItem>[];

            var colorIndex = 0;
            spending.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value))
              ..forEach((e) {
                final category = categories.where((c) => c.id == e.key).firstOrNull;
                final color = AppColors.categoryColors[colorIndex % AppColors.categoryColors.length];
                colorIndex++;

                final percent = total > 0 ? (e.value / total * 100) : 0;
                sections.add(PieChartSectionData(
                  value: e.value,
                  color: color,
                  radius: 80,
                  title: percent > 5 ? '${percent.toStringAsFixed(0)}%' : '',
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ));

                legendItems.add(_LegendItem(
                  color: color,
                  label: category?.name ?? 'Categoria',
                  amount: e.value,
                  percent: percent.toDouble(),
                ));
              });

            return Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Total: ${total.toCurrency()}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ...legendItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.label)),
                        Text(
                          '${item.percent.toStringAsFixed(1)}%',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.amount.toCurrency(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;
  final double amount;
  final double percent;
  _LegendItem({required this.color, required this.label, required this.amount, required this.percent});
}

class _MonthlyReportTab extends ConsumerStatefulWidget {
  const _MonthlyReportTab();

  @override
  ConsumerState<_MonthlyReportTab> createState() => _MonthlyReportTabState();
}

class _MonthlyReportTabState extends ConsumerState<_MonthlyReportTab> {
  final int _monthsCount = 6;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(_monthsCount, (i) => DateTime(now.year, now.month - i));

    return FutureBuilder<List<Map<String, double>>>(
      future: Future.wait(
        months.map((m) => ref.read(transactionsRepositoryProvider).getMonthlySummary(m.month, m.year)),
      ),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final data = snap.data!.reversed.toList();
        final maxVal = data.fold(0.0, (max, m) {
          final v = (m['income'] ?? 0) > (m['expense'] ?? 0) ? (m['income'] ?? 0) : (m['expense'] ?? 0);
          return v > max ? v : max;
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Receitas vs Despesas (6 meses)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxVal * 1.2,
                  barGroups: List.generate(data.length, (i) {
                    final m = data[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: m['income'] ?? 0,
                          color: AppColors.income,
                          width: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: m['expense'] ?? 0,
                          color: AppColors.expense,
                          width: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final m = months.reversed.toList()[v.toInt()];
                          return Text(
                            '${m.month.toString().padLeft(2, '0')}/${m.year.toString().substring(2)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _LegendDot(color: AppColors.income, label: 'Receitas'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.expense, label: 'Despesas'),
              ],
            ),
            const SizedBox(height: 24),
            ...List.generate(data.length, (i) {
              final m = months.reversed.toList()[i];
              final income = data[i]['income'] ?? 0;
              final expense = data[i]['expense'] ?? 0;
              final balance = income - expense;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.toMonthYear(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('+${income.toCurrency()}',
                            style: const TextStyle(color: AppColors.income, fontSize: 12)),
                        Text('-${expense.toCurrency()}',
                            style: const TextStyle(color: AppColors.expense, fontSize: 12)),
                        Text(
                          balance.toCurrency(),
                          style: TextStyle(
                            color: balance >= 0 ? AppColors.income : AppColors.expense,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
