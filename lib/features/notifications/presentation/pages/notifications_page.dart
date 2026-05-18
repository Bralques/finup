import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../data/models/notification_settings_model.dart';
import '../providers/notifications_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Avisos e Bot')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (settings) {
          final s = settings ?? NotificationSettingsModel.defaults(SupabaseService.currentUserId!);
          return _NotificationsForm(settings: s);
        },
      ),
    );
  }
}

class _NotificationsForm extends ConsumerStatefulWidget {
  final NotificationSettingsModel settings;
  const _NotificationsForm({required this.settings});

  @override
  ConsumerState<_NotificationsForm> createState() => _NotificationsFormState();
}

class _NotificationsFormState extends ConsumerState<_NotificationsForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _telegramCtrl;
  late bool _whatsappEnabled;
  late bool _dailySummary;
  late bool _weeklySummary;
  late bool _billReminder;
  late bool _budgetAlert;
  String? _defaultAccountId;
  bool _saving = false;

  static const _bg = Color(0xFF0A0A0A);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final s = widget.settings;
    _whatsappCtrl = TextEditingController(text: s.whatsappNumber ?? '');
    _telegramCtrl = TextEditingController(text: s.telegramChatId ?? '');
    _defaultAccountId = s.defaultAccountId;
    _whatsappEnabled = s.whatsappEnabled;
    _dailySummary = s.dailySummary;
    _weeklySummary = s.weeklySummary;
    _billReminder = s.billReminder;
    _budgetAlert = s.budgetAlert;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _whatsappCtrl.dispose();
    _telegramCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final telegramId = _telegramCtrl.text.trim();
      final updated = widget.settings.copyWith(
        whatsappNumber: _whatsappCtrl.text.isNotEmpty ? _whatsappCtrl.text : null,
        telegramChatId: telegramId.isNotEmpty ? telegramId : null,
        defaultAccountId: _defaultAccountId,
        whatsappEnabled: _whatsappEnabled,
        dailySummary: _dailySummary,
        weeklySummary: _weeklySummary,
        billReminder: _billReminder,
        budgetAlert: _budgetAlert,
      );
      await ref.read(notificationSettingsProvider.notifier).saveSettings(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Configurações salvas!'),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs
        Container(
          color: _bg,
          child: TabBar(
            controller: _tabs,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: const Color(0xFF666666),
            tabs: const [
              Tab(text: '🤖  Bot de Lançamentos'),
              Tab(text: '🔔  Notificações'),
            ],
          ),
        ),

        Expanded(
          child: ColoredBox(
            color: const Color(0xFF0A0A0A),
            child: TabBarView(
            controller: _tabs,
            children: [
              _BotTab(
                whatsappCtrl: _whatsappCtrl,
                telegramCtrl: _telegramCtrl,
                defaultAccountId: _defaultAccountId,
                onAccountChanged: (id) => setState(() => _defaultAccountId = id),
                onSave: _save,
                saving: _saving,
              ),
              _NotificationsTab(
                whatsappEnabled: _whatsappEnabled,
                dailySummary: _dailySummary,
                weeklySummary: _weeklySummary,
                billReminder: _billReminder,
                budgetAlert: _budgetAlert,
                onChanged: (field, val) => setState(() {
                  switch (field) {
                    case 'whatsapp': _whatsappEnabled = val;
                    case 'daily': _dailySummary = val;
                    case 'weekly': _weeklySummary = val;
                    case 'bill': _billReminder = val;
                    case 'budget': _budgetAlert = val;
                  }
                }),
                onSave: _save,
                saving: _saving,
              ),
            ],
          ),
          ),  // ColoredBox
        ),
      ],
    );
  }
}

// ─── Tab: Bot de Lançamentos ────────────────────────────────

class _BotTab extends ConsumerWidget {
  final TextEditingController whatsappCtrl;
  final TextEditingController telegramCtrl;
  final String? defaultAccountId;
  final void Function(String?) onAccountChanged;
  final VoidCallback onSave;
  final bool saving;

