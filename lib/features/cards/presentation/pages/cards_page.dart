import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extension.dart';
import '../../../accounts/data/models/account_model.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';

class CardsPage extends ConsumerWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    final cards = accountsAsync.valueOrNull
            ?.where((a) => a.type == AccountType.creditCard)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Cartões de Crédito',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => context.go('/accounts'),
            tooltip: 'Adicionar cartão',
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (_) => cards.isEmpty
            ? _buildEmpty(context)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  ...cards.map((card) => _CardWidget(account: card)),
                  const SizedBox(height: 16),
                  _buildTotalSummary(cards, ref),
                ],
              ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.credit_card_rounded,
                color: Color(0xFF444444), size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Nenhum cartão cadastrado',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Adicione um cartão em Contas',
              style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/accounts'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ir para Contas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummary(List<AccountModel> cards, WidgetRef ref) {
    double totalLimit = 0;
    int cardsWithLimit = 0;
    for (final c in cards) {
      if (c.creditLimit != null && c.creditLimit! > 0) {
        totalLimit += c.creditLimit!;
        cardsWithLimit++;
      }
    }

    if (cardsWithLimit == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Limite total combinado',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
              const SizedBox(height: 4),
              Text(totalLimit.toCurrency(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$cardsWithLimit cartão${cardsWithLimit > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: Color(0xFF888888), fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Visual Credit Card Widget ─────────────────────────────────────────────────

class _CardWidget extends ConsumerWidget {
  final AccountModel account;
  const _CardWidget({required this.account});

  // Generate a stable gradient based on the account color
  List<Color> _cardGradient() {
    final base = account.color;
    final hsl = HSLColor.fromColor(base);
    final lighter = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation - 0.1).clamp(0.0, 1.0))
        .toColor();
    final darker = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0))
        .withHue((hsl.hue + 30) % 360)
        .toColor();
    return [lighter, base, darker];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(cardInvoiceProvider(account.id));
    final limit = account.creditLimit;
    final gradColors = _cardGradient();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Physical card design
          AspectRatio(
            aspectRatio: 1.586, // standard credit card ratio
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: gradColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: account.color.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background pattern circles
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: -50,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  // Chip icon
                  Positioned(
                    left: 24,
                    top: 24,
                    child: _ChipIcon(),
                  ),
                  // Card content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: chip + brand
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 44), // chip placeholder
                            Icon(Icons.credit_card_rounded,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 28),
                          ],
                        ),
                        const Spacer(),
                        // Available amount
                        invoiceAsync.when(
                          loading: () => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white54)),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (inv) {
                            if (limit == null || limit <= 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fatura do mês',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(inv.total.toCurrency(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5)),
                                ],
                              );
                            }
                            final available = (limit - inv.total).clamp(0.0, limit);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Disponível',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.6),
                                        fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(available.toCurrency(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Bottom row: name + limit
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              account.name.toUpperCase(),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5),
                            ),
                            if (limit != null && limit > 0)
                              Text(
                                'Limite ${limit.toCurrency()}',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats below card
          invoiceAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (inv) => _buildStats(inv.total, limit, inv.transactions.length),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(double used, double? limit, int txCount) {
    final ratio = (limit != null && limit > 0)
        ? (used / limit).clamp(0.0, 1.0)
        : null;
    final barColor = ratio == null
        ? AppColors.expense
        : ratio >= 0.9
            ? AppColors.expense
            : ratio >= 0.7
                ? const Color(0xFFFF8F00)
                : AppColors.income;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatItem(
                label: 'Usado no mês',
                value: used.toCurrency(),
                color: AppColors.expense,
              ),
              const _Divider(),
              if (limit != null && limit > 0) ...[
                _StatItem(
                  label: 'Disponível',
                  value: (limit - used).clamp(0.0, limit).toCurrency(),
                  color: barColor,
                ),
                const _Divider(),
                _StatItem(
                  label: 'Limite',
                  value: limit.toCurrency(),
                  color: Colors.white70,
                ),
              ] else
                _StatItem(
                  label: 'Transações',
                  value: '$txCount este mês',
                  color: Colors.white70,
                ),
            ],
          ),
          if (ratio != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                backgroundColor: const Color(0xFF2A2A2A),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(ratio * 100).toStringAsFixed(0)}% utilizado',
                  style: TextStyle(
                      color: barColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  '${((1 - ratio) * 100).toStringAsFixed(0)}% livre',
                  style: const TextStyle(
                      color: Color(0xFF555555), fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 32, color: const Color(0xFF222222),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}

class _ChipIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.amber.shade300.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(5),
      ),
      child: CustomPaint(painter: _ChipPainter()),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.shade700.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Horizontal lines
    for (double y in [size.height * 0.35, size.height * 0.65]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical center
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    // Center rectangle
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.4,
      height: size.height * 0.4,
    );
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
