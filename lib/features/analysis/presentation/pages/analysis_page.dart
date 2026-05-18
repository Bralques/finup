import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../data/repositories/analysis_repository.dart';
import '../providers/analysis_provider.dart';

class AnalysisPage extends ConsumerWidget {
  const AnalysisPage({super.key});

  static const _bg = Color(0xFF0A0A0A);
  static const _card = Color(0xFF1C1C1C);
  static const _border = Color(0xFF272727);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Análise Financeira IA'),
        actions: [
          if (state.hasValue && state.value != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(analysisProvider.notifier).analyze(),
              tooltip: 'Atualizar análise',
            ),
        ],
      ),
      body: state.when(
        loading: () => _buildLoading(),
        error: (e, _) => _buildError(context, ref, e),
        data: (analysis) => analysis == null
            ? _buildEmpty(context, ref)
            : _buildAnalysis(context, ref, analysis),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blob animado
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(seconds: 2),
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF6B35FF), Color(0xFFFF5733)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B35FF).withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analisando suas finanças...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A IA está lendo seus dados dos últimos 3 meses',
            style: TextStyle(color: Color(0xFF666666), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Color(0xFF222222),
              color: AppColors.accent,
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B35FF), Color(0xFFFF5733)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Análise Financeira com IA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'A IA lê todos os seus dados — saldo, gastos, metas e dívidas — e entrega um diagnóstico completo com recomendações personalizadas.',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _FeatureRow(icon: Icons.trending_up, text: 'Score de saúde financeira 0–10'),
            _FeatureRow(icon: Icons.warning_amber_rounded, text: 'Alertas e riscos detectados'),
            _FeatureRow(icon: Icons.lightbulb_outline, text: 'Recomendações práticas'),
            _FeatureRow(icon: Icons.flag_outlined, text: 'Projeção das suas metas'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(analysisProvider.notifier).analyze(),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Analisar agora'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.expense, size: 48),
            const SizedBox(height: 16),
            const Text('Erro ao gerar análise',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              error.toString().contains('AI_PROVIDER') || error.toString().contains('key')
                  ? 'Configure a chave da IA em Supabase → Secrets (XAI_API_KEY, GEMINI_API_KEY ou GROQ_API_KEY)'
                  : error.toString(),
              style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(analysisProvider.notifier).analyze(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysis(
      BuildContext context, WidgetRef ref, FinancialAnalysis analysis) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score card principal
        _ScoreCard(analysis: analysis),
        const SizedBox(height: 16),

        // Resumo
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.summarize_outlined, size: 16, color: Color(0xFF888888)),
                  SizedBox(width: 6),
                  Text('Situação Atual',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF888888))),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                analysis.summary,
                style: const TextStyle(
                    fontSize: 15, height: 1.5, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Positivos
        if (analysis.positives.isNotEmpty) ...[
          _ListCard(
            title: 'Pontos Positivos',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.income,
            items: analysis.positives,
          ),
          const SizedBox(height: 12),
        ],

        // Alertas
        if (analysis.alerts.isNotEmpty) ...[
          _ListCard(
            title: 'Alertas',
            icon: Icons.warning_amber_rounded,
            color: AppColors.expense,
            items: analysis.alerts,
          ),
          const SizedBox(height: 12),
        ],

        // Recomendações
        if (analysis.recommendations.isNotEmpty) ...[
          _RecommendationsCard(items: analysis.recommendations),
          const SizedBox(height: 12),
        ],

        // Metas
        if (analysis.goalsOutlook.isNotEmpty) ...[
          _DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 16, color: Color(0xFF888888)),
                    SizedBox(width: 6),
                    Text('Perspectiva das Metas',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF888888))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  analysis.goalsOutlook,
                  style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Taxa de poupança + tendência
        Row(
          children: [
            Expanded(
              child: _StatMiniCard(
                label: 'Taxa de Poupança',
                value: '${(analysis.savingsRate * 100).toStringAsFixed(1)}%',
                icon: Icons.savings_outlined,
                color: analysis.savingsRate >= 0.2
                    ? AppColors.income
                    : analysis.savingsRate >= 0.1
                        ? AppColors.moodNeutral
                        : AppColors.expense,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatMiniCard(
                label: 'Tendência',
                value: analysis.trendLabel,
                icon: analysis.trend == 'improving'
                    ? Icons.trending_up_rounded
                    : analysis.trend == 'worsening'
                        ? Icons.trending_down_rounded
                        : Icons.trending_flat_rounded,
                color: analysis.trend == 'improving'
                    ? AppColors.income
                    : analysis.trend == 'worsening'
                        ? AppColors.expense
                        : AppColors.moodNeutral,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Atualizar
        OutlinedButton.icon(
          onPressed: () => ref.read(analysisProvider.notifier).analyze(),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Nova análise'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF888888),
            side: const BorderSide(color: Color(0xFF333333)),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gerado em ${_formatDate(analysis.generatedAt)}',
          style: const TextStyle(color: Color(0xFF444444), fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Widgets ────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final FinancialAnalysis analysis;
  const _ScoreCard({required this.analysis});

  Color get _scoreColor {
    if (analysis.score >= 8) return AppColors.income;
    if (analysis.score >= 6) return const Color(0xFF8BC34A);
    if (analysis.score >= 4) return AppColors.moodNeutral;
    if (analysis.score >= 2) return AppColors.moodBad;
    return AppColors.expense;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A2E), Color(0xFF2A1010)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          // Score circular
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CircularProgressIndicator(
                  value: analysis.score / 10,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFF333333),
                  valueColor: AlwaysStoppedAnimation(_scoreColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${analysis.score}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _scoreColor,
                    ),
                  ),
                  Text(
                    '/10',
                    style: TextStyle(
                        fontSize: 11, color: _scoreColor.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saúde Financeira',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 4),
                Text(
                  analysis.scoreLabel,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _scoreColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      analysis.trend == 'improving'
                          ? Icons.trending_up_rounded
                          : analysis.trend == 'worsening'
                              ? Icons.trending_down_rounded
                              : Icons.trending_flat_rounded,
                      size: 14,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      analysis.trendLabel,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

class _ListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _ListCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Text(item,
                          style: const TextStyle(
                              fontSize: 13, height: 1.4, color: Colors.white)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final List<String> items;
  const _RecommendationsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.08),
            const Color(0xFF1C1C1C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.accent),
              SizedBox(width: 6),
              Text(
                'Recomendações',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                            fontSize: 13, height: 1.4, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF272727)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF666666))),
        ],
      ),
    );
  }
}
