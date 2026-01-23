import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_notifier.dart';
import '../features/auth/login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);

    // 1️⃣ Still restoring session
    if (auth.isLoading) {
      return const _SplashScreen();
    }

    // 2️⃣ Not logged in
    if (!auth.isAuthenticated || auth.user == null) {
      return const LoginScreen();
    }

    // 3️⃣ Logged in → redirect ONCE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = auth.user!.role.name.toLowerCase();
      context.go('/$role/dashboard');
    });

    return const _SplashScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
