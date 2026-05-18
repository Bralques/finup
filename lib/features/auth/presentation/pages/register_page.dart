import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../shared/widgets/dark_text_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (_, state) {
      if (!state.hasError) return;
      final err = state.error;

      if (err is String && err == 'email_confirmation_required') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '📧 Confirme seu e-mail para continuar.\nVerifique sua caixa de entrada.',
            ),
            backgroundColor: const Color(0xFF6B35FF),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final msg = err?.toString() ?? '';
      final friendlyMsg = msg.contains('already registered') || msg.contains('already been registered')
          ? 'Este e-mail já está cadastrado. Tente entrar.'
          : msg.contains('invalid') || msg.contains('Invalid')
              ? 'E-mail inválido. Verifique e tente novamente.'
              : msg.contains('weak') || msg.contains('short')
                  ? 'Senha muito fraca. Use pelo menos 6 caracteres.'
                  : 'Erro: $msg';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMsg),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Blob decorativo
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFFF5733), Color(0xFF0A0A0A)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(height: 48),

                    SvgPicture.asset('assets/images/logo.svg', height: 36),
                    const SizedBox(height: 20),

                    const Text(
                      'Criar sua\nconta ✨',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'É gratuito e leva menos de 1 minuto',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.45)),
                    ),
                    const SizedBox(height: 40),

                    DarkTextField(
                      controller: _emailCtrl,
                      label: 'E-mail',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return AppStrings.errorRequired;
                        if (!v.contains('@')) return AppStrings.errorInvalidEmail;
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    DarkTextField(
                      controller: _passwordCtrl,
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.white38, size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return AppStrings.errorRequired;
                        if (v.length < 6) return AppStrings.errorPasswordMin;
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    DarkTextField(
                      controller: _confirmCtrl,
                      label: 'Confirmar senha',
                      icon: Icons.lock_outline,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return AppStrings.errorRequired;
                        if (v != _passwordCtrl.text) return AppStrings.errorPasswordMatch;
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0A0A0A),
                          minimumSize: const Size.fromHeight(58),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Color(0xFF0A0A0A)))
                            : const Text('Criar conta'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/login'),
                        child: RichText(
                          text: TextSpan(
                            text: 'Já tem conta? ',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14),
                            children: const [
                              TextSpan(
                                text: 'Entrar',
                                style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
