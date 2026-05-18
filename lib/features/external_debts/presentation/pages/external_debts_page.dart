import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/external_debt_model.dart';
import '../providers/external_debts_provider.dart';

class ExternalDebtsPage extends ConsumerWidget {
  const ExternalDebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(externalDebtsProvider);
    final summaryAsync = ref.watch(externalDebtsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dívidas Externas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_outlined),
            tooltip: 'Abrir Serasa',
            onPressed: () => _showSerasaInfo(context),
          ),
        ],
      ),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (debts) => debts.isEmpty
            ? EmptyState(
                icon: Icons.account_balance_outlined,
                title: 'Nenhuma dívida registrada',
                subtitle: 'Consulte seu Serasa ou SPC e registre as dívidas aqui para acompanhá-las',
                action: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showAddSheet(context, ref),
                      child: const Text('Adicionar Dívida'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showSerasaInfo(context),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Como consultar Serasa'),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Card de resumo por fonte
                  _SummaryCard(summaryAsync: summaryAsync),
                  const SizedBox(height: 20),

                  // Banner informativo
                  _InfoBanner(),
                  const SizedBox(height: 20),

                  // Lista de dívidas agrupadas por fonte
                  ..._buildGroupedList(debts, context, ref),
                  const SizedBox(height: 80),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildGroupedList(
      List<ExternalDebtModel> debts, BuildContext context, WidgetRef ref) {
    final groups = <ExternalDebtSource, List<ExternalDebtModel>>{};
    for (final debt in debts) {
      groups.putIfAbsent(debt.source, () => []).add(debt);
    }

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      widgets.add(_SourceHeader(source: entry.key, count: entry.value.length));
      widgets.add(const SizedBox(height: 10));
      for (final debt in entry.value) {
        widgets.add(_DebtCard(debt: debt));
      }
      widgets.add(const SizedBox(height: 20));
    }
    return widgets;
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddExternalDebtSheet(
        onSave: (debt) async {
          await ref.read(externalDebtsProvider.notifier).createDebt(debt);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showSerasaInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Como consultar suas dívidas'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoStep(
              icon: Icons.search,
              title: 'Serasa Consumidor',
              subtitle: 'serasa.com.br/consumidor\nConsulte grátis suas negativações',
            ),
            SizedBox(height: 12),
            _InfoStep(
              icon: Icons.account_balance,
              title: 'SPC Brasil',
              subtitle: 'spcbrasil.org.br\nConsulta gratuita 1x por ano',
            ),
            SizedBox(height: 12),
            _InfoStep(
              icon: Icons.gavel,
              title: 'Protestos em cartório',
              subtitle: 'protestosp.com.br ou\nCRC do seu estado',
            ),
            SizedBox(height: 12),
            _InfoStep(
              icon: Icons.account_balance_wallet,
              title: 'Banco Central (Registrato)',
              subtitle: 'registrato.bcb.gov.br\nDívidas com bancos',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoStep({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AsyncValue<Map<String, double>> summaryAsync;

  const _SummaryCard({required this.summaryAsync});

  @override
  Widget build(BuildContext context) {
    final summary = summaryAsync.valueOrNull ?? {};
    final total = summary['total'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: total > 0 ? AppColors.expense.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: total > 0 ? AppColors.expense.withValues(alpha: 0.2) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total em aberto',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Negativado',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.expense, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            total.toCurrency(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: total > 0 ? AppColors.expense : AppColors.income,
              letterSpacing: -1,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                if ((summary['serasa'] ?? 0) > 0)
                  Expanded(
                    child: _SourceChip(
                      label: 'Serasa',
                      amount: summary['serasa']!,
                      color: const Color(0xFFE53935),
                    ),
                  ),
                if ((summary['spc'] ?? 0) > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SourceChip(
                      label: 'SPC',
                      amount: summary['spc']!,
                      color: const Color(0xFFFF6F00),
                    ),
                  ),
                ],
                if ((summary['protest'] ?? 0) > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SourceChip(
                      label: 'Protesto',
                      amount: summary['protest']!,
                      color: const Color(0xFF6A1B9A),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SourceChip({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(amount.toCurrency(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Dados inseridos manualmente. Consulte periodicamente o Serasa e SPC para manter atualizado.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceHeader extends StatelessWidget {
  final ExternalDebtSource source;
  final int count;

  const _SourceHeader({required this.source, required this.count});

  Color get _color {
    switch (source) {
      case ExternalDebtSource.serasa:
        return const Color(0xFFE53935);
      case ExternalDebtSource.spc:
        return const Color(0xFFFF6F00);
      case ExternalDebtSource.protest:
        return const Color(0xFF6A1B9A);
      case ExternalDebtSource.bacen:
        return const Color(0xFF1565C0);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(source.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count', style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _DebtCard extends ConsumerWidget {
  final ExternalDebtModel debt;

  const _DebtCard({required this.debt});

  Color get _statusColor {
    switch (debt.status) {
      case ExternalDebtStatus.active:
        return AppColors.expense;
      case ExternalDebtStatus.negotiating:
        return AppColors.moodNeutral;
      case ExternalDebtStatus.disputed:
        return AppColors.transfer;
      case ExternalDebtStatus.paid:
        return AppColors.income;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.creditorName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(debt.type.label,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      debt.displayAmount.toCurrency(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.expense,
                      ),
                    ),
                    if (debt.currentAmount != null && debt.currentAmount != debt.originalAmount)
                      Text(
                        'Original: ${debt.originalAmount.toCurrency()}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    debt.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (debt.negativatedAt != null) ...[
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 13, color: AppColors.expense),
                      const SizedBox(width: 3),
                      Text(
                        'Negativado em ${debt.negativatedAt!.toShortDate()}',
                        style: const TextStyle(fontSize: 11, color: AppColors.expense),
                      ),
                    ],
                  ),
                ],
                if (debt.dueDate != null && debt.negativatedAt == null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Venceu em ${debt.dueDate!.toShortDate()}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
            if (debt.notes != null && debt.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(debt.notes!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                // Mudar status
                Expanded(
                  child: PopupMenuButton<ExternalDebtStatus>(
                    onSelected: (status) async {
                      await ref.read(externalDebtsProvider.notifier)
                          .updateDebt(debt.copyWith(status: status));
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    itemBuilder: (_) => ExternalDebtStatus.values
                        .map((s) => PopupMenuItem(
                              value: s,
                              child: Text(s.label),
                            ))
                        .toList(),
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text('Status'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: Colors.grey.shade300),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Atualizar valor
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _showUpdateAmountDialog(context, ref),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Atualizar valor'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => _confirmDelete(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      side: BorderSide(color: AppColors.expense.withValues(alpha: 0.3)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateAmountDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(
      text: debt.displayAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Atualizar valor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Valor com juros/multa atual de ${debt.creditorName}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Valor atualizado', prefixText: 'R\$ '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (amount == null || amount <= 0) return;
              await ref.read(externalDebtsProvider.notifier)
                  .updateDebt(debt.copyWith(currentAmount: amount));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
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
        title: const Text('Excluir dívida?'),
        content: Text('Remover dívida com ${debt.creditorName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await ref.read(externalDebtsProvider.notifier).deleteDebt(debt.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Excluir', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _AddExternalDebtSheet extends StatefulWidget {
  final Future<void> Function(ExternalDebtModel debt) onSave;

  const _AddExternalDebtSheet({required this.onSave});

  @override
  State<_AddExternalDebtSheet> createState() => _AddExternalDebtSheetState();
}

class _AddExternalDebtSheetState extends State<_AddExternalDebtSheet> {
  final _creditorCtrl = TextEditingController();
  final _originalCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _contractCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  ExternalDebtType _type = ExternalDebtType.credit;
  ExternalDebtStatus _status = ExternalDebtStatus.active;
  ExternalDebtSource _source = ExternalDebtSource.serasa;
  DateTime? _dueDate;
  DateTime? _negativatedAt;
  bool _saving = false;

  @override
  void dispose() {
    _creditorCtrl.dispose();
    _originalCtrl.dispose();
    _currentCtrl.dispose();
    _contractCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text('Nova Dívida Externa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            // Fonte
            const Text('Onde aparece?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ExternalDebtSource.values.map((s) {
                final selected = _source == s;
                return ChoiceChip(
                  label: Text(s.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _source = s),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _creditorCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Credor (banco, empresa...)',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<ExternalDebtType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Tipo de dívida'),
              items: ExternalDebtType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _originalCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor original',
                      prefixText: 'R\$ ',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _currentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor atual (c/ juros)',
                      prefixText: 'R\$ ',
                      helperText: 'Opcional',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Datas
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Vencimento original',
                    date: _dueDate,
                    onPick: (d) => setState(() => _dueDate = d),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: 'Data negativação',
                    date: _negativatedAt,
                    onPick: (d) => setState(() => _negativatedAt = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _contractCtrl,
              decoration: const InputDecoration(
                labelText: 'Nº do contrato (opcional)',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<ExternalDebtStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ExternalDebtStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saving ? null : () async {
                if (_creditorCtrl.text.isEmpty) return;
                final original = double.tryParse(_originalCtrl.text.replaceAll(',', '.')) ?? 0;
                if (original <= 0) return;
                final current = double.tryParse(_currentCtrl.text.replaceAll(',', '.'));

                setState(() => _saving = true);
                try {
                  final debt = ExternalDebtModel(
                    id: '',
                    userId: SupabaseService.currentUserId!,
                    creditorName: _creditorCtrl.text.trim(),
                    type: _type,
                    status: _status,
                    source: _source,
                    originalAmount: original,
                    currentAmount: current,
                    dueDate: _dueDate,
                    negativatedAt: _negativatedAt,
                    contractNumber: _contractCtrl.text.isNotEmpty ? _contractCtrl.text.trim() : null,
                    notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
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
                  : const Text('Salvar Dívida'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final void Function(DateTime) onPick;

  const _DateField({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(
              date?.toShortDate() ?? 'Toque p/ selecionar',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: date != null ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
