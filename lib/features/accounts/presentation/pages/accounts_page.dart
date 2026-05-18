import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
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
      builder: (ctx) => _AddAccountSheet(onSave: (name, type, balance, color) async {
        await ref.read(accountsProvider.notifier).createAccount(
              name: name,
              type: type,
              balance: balance,
              color: color,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        subtitle: Text(account.type.label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
                Text(
                  'Toque para ajustar',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
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
  final Future<void> Function(String name, AccountType type, double balance, Color color) onSave;

  const _AddAccountSheet({required this.onSave});

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  AccountType _type = AccountType.checking;
  Color _color = AppColors.primary;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

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
                await widget.onSave(_nameCtrl.text, _type, balance, _color);
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
