// lib/src/core/auth_state.dart
import 'package:fintech_frontend/models/user.dart';


class AuthState {
  final String? accessToken;
  final User? user;

  const AuthState({this.accessToken, this.user});

  AuthState copyWith({String? accessToken, User? user}) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      user: user ?? this.user,
    );
  }

  bool get isAuthenticated => accessToken != null && user != null;
}
