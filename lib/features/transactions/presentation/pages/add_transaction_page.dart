import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transactions_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/data/models/account_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/data/models/category_model.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  final String? initialType;

  const AddTransactionPage({super.key, this.initialType});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _installmentsCtrl = TextEditingController(text: '2');

  late TransactionType _type;
  DateTime _date = DateTime.now();
  String? _accountId;
  String? _categoryId;
  String? _transferAccountId;
  bool _isPaid = true;
  bool _isInstallment = false;
  RecurrenceType _recurrence = RecurrenceType.none;
  DateTime? _recurrenceEndDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initialType;
    if (t == 'income') {
      _type = TransactionType.income;
    } else if (t == 'transfer') {
      _type = TransactionType.transfer;
    } else if (t == 'installment') {
      _type = TransactionType.expense;
      _isInstallment = true;
    } else {
      _type = TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _installmentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma conta')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
      final userId = SupabaseService.currentUserId!;

      final transaction = TransactionModel(
        id: '',
        userId: userId,
        accountId: _accountId!,
        categoryId: _categoryId,
        amount: amount,
        type: _type,
        description: _descriptionCtrl.text.isNotEmpty ? _descriptionCtrl.text : null,
        date: _date,
        isPaid: _isPaid,
        recurrence: _recurrence,
        recurrenceEndDate: _recurrenceEndDate,
        transferAccountId: _transferAccountId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isInstallment) {
        final count = int.tryParse(_installmentsCtrl.text) ?? 2;
        await ref.read(transactionsProvider.notifier).addInstallments(transaction, count);
      } else {
        await ref.read(transactionsProvider.notifier).addTransaction(transaction);
      }

      if (mounted) context.pop();
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
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final isIncome = _type == TransactionType.income;
    final isTransfer = _type == TransactionType.transfer;
    final categories = isIncome
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    final headerColor = isTransfer
        ? AppColors.transfer
        : isIncome
            ? AppColors.income
            : AppColors.expense;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTransfer
            ? AppStrings.transfer
            : isIncome
                ? 'Nova Receita'
                : _isInstallment
                    ? 'Compra Parcelada'
                    : 'Nova Despesa'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selector
            if (!_isInstallment)
              _TypeSelector(
                type: _type,
                onChanged: (t) => setState(() {
                  _type = t;
                  _categoryId = null;
                }),
              ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: headerColor),
              decoration: InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(fontSize: 20, color: headerColor),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe o valor';
                if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 16),

            // Account
            DropdownButtonFormField<String>(
              value: _accountId,
              decoration: const InputDecoration(
                labelText: 'Conta',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              items: accounts
                  .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 16),

            // Transfer destination account
            if (isTransfer) ...[
              DropdownButtonFormField<String>(
                value: _transferAccountId,
                decoration: const InputDecoration(
                  labelText: 'Conta de destino',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                items: accounts
                    .where((a) => a.id != _accountId)
                    .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) => setState(() => _transferAccountId = v),
              ),
              const SizedBox(height: 16),
            ],

            // Category
            if (!isTransfer && categories.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Categoria (opcional)',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 16),
            ],

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Data'),
              trailing: Text(_date.toShortDate()),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const Divider(),

            // Paid toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pago / Recebido'),
              subtitle: Text(_isPaid ? 'Já realizado' : 'Pendente'),
              value: _isPaid,
              onChanged: (v) => setState(() => _isPaid = v),
            ),
            const Divider(),

            // Installments
            if (!isTransfer) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Compra parcelada'),
                value: _isInstallment,
                onChanged: (v) => setState(() {
                  _isInstallment = v;
                  if (v) _recurrence = RecurrenceType.none;
                }),
              ),
              if (_isInstallment) ...[
                TextFormField(
                  controller: _installmentsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de parcelas',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 2) return 'Mínimo 2 parcelas';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Recurrence
            if (!_isInstallment && !isTransfer) ...[
              DropdownButtonFormField<RecurrenceType>(
                value: _recurrence,
                decoration: const InputDecoration(
                  labelText: 'Recorrência',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: RecurrenceType.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (v) => setState(() => _recurrence = v!),
              ),
              if (_recurrence != RecurrenceType.none) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repetir até (opcional)'),
                  trailing: Text(_recurrenceEndDate?.toShortDate() ?? 'Sem fim'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: _date,
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _recurrenceEndDate = picked);
                  },
                ),
              ],
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final TransactionType type;
  final void Function(TransactionType) onChanged;

  const _TypeSelector({required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TransactionType>(
      segments: const [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text('Despesa'),
          icon: Icon(Icons.arrow_upward, size: 16),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text('Receita'),
          icon: Icon(Icons.arrow_downward, size: 16),
        ),
        ButtonSegment(
          value: TransactionType.transfer,
          label: Text('Transferência'),
          icon: Icon(Icons.swap_horiz, size: 16),
        ),
      ],
      selected: {type},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
