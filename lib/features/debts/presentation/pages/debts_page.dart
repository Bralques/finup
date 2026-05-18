import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/debt_model.dart';
import '../providers/debts_provider.dart';

class DebtsPage extends ConsumerWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsProvider);
    final pendingAmount = ref.watch(pendingDebtsAmountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Cobranças')),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (debts) {
          final owedToMe = debts.where((d) => d.type == DebtType.owedToMe).toList();
          final iOwe = debts.where((d) => d.type == DebtType.iOwe).toList();

          return debts.isEmpty
              ? EmptyState(
                  icon: Icons.people_alt_outlined,
                  title: 'Nenhuma cobrança',
                  subtitle: 'Registre quem te deve ou o que você deve a alguém',
                  action: ElevatedButton(
                    onPressed: () => _showAddDebtSheet(context, ref),
                    child: const Text('Adicionar Cobrança'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Resumo
                    _SummaryCard(pendingAmount: pendingAmount, debts: debts),
                    const SizedBox(height: 24),

                    // Me devem
                    if (owedToMe.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Me Devem',
                        count: owedToMe.length,
                        color: AppColors.debtOwed,
                      ),
                      const SizedBox(height: 10),
                      ...owedToMe.map((d) => _DebtCard(debt: d)),
                      const SizedBox(height: 20),
                    ],

                    // Eu devo
                    if (iOwe.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Eu Devo',
                        count: iOwe.length,
                        color: AppColors.debtIOwe,
                      ),
                      const SizedBox(height: 10),
                      ...iOwe.map((d) => _DebtCard(debt: d)),
                    ],
                    const SizedBox(height: 80),
                  ],
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDebtSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddDebtSheet(
        onSave: (debt) async {
          await ref.read(debtsProvider.notifier).createDebt(debt);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double pendingAmount;
  final List<DebtModel> debts;

  const _SummaryCard({required this.pendingAmount, required this.debts});

  @override
  Widget build(BuildContext context) {
    final owedCount = debts.where((d) => d.type == DebtType.owedToMe).length;
    final iOweTotal = debts
        .where((d) => d.type == DebtType.iOwe)
        .fold(0.0, (s, d) => s + d.remainingAmount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Me devem',
                  amount: pendingAmount,
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.debtOwed,
                  subtitle: '$owedCount pessoa${owedCount != 1 ? 's' : ''}',
                ),
              ),
              Container(width: 1, height: 48, color: Colors.black12),
              Expanded(
                child: _SummaryItem(
                  label: 'Eu devo',
                  amount: iOweTotal,
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.debtIOwe,
                  subtitle: '${debts.where((d) => d.type == DebtType.iOwe).length} pendente${debts.where((d) => d.type == DebtType.iOwe).length != 1 ? 's' : ''}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount.toCurrency(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _DebtCard extends ConsumerWidget {
  final DebtModel debt;

  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = debt.type == DebtType.owedToMe ? AppColors.debtOwed : AppColors.debtIOwe;
    final isInstallment = debt.installmentsCount > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar inicial
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      debt.personName.isNotEmpty
                          ? debt.personName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.personName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      if (debt.description != null && debt.description!.isNotEmpty)
                        Text(debt.description!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      debt.remainingAmount.toCurrency(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    Text('restante',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),

            // Progresso parcelado
            if (isInstallment) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${debt.paidInstallments}/${debt.installmentsCount} parcelas pagas',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${debt.installmentAmount.toCurrency()}/parcela',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: debt.progress,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],

            // Data de vencimento
            if (debt.dueDate != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Vence em ${debt.dueDate!.toShortDate()}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                // Registrar pagamento
                if (!debt.isPaid)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmPayment(context, ref),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(isInstallment
                          ? 'Parcela paga'
                          : 'Marcar como pago'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color.withValues(alpha: 0.5)),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (!debt.isPaid) const SizedBox(width: 8),
                // Excluir
                SizedBox(
                  width: 36,
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => _confirmDelete(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      side: BorderSide(color: AppColors.expense.withValues(alpha: 0.3)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPayment(BuildContext context, WidgetRef ref) {
    final isInstallment = debt.installmentsCount > 1;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isInstallment ? 'Registrar parcela?' : 'Marcar como pago?'),
        content: Text(
          isInstallment
              ? 'Parcela ${debt.paidInstallments + 1}/${debt.installmentsCount} de ${debt.installmentAmount.toCurrency()}'
              : '${debt.personName} pagou ${debt.totalAmount.toCurrency()}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(debtsProvider.notifier).registerPayment(debt.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir cobrança?'),
        content: Text('Deseja excluir a cobrança de ${debt.personName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await ref.read(debtsProvider.notifier).deleteDebt(debt.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Excluir',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _AddDebtSheet extends StatefulWidget {
  final Future<void> Function(DebtModel debt) onSave;

  const _AddDebtSheet({required this.onSave});

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _installmentsCtrl = TextEditingController(text: '1');
  DebtType _type = DebtType.owedToMe;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _installmentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final installments = int.tryParse(_installmentsCtrl.text) ?? 1;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final installmentAmount = installments > 1 && amount > 0 ? amount / installments : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Nova Cobrança',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            // Tipo
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Me devem',
                    icon: Icons.arrow_downward_rounded,
                    color: AppColors.debtOwed,
                    selected: _type == DebtType.owedToMe,
                    onTap: () => setState(() => _type = DebtType.owedToMe),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeButton(
                    label: 'Eu devo',
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.debtIOwe,
                    selected: _type == DebtType.iOwe,
                    onTap: () => setState(() => _type = DebtType.iOwe),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome da pessoa',
                prefixIcon: Icon(Icons.person_outline),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor total (R\$)',
                prefixText: 'R\$ ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _installmentsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número de parcelas',
                prefixIcon: Icon(Icons.credit_card_outlined),
                helperText: '1 = valor único, 2+ = parcelado',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (installmentAmount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${installments}x de ${installmentAmount.toCurrency()}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? 'Vence em ${_dueDate!.toShortDate()}'
                          : 'Data de vencimento (opcional)',
                      style: TextStyle(
                        color: _dueDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : () async {
                if (_nameCtrl.text.isEmpty) return;
                final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
                if (amount <= 0) return;
                final count = int.tryParse(_installmentsCtrl.text) ?? 1;

                setState(() => _saving = true);
                try {
                  final debt = DebtModel(
                    id: '',
                    userId: SupabaseService.currentUserId!,
                    personName: _nameCtrl.text.trim(),
                    description: _descCtrl.text.isNotEmpty ? _descCtrl.text.trim() : null,
                    totalAmount: amount,
                    installmentsCount: count.clamp(1, 999),
                    paidInstallments: 0,
                    dueDate: _dueDate,
                    type: _type,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await widget.onSave(debt);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                  );
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              },
              child: _saving
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar Cobrança'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 0 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
