import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(
    data: (state) => state.session?.user,
  );
});

class AuthNotifier extends AsyncNotifier<void> {
  late AuthRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.watch(authRepositoryProvider);
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signIn(email: email, password: password),
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final response = await _repo.signUp(email: email, password: password);
      if (response.session == null && response.user != null) {
        // Email confirmation required — treat as a special state
        state = AsyncError('email_confirmation_required', StackTrace.current);
      } else {
        state = const AsyncData(null);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
