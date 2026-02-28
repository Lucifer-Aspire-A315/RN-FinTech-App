import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import 'auth_change_notifier.dart';
import 'auth_state.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authChange = ref.read(authChangeNotifierProvider);
  return AuthNotifier(ref, authChange);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final AuthChangeNotifier _authChange;

  AuthNotifier(this.ref, this._authChange) : super(const AuthState()) {
    _restoreSession();
  }

  // ---------- RESTORE SESSION ----------
  Future<void> _restoreSession() async {
    state = state.copyWith(isLoading: true);

    final repo = ref.read(authRepositoryProvider);
    final success = await repo.refreshTokenIfNeeded();

    if (success) {
      state = state.copyWith(
        isAuthenticated: true,
        user: repo.user,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  // ---------- LOGIN ----------
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.login(email, password);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: repo.user,
      );

      _authChange.notify(); // 🔥 IMPORTANT
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
    _authChange.notify(); // 🔥 IMPORTANT
  }

  Future<void> refreshUser() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final current = await repo.fetchCurrentUser();
      state = state.copyWith(user: current);
      _authChange.notify();
    } catch (_) {}
  }

  // ---------- SIGNUP ----------
  Future<void> signup(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signup(payload);

      state = state.copyWith(
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}
