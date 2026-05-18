import '../../../../core/supabase/supabase_service.dart';

class FinancialAnalysis {
  final int score;
  final String scoreLabel;
  final String summary;
  final List<String> positives;
  final List<String> alerts;
  final List<String> recommendations;
  final String goalsOutlook;
  final double savingsRate;
  final String trend;
  final String trendLabel;
  final DateTime generatedAt;

  const FinancialAnalysis({
    required this.score,
    required this.scoreLabel,
    required this.summary,
    required this.positives,
    required this.alerts,
    required this.recommendations,
    required this.goalsOutlook,
    required this.savingsRate,
    required this.trend,
    required this.trendLabel,
    required this.generatedAt,
  });

  factory FinancialAnalysis.fromMap(Map<String, dynamic> map) {
    return FinancialAnalysis(
      score: ((map['score'] as num?) ?? 0).round(),
      scoreLabel: map['score_label'] as String? ?? 'Regular',
      summary: map['summary'] as String? ?? '',
      positives: List<String>.from(map['positives'] ?? []),
      alerts: List<String>.from(map['alerts'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      goalsOutlook: map['goals_outlook'] as String? ?? '',
      savingsRate: ((map['savings_rate'] as num?) ?? 0).toDouble(),
      trend: map['trend'] as String? ?? 'stable',
      trendLabel: map['trend_label'] as String? ?? 'Estável',
      generatedAt: map['generated_at'] != null
          ? DateTime.parse(map['generated_at'] as String)
          : DateTime.now(),
    );
  }
}

class AnalysisRepository {
  Future<FinancialAnalysis> analyze() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Usuário não autenticado');

    final result = await SupabaseService.client.functions.invoke(
      'financial-analysis',
      body: {'userId': userId},
    );

    if (result.status != 200) {
      throw Exception('Erro na análise: ${result.data}');
    }

    final analysisMap = result.data['analysis'] as Map<String, dynamic>;
    return FinancialAnalysis.fromMap(analysisMap);
  }
}
