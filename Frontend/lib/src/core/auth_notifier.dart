import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintech_frontend/models/user.dart';
import 'auth_repository.dart';
import 'auth_change_notifier.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authChange = ref.read(authChangeNotifierProvider);
  return AuthNotifier(ref, authChange);
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final AuthChangeNotifier _authChange;

  AuthNotifier(this.ref, this._authChange) : super(const AuthState()) {
    _restoreSession();
  }

  // ---------- RESTORE SESSION ----------
  Future<void> _restoreSession() async {
    final repo = ref.read(authRepositoryProvider);
    final success = await repo.refreshTokenIfNeeded();

    if (success) {
      state = state.copyWith(
        isAuthenticated: true,
        user: repo.user,
      );
      _authChange.notify();
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

      _authChange.notify();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ---------- SIGNUP ----------
  Future<void> signup(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signup(payload);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: repo.user,
      );

      _authChange.notify();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ---------- LOGOUT ----------
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
    _authChange.notify();
  }
}
