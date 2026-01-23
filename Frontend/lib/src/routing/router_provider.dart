import 'package:fintech_frontend/src/core/auth_change_notifier.dart';
import 'package:fintech_frontend/src/core/auth_notifier.dart';
import 'package:fintech_frontend/src/features/auth/email_not_verified_screen.dart';
import 'package:fintech_frontend/src/features/auth/login_screen.dart';
import 'package:fintech_frontend/src/features/auth/sign_up_screen.dart';
import 'package:fintech_frontend/src/features/auth/verify_email_screen.dart';
import 'package:fintech_frontend/src/features/banker/banker_dashboard.dart';
import 'package:fintech_frontend/src/features/customer/customer_dashboard.dart';
import 'package:fintech_frontend/src/features/merchant/merchant_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authChange = ref.read(authChangeNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authChange,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final loggedIn = auth.isAuthenticated;

      final location = state.location;

      // 🟢 PUBLIC ROUTES (no auth required)
      final isPublicRoute = location.startsWith('/login') ||
          location.startsWith('/signup') ||
          location.startsWith('/verify-email') ||
          location.startsWith('/email-not-verified');

      // 🔐 NOT LOGGED IN
      if (!loggedIn) {
        return isPublicRoute ? null : '/login';
      }

      // ✅ LOGGED IN → prevent visiting auth pages
      if (location == '/login' || location == '/signup') {
        final role = auth.user?.role.name.toLowerCase();
        return '/$role/dashboard';
      }

      return null;
    },
    routes: [
      // ───────── AUTH ─────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),

      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final token = state.queryParameters['token'];

          if (token == null || token.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Invalid verification link')),
            );
          }

          return VerifyEmailScreen(token: token);
        },
      ),

      GoRoute(
        path: '/email-not-verified',
        builder: (context, state) {
          final email = state.extra as String?;
          if (email == null) {
            return const Scaffold(
              body: Center(child: Text('Email not provided')),
            );
          }
          return EmailNotVerifiedScreen(email: email);
        },
      ),

      // ───────── DASHBOARDS ─────────
      GoRoute(
        path: '/customer/dashboard',
        builder: (_, __) => const CustomerDashboard(),
      ),

      GoRoute(
        path: '/merchant/dashboard',
        builder: (_, __) => const MerchantDashboard(),
      ),

      GoRoute(
        path: '/banker/dashboard',
        builder: (_, __) => const BankerDashboard(),
      ),
    ],
  );
});
