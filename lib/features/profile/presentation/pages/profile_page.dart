import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/dark_text_field.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _savingName = false;
  bool _savingPass = false;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    final user = SupabaseService.client.auth.currentUser;
    _nameCtrl.text = user?.userMetadata?['name'] as String? ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String get _userEmail =>
      SupabaseService.client.auth.currentUser?.email ?? '';

  String get _initials {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      final e = _userEmail;
      return e.isNotEmpty ? e[0].toUpperCase() : '?';
    }
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingName = true);
    try {
      await SupabaseService.client.auth
          .updateUser(UserAttributes(data: {'name': name}));
      if (mounted) {
        _showSnack('Nome atualizado!', success: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Erro ao salvar nome.');
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _savePassword() async {
    if (_newPassCtrl.text.length < 6) {
      _showSnack('A nova senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showSnack('As senhas não coincidem.');
      return;
    }
    setState(() => _savingPass = true);
    try {
      await SupabaseService.client.auth
          .updateUser(UserAttributes(password: _newPassCtrl.text));
      if (mounted) {
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        _showSnack('Senha alterada com sucesso!', success: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Erro ao alterar senha. Tente novamente.');
    } finally {
      if (mounted) setState(() => _savingPass = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) context.go('/');
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir conta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
          'Todos os seus dados serão apagados permanentemente. Esta ação não pode ser desfeita.',
          style: TextStyle(color: Color(0xFF888888), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Excluir',
                style: TextStyle(
                    color: AppColors.expense, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      // Delete all user data then sign out (RLS cascade deletes data)
      await SupabaseService.client.rpc('delete_user');
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) context.go('/');
    } catch (_) {
      // If RPC not available, just sign out
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) context.go('/');
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.income : AppColors.expense,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Minha Conta',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAvatar(),
          const SizedBox(height: 32),
          _sectionLabel('Perfil'),
          const SizedBox(height: 12),
          _buildNameCard(),
          const SizedBox(height: 24),
          _sectionLabel('Segurança'),
          const SizedBox(height: 12),
          _buildPasswordCard(),
          const SizedBox(height: 24),
          _sectionLabel('Sessão'),
          const SizedBox(height: 12),
          _buildSignOutCard(),
          const SizedBox(height: 24),
          _sectionLabel('Zona de Perigo'),
          const SizedBox(height: 12),
          _buildDeleteCard(),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Finup v1.0.0',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6B35FF), Color(0xFFFF5733)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Sem nome',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _userEmail));
              _showSnack('E-mail copiado!', success: true);
            },
            child: Text(
              _userEmail,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DarkTextField(
            controller: _nameCtrl,
            label: 'Nome de exibição',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _saveName(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingName ? null : _saveName,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: _savingName
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Salvar nome'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return _Card(
      child: Column(
        children: [
          DarkTextField(
            controller: _newPassCtrl,
            label: 'Nova senha',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureNew,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 12),
          DarkTextField(
            controller: _confirmPassCtrl,
            label: 'Confirmar nova senha',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureNew,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _savePassword(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingPass ? null : _savePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: _savingPass
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Alterar senha'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutCard() {
    return _Card(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF272727),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.logout_rounded,
              color: Colors.white70, size: 20),
        ),
        title: const Text('Sair da conta',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        subtitle: const Text('Encerrar sessão neste dispositivo',
            style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Color(0xFF444444), size: 14),
        onTap: _signOut,
      ),
    );
  }

  Widget _buildDeleteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.expense.withValues(alpha: 0.25), width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.expense.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_forever_rounded,
              color: AppColors.expense, size: 20),
        ),
        title: Text('Excluir conta',
            style: TextStyle(
                color: AppColors.expense,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        subtitle: const Text('Remove todos os dados permanentemente',
            style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: AppColors.expense.withValues(alpha: 0.4), size: 14),
        onTap: _confirmDeleteAccount,
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: child,
    );
  }
}
