import 'package:fintech_frontend/models/user_role.dart';
import 'package:fintech_frontend/src/core/auth_change_notifier.dart';
import 'package:fintech_frontend/src/core/auth_notifier.dart';
import 'package:fintech_frontend/src/features/auth/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/customer/customer_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authChange = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    initialLocation: '/login',

    // 🔥 THIS IS THE KEY FIX
    refreshListenable: authChange,

    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final user = auth.user;
      final loggingIn = state.matchedLocation == '/login';
      final signingUp = state.matchedLocation == '/signup';

      // NOT logged in → allow login/signup only
      if (user == null) {
        return (loggingIn || signingUp) ? null : '/login';
      }

      // Logged in → block auth pages
      if (loggingIn || signingUp) {
        switch (user.role) {
          case UserRole.customer:
            return '/customer/dashboard';
          case UserRole.merchant:
            return '/merchant/dashboard';
          case UserRole.banker:
            return '/banker/dashboard';
          case UserRole.admin:
            return '/admin/dashboard';
          default:
            return '/login';
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/customer/dashboard',
        builder: (_, __) => const CustomerDashboard(),
      ),
      // add merchant/banker later
    ],
  );
});
