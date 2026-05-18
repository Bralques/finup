import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../fixed_bills/presentation/providers/fixed_bills_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../debts/presentation/providers/debts_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _obscureBalance = false;

  static const _bg = Color(0xFF0A0A0A);
  static const _card = Color(0xFF1C1C1C);
  static const _border = Color(0xFF272727);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final totalBalance = ref.watch(totalBalanceProvider);
    final summary = ref.watch(monthlySummaryProvider(month));
    final recentTxns = ref.watch(transactionsProvider).valueOrNull ?? [];
    final upcomingBills = ref.watch(upcomingBillsProvider).valueOrNull ?? [];
    final pendingDebts = ref.watch(pendingDebtsAmountProvider).valueOrNull ?? 0.0;
    final user = ref.watch(currentUserProvider);
    final firstName = user?.email?.split('@').first ?? 'você';

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: _card,
        onRefresh: () async {
          ref.invalidate(accountsProvider);
          ref.invalidate(transactionsProvider);
          ref.invalidate(upcomingBillsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(firstName, now)),

            // Card de saldo
            SliverToBoxAdapter(child: _buildBalanceCard(totalBalance, summary, month)),

            // Ações rápidas
            SliverToBoxAdapter(child: _buildActions(context)),

            // Contas a vencer
            if (upcomingBills.isNotEmpty)
              SliverToBoxAdapter(child: _buildUpcoming(upcomingBills, context)),

            // Cobranças pendentes
            if (pendingDebts > 0)
              SliverToBoxAdapter(child: _buildDebtsStrip(pendingDebts, context)),

            // Transações recentes
            SliverToBoxAdapter(child: _buildRecent(recentTxns, context)),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/transactions/add'),
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }

  Widget _buildHeader(String name, DateTime now) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset('assets/images/logo.svg', height: 22),
              const SizedBox(height: 4),
              Text(
                'Olá, $name 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                now.toLongDate(),
                style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
              ),
            ],
          ),
          Row(
            children: [
              _IconBtn(
                icon: _obscureBalance
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onTap: () => setState(() => _obscureBalance = !_obscureBalance),
              ),
              const SizedBox(width: 8),
              _IconBtn(
                icon: Icons.logout_rounded,
                onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
      double balance, AsyncValue<Map<String, double>> summary, DateTime month) {
    final income = summary.valueOrNull?['income'] ?? 0;
    final expense = summary.valueOrNull?['expense'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B35FF),
              Color(0xFFB535FF),
              Color(0xFFFF5733),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone de cartão + saldo label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo Total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    month.toMonthYear(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Valor
            Text(
              _obscureBalance ? 'R\$ ••••••' : balance.toCurrency(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Divisor
            Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),

            // Receitas / Despesas
            Row(
              children: [
                Expanded(
                  child: _BalanceStat(
                    label: 'Receitas',
                    amount: income,
                    icon: Icons.arrow_downward_rounded,
                    obscure: _obscureBalance,
                  ),
                ),
                Expanded(
                  child: _BalanceStat(
                    label: 'Despesas',
                    amount: expense,
                    icon: Icons.arrow_upward_rounded,
                    obscure: _obscureBalance,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _ActionBtn(
            label: 'Receita',
            icon: Icons.add_rounded,
            color: AppColors.income,
            onTap: () => context.go('/transactions/add', extra: {'type': 'income'}),
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            label: 'Despesa',
            icon: Icons.remove_rounded,
            color: AppColors.expense,
            onTap: () => context.go('/transactions/add', extra: {'type': 'expense'}),
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            label: 'Transferir',
            icon: Icons.swap_horiz_rounded,
            color: const Color(0xFF6B35FF),
            onTap: () => context.go('/transactions/add', extra: {'type': 'transfer'}),
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            label: 'Parcelado',
            icon: Icons.credit_card_rounded,
            color: const Color(0xFFFF5733),
            onTap: () => context.go('/transactions/add', extra: {'type': 'installment'}),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcoming(List bills, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _SectionTitle(
              title: 'Contas a Vencer',
              onTap: () => context.go('/fixed-bills'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              itemCount: bills.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final bill = bills[i];
                final days = bill
                    .nextDueDate(DateTime.now())
                    .difference(DateTime.now())
                    .inDays;
                return _BillChip(name: bill.name, amount: bill.amount, daysLeft: days);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsStrip(double amount, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => context.go('/debts'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.income.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.income.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_alt_outlined,
                    color: AppColors.income, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cobranças pendentes',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(
                      'Te devem ${amount.toCurrency()}',
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF888888), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecent(List<TransactionModel> txns, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Últimas Transações',
            onTap: () => context.go('/transactions'),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: txns.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Nenhuma transação este mês',
                          style: TextStyle(color: Color(0xFF666666))),
                    ),
                  )
                : Column(
                    children: txns
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => _TxnRow(
                              transaction: e.value,
                              isLast: e.key ==
                                  (txns.length > 5 ? 4 : txns.length - 1),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────── Widgets auxiliares ────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF272727)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final bool obscure;

  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.obscure,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(
              obscure ? '••••' : amount.toCurrency(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SectionTitle({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        GestureDetector(
          onTap: onTap,
          child: const Text('Ver todos',
              style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
        ),
      ],
    );
  }
}

class _BillChip extends StatelessWidget {
  final String name;
  final double amount;
  final int daysLeft;

  const _BillChip(
      {required this.name, required this.amount, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final urgent = daysLeft <= 2;
    final accentColor =
        urgent ? AppColors.expense : const Color(0xFF444444);

    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent
              ? AppColors.expense.withValues(alpha: 0.4)
              : const Color(0xFF272727),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(amount.toCurrency(),
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.expense)),
          Text(
            daysLeft == 0
                ? 'Vence hoje!'
                : 'Em $daysLeft dia${daysLeft > 1 ? 's' : ''}',
            style: TextStyle(
                fontSize: 11,
                color: accentColor,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TxnRow extends ConsumerWidget {
  final TransactionModel transaction;
  final bool isLast;

  const _TxnRow({required this.transaction, required this.isLast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final category =
        ref.watch(categoryByIdProvider(transaction.categoryId));

    final color = isTransfer
        ? const Color(0xFF6B35FF)
        : isIncome
            ? AppColors.income
            : AppColors.expense;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isTransfer
                      ? Icons.swap_horiz_rounded
                      : isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      category?.name ?? transaction.date.toShortDate(),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${transaction.amount.toCurrency()}',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
              height: 0, indent: 70, endIndent: 16, color: Color(0xFF222222)),
      ],
    );
  }
}