  const _BotTab({
    required this.whatsappCtrl,
    required this.telegramCtrl,
    required this.defaultAccountId,
    required this.onAccountChanged,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Como funciona
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('✨', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Registre gastos pelo chat',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('Mande uma mensagem e o bot lança no app',
                            style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ExampleChip('💸 "gastei 47 no mercado"'),
              const SizedBox(height: 6),
              _ExampleChip('💰 "recebi 3000 de salário"'),
              const SizedBox(height: 6),
              _ExampleChip('💳 "comprei TV 1200 em 6x"'),
              const SizedBox(height: 6),
              _ExampleChip('📊 "saldo" ou "resumo do mês"'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Conta padrão
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Conta padrão do bot',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Onde os lançamentos serão registrados',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: defaultAccountId,
                hint: const Text('Selecionar conta'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                items: accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name),
                        ))
                    .toList(),
                onChanged: onAccountChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Telegram
        _BotSetupCard(
          icon: '✈️',
          title: 'Telegram',
          color: const Color(0xFF229ED9),
          steps: const [
            '1. Abra o Telegram e pesquise por @BotFather',
            '2. Envie /newbot e escolha um nome',
            '3. Copie o token e configure nas env vars do Supabase: TELEGRAM_BOT_TOKEN',
            '4. Abra seu bot no Telegram e envie /start',
            '5. Cole abaixo o Chat ID que o bot enviar',
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Seu Chat ID do Telegram',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
              const SizedBox(height: 8),
              TextFormField(
                controller: telegramCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ex: 123456789',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // WhatsApp
        _BotSetupCard(
          icon: '📱',
          title: 'WhatsApp via Z-API',
          color: const Color(0xFF25D366),
          steps: const [
            '1. Crie conta em z-api.io (tem plano de teste gratuito)',
            '2. Crie uma instância e escaneie o QR Code com seu WhatsApp',
            '3. No painel Z-API → Webhooks → "Ao receber mensagem"',
            '4. Cole a URL da Edge Function whatsapp-bot do Supabase',
            '5. Em Supabase → Secrets, adicione: ZAPI_INSTANCE_ID, ZAPI_TOKEN e ZAPI_CLIENT_TOKEN',
            '6. Confirme seu número abaixo (mesmo conectado ao Z-API)',
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Seu número WhatsApp',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
              const SizedBox(height: 8),
              TextFormField(
                controller: whatsappCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Ex: 5511999999999',
                  prefixIcon: Icon(Icons.phone),
                  helperText: 'DDI + DDD + número, sem espaços',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Webhook URLs
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('URLs dos Webhooks',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Configure nos serviços externos:',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(height: 12),
              _WebhookUrl(
                label: 'Telegram',
                url: 'https://SEU_ID.supabase.co/functions/v1/telegram-bot',
              ),
              const SizedBox(height: 8),
              _WebhookUrl(
                label: 'WhatsApp',
                url: 'https://SEU_ID.supabase.co/functions/v1/whatsapp-bot',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: saving ? null : onSave,
          child: saving
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0A0A)))
              : const Text('Salvar Configurações'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Tab: Notificações ──────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  final bool whatsappEnabled;
  final bool dailySummary;
  final bool weeklySummary;
  final bool billReminder;
  final bool budgetAlert;
  final void Function(String, bool) onChanged;
  final VoidCallback onSave;
  final bool saving;

  const _NotificationsTab({
    required this.whatsappEnabled,
    required this.dailySummary,
    required this.weeklySummary,
    required this.billReminder,
    required this.budgetAlert,
    required this.onChanged,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DarkCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativar notificações'),
                subtitle: const Text('Via WhatsApp ou Telegram',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                value: whatsappEnabled,
                onChanged: (v) => onChanged('whatsapp', v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DarkCard(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tipos de aviso',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Contas a vencer'),
                subtitle: const Text('Avisa antes do vencimento',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                value: billReminder,
                onChanged: (v) => onChanged('bill', v),
              ),
              const Divider(color: Color(0xFF272727)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Alerta de orçamento'),
                subtitle: const Text('Ao atingir 80% do limite',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                value: budgetAlert,
                onChanged: (v) => onChanged('budget', v),
              ),
              const Divider(color: Color(0xFF272727)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Resumo diário'),
                subtitle: const Text('Todo dia às 20h',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                value: dailySummary,
                onChanged: (v) => onChanged('daily', v),
              ),
              const Divider(color: Color(0xFF272727)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Resumo semanal'),
                subtitle: const Text('Toda segunda-feira',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                value: weeklySummary,
                onChanged: (v) => onChanged('weekly', v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: saving ? null : onSave,
          child: saving
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0A0A)))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

// ─── Widgets auxiliares ─────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF272727)),
      ),
      child: child,
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String text;
  const _ExampleChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
    );
  }
}

class _BotSetupCard extends StatefulWidget {
  final String icon;
  final String title;
  final Color color;
  final List<String> steps;
  final Widget child;

  const _BotSetupCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.steps,
    required this.child,
  });

  @override
  State<_BotSetupCard> createState() => _BotSetupCardState();
}

class _BotSetupCardState extends State<_BotSetupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF272727)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(widget.icon, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF666666),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 0, color: Color(0xFF272727)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Passo a passo
                  ...widget.steps.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(s,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF888888), height: 1.4)),
                  )),
                  const SizedBox(height: 12),
                  widget.child,
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WebhookUrl extends StatelessWidget {
  final String label;
  final String url;

  const _WebhookUrl({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(url,
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              overflow: TextOverflow.ellipsis),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 16),
          color: const Color(0xFF666666),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('URL copiada!')),
            );
          },
        ),
      ],
    );
  }
}
