import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/fixed_bill_model.dart';
import '../providers/fixed_bills_provider.dart';

class FixedBillsPage extends ConsumerWidget {
  const FixedBillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(fixedBillsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contas Fixas')),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (bills) => bills.isEmpty
            ? EmptyState(
                icon: Icons.repeat_outlined,
                title: 'Nenhuma conta fixa',
                subtitle: 'Cadastre contas recorrentes como aluguel, streaming, academia...',
                action: ElevatedButton(
                  onPressed: () => _showAddSheet(context, ref),
                  child: const Text('Adicionar Conta Fixa'),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bills.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _FixedBillCard(bill: bills[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddFixedBillSheet(
        onSave: (bill) async {
          await ref.read(fixedBillsProvider.notifier).createFixedBill(bill);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _FixedBillCard extends ConsumerWidget {
  final FixedBillModel bill;

  const _FixedBillCard({required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextDue = bill.nextDueDate(DateTime.now());
    final daysLeft = nextDue.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 3;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.expense.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_outlined, color: AppColors.expense, size: 20),
        ),
        title: Text(bill.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Todo dia ${bill.dayOfMonth} • ${bill.recurrence == 'monthly' ? 'Mensal' : 'Anual'}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            Text(
              daysLeft == 0
                  ? 'Vence hoje!'
                  : 'Vence em $daysLeft dia${daysLeft > 1 ? 's' : ''}',
              style: TextStyle(
                color: isUrgent ? AppColors.expense : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              bill.amount.toCurrency(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.expense,
                fontSize: 15,
              ),
            ),
            if (bill.endDate != null)
              Text(
                'até ${bill.endDate!.toShortDate()}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
          ],
        ),
        onLongPress: () => showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excluir conta fixa?'),
            content: Text('Deseja desativar "${bill.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              TextButton(
                onPressed: () async {
                  await ref.read(fixedBillsProvider.notifier).deleteFixedBill(bill.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Excluir', style: TextStyle(color: AppColors.expense)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddFixedBillSheet extends StatefulWidget {
  final Future<void> Function(FixedBillModel bill) onSave;

  const _AddFixedBillSheet({required this.onSave});

  @override
  State<_AddFixedBillSheet> createState() => _AddFixedBillSheetState();
}

class _AddFixedBillSheetState extends State<_AddFixedBillSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  int _dayOfMonth = 1;
  DateTime? _endDate;
  int _reminderDays = 3;
  bool _whatsappReminder = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nova Conta Fixa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'), autofocus: true),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixText: 'R\$ '),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _dayOfMonth,
              decoration: const InputDecoration(labelText: 'Dia de vencimento'),
              items: List.generate(28, (i) => i + 1)
                  .map((d) => DropdownMenuItem(value: d, child: Text('Dia $d')))
                  .toList(),
              onChanged: (v) => setState(() => _dayOfMonth = v!),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data final (opcional)'),
              trailing: Text(_endDate?.toShortDate() ?? 'Sem fim'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
            ),
            DropdownButtonFormField<int>(
              value: _reminderDays,
              decoration: const InputDecoration(labelText: 'Aviso antecipado'),
              items: [1, 2, 3, 5, 7, 10]
                  .map((d) => DropdownMenuItem(value: d, child: Text('$d dia${d > 1 ? 's' : ''} antes')))
                  .toList(),
              onChanged: (v) => setState(() => _reminderDays = v!),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aviso via WhatsApp'),
              value: _whatsappReminder,
              onChanged: (v) => setState(() => _whatsappReminder = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : () async {
                if (_nameCtrl.text.isEmpty) return;
                final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
                if (amount <= 0) return;
                setState(() => _saving = true);
                try {
                  final bill = FixedBillModel(
                    id: '',
                    userId: SupabaseService.currentUserId!,
                    name: _nameCtrl.text,
                    amount: amount,
                    dayOfMonth: _dayOfMonth,
                    startDate: DateTime.now(),
                    endDate: _endDate,
                    reminderDaysBefore: _reminderDays,
                    whatsappReminder: _whatsappReminder,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await widget.onSave(bill);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                  );
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
      ),
    );
  }
}
