import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/diary_entry_model.dart';
import '../providers/diary_provider.dart';

class ExpenseDiaryPage extends ConsumerStatefulWidget {
  const ExpenseDiaryPage({super.key});

  @override
  ConsumerState<ExpenseDiaryPage> createState() => _ExpenseDiaryPageState();
}

class _ExpenseDiaryPageState extends ConsumerState<ExpenseDiaryPage> {
  @override
  Widget build(BuildContext context) {
    final month = ref.watch(diaryMonthProvider);
    final entriesAsync = ref.watch(diaryEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário de Gastos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _MonthBar(month: month),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (entries) => entries.isEmpty
            ? EmptyState(
                icon: Icons.book_outlined,
                title: 'Nenhuma anotação este mês',
                subtitle: 'Registre como foi seu dia financeiro',
                action: ElevatedButton(
                  onPressed: () => _showEditSheet(context, ref, null),
                  child: const Text('Anotar hoje'),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _DiaryCard(
                  entry: entries[i],
                  onTap: () => _showEditSheet(context, ref, entries[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditSheet(context, ref, null),
        child: const Icon(Icons.edit),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, DiaryEntryModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DiaryEditSheet(
        existing: existing,
        onSave: (entry) async {
          await ref.read(diaryEntriesProvider.notifier).upsertEntry(entry);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _MonthBar extends ConsumerWidget {
  final DateTime month;

  const _MonthBar({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(diaryMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1),
          ),
          Text(month.toMonthYear(), style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(diaryMonthProvider.notifier).state =
                DateTime(month.year, month.month + 1),
          ),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final DiaryEntryModel entry;
  final VoidCallback onTap;

  const _DiaryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    entry.date.day.toString(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    entry.date.toWeekDay().substring(0, 3),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.mood != null)
                      Row(
                        children: [
                          Text(entry.mood!.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            entry.mood!.label,
                            style: TextStyle(
                              color: entry.mood!.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    if (entry.note != null && entry.note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.note!,
                        style: TextStyle(color: Colors.grey.shade600),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryEditSheet extends StatefulWidget {
  final DiaryEntryModel? existing;
  final Future<void> Function(DiaryEntryModel entry) onSave;

  const _DiaryEditSheet({this.existing, required this.onSave});

  @override
  State<_DiaryEditSheet> createState() => _DiaryEditSheetState();
}

class _DiaryEditSheetState extends State<_DiaryEditSheet> {
  late TextEditingController _noteCtrl;
  DiaryMood? _mood;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.existing?.note ?? '');
    _mood = widget.existing?.mood;
    _date = widget.existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
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
          Text(
            _date.toLongDate(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Text('Como foi seu dia financeiro?',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: DiaryMood.values.map((m) => GestureDetector(
              onTap: () => setState(() => _mood = m),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _mood == m ? m.color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _mood == m ? Border.all(color: m.color) : null,
                ),
                child: Column(
                  children: [
                    Text(m.emoji, style: const TextStyle(fontSize: 24)),
                    Text(m.label, style: TextStyle(fontSize: 10, color: m.color)),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Anotações do dia (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : () async {
              setState(() => _saving = true);
              final entry = DiaryEntryModel(
                id: widget.existing?.id ?? '',
                userId: SupabaseService.currentUserId!,
                date: _date,
                note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
                mood: _mood,
                createdAt: widget.existing?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await widget.onSave(entry);
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
