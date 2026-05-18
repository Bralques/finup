import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_service.dart';

class AuthRepository {
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({required String email, required String password}) async {
    return SupabaseService.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await SupabaseService.client.auth.resetPasswordForEmail(email);
  }

  User? get currentUser => SupabaseService.currentUser;
  bool get isAuthenticated => currentUser != null;
}
