enum ExternalDebtType {
  credit('credit', 'Crédito'),
  loan('loan', 'Empréstimo'),
  financing('financing', 'Financiamento'),
  creditCard('credit_card', 'Cartão de Crédito'),
  utility('utility', 'Conta de Consumo'),
  tax('tax', 'Imposto / Tributo'),
  protest('protest', 'Protesto'),
  other('other', 'Outros');

  final String value;
  final String label;
  const ExternalDebtType(this.value, this.label);

  static ExternalDebtType fromValue(String v) =>
      ExternalDebtType.values.firstWhere((e) => e.value == v, orElse: () => ExternalDebtType.other);
}

enum ExternalDebtStatus {
  active('active', 'Em aberto'),
  negotiating('negotiating', 'Em negociação'),
  paid('paid', 'Quitada'),
  disputed('disputed', 'Contestada');

  final String value;
  final String label;
  const ExternalDebtStatus(this.value, this.label);

  static ExternalDebtStatus fromValue(String v) =>
      ExternalDebtStatus.values.firstWhere((e) => e.value == v, orElse: () => ExternalDebtStatus.active);
}

enum ExternalDebtSource {
  serasa('serasa', 'Serasa'),
  spc('spc', 'SPC'),
  protest('protest', 'Cartório / Protesto'),
  bacen('bacen', 'Banco Central'),
  other('other', 'Outro');

  final String value;
  final String label;
  const ExternalDebtSource(this.value, this.label);

  static ExternalDebtSource fromValue(String v) =>
      ExternalDebtSource.values.firstWhere((e) => e.value == v, orElse: () => ExternalDebtSource.other);
}

class ExternalDebtModel {
  final String id;
  final String userId;
  final String creditorName;
  final ExternalDebtType type;
  final ExternalDebtStatus status;
  final ExternalDebtSource source;
  final double originalAmount;
  final double? currentAmount;    // valor atualizado (com juros)
  final DateTime? dueDate;        // data original da dívida
  final DateTime? negativatedAt;  // data de negativação
  final String? contractNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExternalDebtModel({
    required this.id,
    required this.userId,
    required this.creditorName,
    required this.type,
    this.status = ExternalDebtStatus.active,
    this.source = ExternalDebtSource.serasa,
    required this.originalAmount,
    this.currentAmount,
    this.dueDate,
    this.negativatedAt,
    this.contractNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get displayAmount => currentAmount ?? originalAmount;
  bool get isNegativated => negativatedAt != null;
  bool get isActive => status == ExternalDebtStatus.active || status == ExternalDebtStatus.negotiating;

  factory ExternalDebtModel.fromMap(Map<String, dynamic> map) {
    return ExternalDebtModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      creditorName: map['creditor_name'] as String,
      type: ExternalDebtType.fromValue(map['type'] as String),
      status: ExternalDebtStatus.fromValue(map['status'] as String? ?? 'active'),
      source: ExternalDebtSource.fromValue(map['source'] as String? ?? 'serasa'),
      originalAmount: (map['original_amount'] as num).toDouble(),
      currentAmount: map['current_amount'] != null ? (map['current_amount'] as num).toDouble() : null,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      negativatedAt: map['negativated_at'] != null ? DateTime.parse(map['negativated_at'] as String) : null,
      contractNumber: map['contract_number'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'creditor_name': creditorName,
        'type': type.value,
        'status': status.value,
        'source': source.value,
        'original_amount': originalAmount,
        'current_amount': currentAmount,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'negativated_at': negativatedAt?.toIso8601String().split('T').first,
        'contract_number': contractNumber,
        'notes': notes,
      };

  ExternalDebtModel copyWith({
    String? creditorName,
    ExternalDebtType? type,
    ExternalDebtStatus? status,
    ExternalDebtSource? source,
    double? originalAmount,
    double? currentAmount,
    DateTime? dueDate,
    DateTime? negativatedAt,
    String? contractNumber,
    String? notes,
  }) {
    return ExternalDebtModel(
      id: id,
      userId: userId,
      creditorName: creditorName ?? this.creditorName,
      type: type ?? this.type,
      status: status ?? this.status,
      source: source ?? this.source,
      originalAmount: originalAmount ?? this.originalAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      dueDate: dueDate ?? this.dueDate,
      negativatedAt: negativatedAt ?? this.negativatedAt,
      contractNumber: contractNumber ?? this.contractNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
