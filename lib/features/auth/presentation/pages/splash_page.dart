import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Blob de gradiente — centro/topo
          Positioned(
            top: -60,
            left: -40,
            right: -40,
            child: _GradientBlob(
              colors: const [
                Color(0xFF6B35FF),
                Color(0xFFFF5733),
                Color(0xFFFF9500),
              ],
              width: MediaQuery.of(context).size.width + 80,
              height: MediaQuery.of(context).size.height * 0.55,
            ),
          ),

          // Overlay escuro sobre o blob
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.3, 0.6, 1.0],
                  colors: [
                    Colors.transparent,
                    Color(0xCC0A0A0A),
                    Color(0xFF0A0A0A),
                  ],
                ),
              ),
            ),
          ),

          // Linhas decorativas (inspirado na referência)
          Positioned(
            top: 80,
            right: 20,
            child: _DecorativeLine(),
          ),

          // Conteúdo
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      SvgPicture.asset(
                        'assets/images/logo.svg',
                        height: 44,
                      ),
                      const SizedBox(height: 28),

                      // Headline
                      const Text(
                        'Controle suas\nfinanças.',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Domine seus gastos.',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                          height: 1.1,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Receitas, despesas, cobranças e metas\nno mesmo lugar. Grátis.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.5),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go('/register'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0A0A0A),
                            minimumSize: const Size.fromHeight(58),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Começar agora'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Link login
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Já tenho conta  →',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBlob extends StatelessWidget {
  final List<Color> colors;
  final double width;
  final double height;

  const _GradientBlob({
    required this.colors,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: RadialGradient(
          center: const Alignment(0.2, 0.3),
          radius: 0.85,
          colors: colors,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.2),
            radius: 0.6,
            colors: [
              const Color(0xFF4400FF).withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorativeLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 200),
      painter: _LinePainter(),
    );
  }
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    path1.moveTo(size.width, 0);
    path1.quadraticBezierTo(0, size.height * 0.4, size.width * 0.3, size.height);
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(size.width * 0.6, 0);
    path2.quadraticBezierTo(size.width * 0.2, size.height * 0.5, size.width * 0.8, size.height);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
