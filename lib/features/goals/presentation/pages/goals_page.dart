import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/goal_model.dart';
import '../providers/goals_provider.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Metas')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (goals) => goals.isEmpty
            ? EmptyState(
                icon: Icons.track_changes_outlined,
                title: 'Nenhuma meta cadastrada',
                subtitle: 'Defina objetivos financeiros e acompanhe seu progresso',
                action: ElevatedButton(
                  onPressed: () => _showAddGoalSheet(context, ref),
                  child: const Text('Adicionar Meta'),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: goals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _GoalCard(goal: goals[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddGoalSheet(
        onSave: (goal) async {
          await ref.read(goalsProvider.notifier).createGoal(goal);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final GoalModel goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.flag, color: goal.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      if (goal.deadline != null)
                        Text(
                          'Prazo: ${goal.deadline!.toShortDate()}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (goal.isAchieved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Concluída!',
                        style: TextStyle(color: AppColors.income, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal.currentAmount.toCurrency(),
                  style: TextStyle(color: goal.color, fontWeight: FontWeight.w700, fontSize: 18),
                ),
                Text(
                  goal.targetAmount.toCurrency(),
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.percentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(goal.color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Faltam ${goal.remaining.toCurrency()}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                Text(
                  '${(goal.percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: goal.color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showAddAmountSheet(context, ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar valor'),
              style: OutlinedButton.styleFrom(
                foregroundColor: goal.color,
                side: BorderSide(color: goal.color),
                minimumSize: const Size(0, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAmountSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Adicionar a "${goal.name}"',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixText: 'R\$ '),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
                  if (amount <= 0) return;
                  await ref.read(goalsProvider.notifier).addAmount(goal.id, amount);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  final Future<void> Function(GoalModel goal) onSave;

  const _AddGoalSheet({required this.onSave});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  DateTime? _deadline;
  Color _color = AppColors.primary;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
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
          const Text('Nova Meta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome da meta'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor alvo (R\$)', prefixText: 'R\$ '),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Prazo (opcional)'),
            trailing: Text(_deadline?.toShortDate() ?? 'Sem prazo'),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _deadline = picked);
            },
          ),
          const SizedBox(height: 8),
          const Text('Cor', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AppColors.categoryColors.take(8).map((c) => GestureDetector(
              onTap: () => setState(() => _color = c),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: _color == c ? Border.all(color: Colors.black, width: 3) : null,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : () async {
              if (_nameCtrl.text.isEmpty) return;
              final target = double.tryParse(_targetCtrl.text.replaceAll(',', '.')) ?? 0;
              if (target <= 0) return;
              setState(() => _saving = true);
              try {
                final goal = GoalModel(
                  id: '',
                  userId: SupabaseService.currentUserId!,
                  name: _nameCtrl.text,
                  targetAmount: target,
                  currentAmount: 0,
                  deadline: _deadline,
                  color: _color,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await widget.onSave(goal);
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
    );
  }
}

