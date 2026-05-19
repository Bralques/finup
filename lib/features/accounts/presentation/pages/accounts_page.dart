import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/accounts_provider.dart';
import '../../data/models/account_model.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final total = ref.watch(totalBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contas')),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (accounts) => accounts.isEmpty
            ? EmptyState(
                icon: Icons.account_balance_outlined,
                title: 'Nenhuma conta cadastrada',
                subtitle: 'Adicione sua primeira conta para começar',
                action: ElevatedButton(
                  onPressed: () => _showAddAccountSheet(context, ref),
                  child: const Text('Adicionar Conta'),
                ),
              )
            : Column(
                children: [
                  _TotalBalanceBar(total: total),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _AccountCard(account: accounts[i]),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddAccountSheet(onSave: (name, type, balance, color, creditLimit) async {
        await ref.read(accountsProvider.notifier).createAccount(
              name: name,
              type: type,
              balance: balance,
              color: color,
              creditLimit: creditLimit,
            );
        if (ctx.mounted) Navigator.pop(ctx);
      }),
    );
  }
}

class _TotalBalanceBar extends StatelessWidget {
  final double total;

  const _TotalBalanceBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Saldo Total', style: TextStyle(color: Colors.white, fontSize: 14)),
          Text(
            total.toCurrency(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final AccountModel account;

  const _AccountCard({required this.account});

  bool get _isCard => account.type == AccountType.creditCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isCard) return _buildCreditCard(context, ref);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: account.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(account.type.icon, color: account.color, size: 22),
        ),
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(account.type.label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  account.balance.toCurrency(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: account.balance >= 0 ? AppColors.income : AppColors.expense,
                    fontSize: 15,
                  ),
                ),
                Text('Toque para ajustar',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade400),
          ],
        ),
        onTap: () => _showAdjustBalanceSheet(context, ref),
        onLongPress: () => _showDeleteDialog(context, ref),
      ),
    );
  }

  Widget _buildCreditCard(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(cardInvoiceProvider(account.id));
    final limit = account.creditLimit;

    return GestureDetector(
      onTap: () => _showInvoiceSheet(context, ref),
      onLongPress: () => _showDeleteDialog(context, ref),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: account.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.credit_card_rounded,
                        color: account.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(account.type.label,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      invoiceAsync.when(
                        loading: () => const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5)),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (inv) => Text(
                          inv.total.toCurrency(),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.expense,
                              fontSize: 15),
                        ),
                      ),
                      Text('Ver fatura',
                          style: TextStyle(
                              color: AppColors.accent.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),

              // Limit progress bar (only if limit is set)
              if (limit != null && limit > 0)
                invoiceAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (inv) {
                    final used = inv.total;
                    final available = (limit - used).clamp(0.0, limit);
                    final ratio = (used / limit).clamp(0.0, 1.0);
                    final barColor = ratio >= 0.9
                        ? AppColors.expense
                        : ratio >= 0.7
                            ? const Color(0xFFFF8F00)
                            : AppColors.income;

                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${available.toCurrency()} disponível',
                                style: TextStyle(
                                    color: barColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Limite ${limit.toCurrency()}',
                                style: const TextStyle(
                                    color: Color(0xFF666666), fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 5,
                              backgroundColor: const Color(0xFF2A2A2A),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(barColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvoiceSheet(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthName = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ][now.month];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: _InvoiceSheetContent(
            account: account,
            monthName: monthName,
            scrollController: controller,
            onPayPressed: () {
              Navigator.pop(ctx);
              context.go('/transactions/add', extra: {
                'type': 'expense',
                'description': 'Fatura $monthName - ${account.name}',
              });
            },
          ),
        ),
      ),
    );
  }

  void _showAdjustBalanceSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(
      text: account.balance.toStringAsFixed(2).replaceAll('.', ','),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        bool saving = false;

        return StatefulBuilder(
          builder: (ctx, setState) => Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: account.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(account.type.icon, color: account.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Ajustar saldo atual',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  autofocus: true,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: 'Saldo atual (R\$)',
                    prefixText: 'R\$ ',
                    prefixStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                    helperText: 'Digite o saldo real da sua conta agora',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Saldo anterior: ${account.balance.toCurrency()}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final raw = ctrl.text.replaceAll('.', '').replaceAll(',', '.');
                          final newBalance = double.tryParse(raw);
                          if (newBalance == null) return;
                          setState(() => saving = true);
                          await ref
                              .read(accountsProvider.notifier)
                              .adjustBalance(account.id, newBalance);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirmar Saldo'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta'),
        content: Text('Deseja excluir "${account.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await ref.read(accountsProvider.notifier).deleteAccount(account.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Excluir', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _AddAccountSheet extends StatefulWidget {
  final Future<void> Function(String name, AccountType type, double balance, Color color, double? creditLimit) onSave;

  const _AddAccountSheet({required this.onSave});

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  final _limitCtrl = TextEditingController();
  AccountType _type = AccountType.checking;
  Color _color = AppColors.primary;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isCard = _type == AccountType.creditCard;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nova Conta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome da conta'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AccountType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: AccountType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(labelText: 'Saldo inicial', prefixText: 'R\$ '),
          ),
          if (isCard) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _limitCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Limite do cartão',
                prefixText: 'R\$ ',
                helperText: 'Deixe em branco para não definir limite',
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text('Cor', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: accountDefaultColors.map((Color c) => GestureDetector(
              onTap: () => setState(() => _color = c),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: _color == c
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : () async {
              if (_nameCtrl.text.isEmpty) return;
              setState(() => _saving = true);
              try {
                final balance = double.tryParse(
                  _balanceCtrl.text.replaceAll(',', '.'),
                ) ?? 0;
                final limitText = _limitCtrl.text.replaceAll(',', '.');
                final creditLimit = limitText.isNotEmpty
                    ? double.tryParse(limitText)
                    : null;
                await widget.onSave(_nameCtrl.text, _type, balance, _color, creditLimit);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao salvar: $e'),
                      backgroundColor: AppColors.expense,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _saving = false);
              }
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

// ── Invoice sheet ─────────────────────────────────────────────────────────────

class _InvoiceSheetContent extends ConsumerWidget {
  final AccountModel account;
  final String monthName;
  final ScrollController scrollController;
  final VoidCallback onPayPressed;

  const _InvoiceSheetContent({
    required this.account,
    required this.monthName,
    required this.scrollController,
    required this.onPayPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(cardInvoiceProvider(account.id));

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        // Handle
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: account.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.credit_card_rounded,
                  color: account.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  Text('Fatura de $monthName',
                      style: const TextStyle(
                          color: Color(0xFF666666), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        invoiceAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator()),
          error: (e, _) =>
              Text('Erro: $e', style: const TextStyle(color: Colors.red)),
          data: (invoice) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.expense.withValues(alpha: 0.2),
                      AppColors.expense.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.expense.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total da fatura',
                        style: TextStyle(
                            color: Color(0xFF888888), fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      invoice.total.toCurrency(),
                      style: TextStyle(
                        color: AppColors.expense,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invoice.transactions.length} transações este mês',
                      style: const TextStyle(
                          color: Color(0xFF666666), fontSize: 12),
                    ),
                    // Limit info inside invoice
                    if (account.creditLimit != null && account.creditLimit! > 0) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF2A2A2A)),
                      const SizedBox(height: 12),
                      () {
                        final limit = account.creditLimit!;
                        final used = invoice.total;
                        final available = (limit - used).clamp(0.0, limit);
                        final ratio = (used / limit).clamp(0.0, 1.0);
                        final barColor = ratio >= 0.9
                            ? AppColors.expense
                            : ratio >= 0.7
                                ? const Color(0xFFFF8F00)
                                : AppColors.income;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Disponível',
                                        style: TextStyle(
                                            color: Color(0xFF888888),
                                            fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(available.toCurrency(),
                                        style: TextStyle(
                                            color: barColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Limite total',
                                        style: TextStyle(
                                            color: Color(0xFF888888),
                                            fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(limit.toCurrency(),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: const Color(0xFF2A2A2A),
                                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                              ),
                            ),
                          ],
                        );
                      }(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Pay button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onPayPressed,
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text('Pagar fatura'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              if (invoice.transactions.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Lançamentos do mês',
                    style: TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ...invoice.transactions.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.description?.isNotEmpty == true
                                    ? t.description!
                                    : 'Sem descrição',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t.date.toShortDate(),
                                style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          t.amount.toCurrency(),
                          style: TextStyle(
                            color: AppColors.expense,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ] else ...[
                const SizedBox(height: 40),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          color: Color(0xFF333333), size: 48),
                      SizedBox(height: 12),
                      Text('Nenhuma despesa este mês',
                          style: TextStyle(
                              color: Color(0xFF555555), fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
