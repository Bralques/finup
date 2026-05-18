import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/income_source_model.dart';
import '../providers/income_sources_provider.dart';

class IncomeSourcesPage extends ConsumerWidget {
  const IncomeSourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(incomeSourcesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fontes de Renda')),
      body: sourcesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (sources) => sources.isEmpty
            ? EmptyState(
                icon: Icons.payments_outlined,
                title: 'Nenhuma fonte de renda',
                subtitle: 'Cadastre suas fontes de renda para melhor acompanhamento',
                action: ElevatedButton(
                  onPressed: () => _showAddSheet(context, ref),
                  child: const Text('Adicionar Fonte de Renda'),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sources.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _IncomeSourceCard(source: sources[i]),
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
      builder: (ctx) => _AddIncomeSourceSheet(
        onSave: (source) async {
          await ref.read(incomeSourcesProvider.notifier).createIncomeSource(source);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _IncomeSourceCard extends ConsumerWidget {
  final IncomeSourceModel source;

  const _IncomeSourceCard({required this.source});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.income.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.payments, color: AppColors.income, size: 20),
        ),
        title: Text(source.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(IncomeSourceType.labelFor(source.type),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            if (source.dayOfMonth != null)
              Text('Recebe dia ${source.dayOfMonth}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
        trailing: source.expectedAmount != null
            ? Text(
                source.expectedAmount!.toCurrency(),
                style: const TextStyle(
                  color: AppColors.income,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              )
            : null,
        onLongPress: () => showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excluir fonte de renda?'),
            content: Text('Deseja remover "${source.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              TextButton(
                onPressed: () async {
                  await ref.read(incomeSourcesProvider.notifier).deleteIncomeSource(source.id);
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

class _AddIncomeSourceSheet extends StatefulWidget {
  final Future<void> Function(IncomeSourceModel source) onSave;

  const _AddIncomeSourceSheet({required this.onSave});

  @override
  State<_AddIncomeSourceSheet> createState() => _AddIncomeSourceSheetState();
}

class _AddIncomeSourceSheetState extends State<_AddIncomeSourceSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _type = IncomeSourceType.salary;
  int? _dayOfMonth;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nova Fonte de Renda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'), autofocus: true),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: IncomeSourceType.labels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor esperado (opcional)', prefixText: 'R\$ '),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: _dayOfMonth,
            decoration: const InputDecoration(labelText: 'Dia de recebimento (opcional)'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Não definido')),
              ...List.generate(28, (i) => i + 1).map(
                (d) => DropdownMenuItem<int?>(value: d, child: Text('Dia $d')),
              ),
            ],
            onChanged: (v) => setState(() => _dayOfMonth = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : () async {
              if (_nameCtrl.text.isEmpty) return;
              setState(() => _saving = true);
              final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
              final source = IncomeSourceModel(
                id: '',
                userId: SupabaseService.currentUserId!,
                name: _nameCtrl.text,
                type: _type,
                expectedAmount: amount,
                dayOfMonth: _dayOfMonth,
                createdAt: DateTime.now(),
              );
              await widget.onSave(source);
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
