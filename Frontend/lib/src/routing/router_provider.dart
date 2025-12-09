// lib/src/routing/router_provider.dart
import 'package:fintech_frontend/src/features/admin/admin_dashboard.dart';
import 'package:fintech_frontend/src/features/auth/sign_up_screen.dart';
import 'package:fintech_frontend/src/features/banker/banker_dashboard.dart';
import 'package:fintech_frontend/src/features/customer/customer_dashboard.dart';
import 'package:fintech_frontend/src/features/customer/customer_dashboard_responsive.dart';
import 'package:fintech_frontend/src/features/merchant/merchant_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/login_screen.dart';
import '../core/auth_notifier.dart';
import '../core/auth_change_notifier.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authChange = ref.read(authChangeNotifierProvider);
  final authState = ref.read(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authChange,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(
          path: '/customer/dashboard',
          builder: (context, state) => const CustomerDashboardModern()),

      GoRoute(
          path: '/merchant/dashboard',
          builder: (context, state) => const MerchantDashboard()),
      GoRoute(
          path: '/banker/dashboard',
          builder: (context, state) => const BankerDashboard()),
      GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboard()),
      // add other role routes...
    ],
    redirect: (context, state) {
      final loggedIn = ref.read(authNotifierProvider).isAuthenticated;
      final location = state.location;
      final isAuthRoute = location == '/login' || location == '/signup';

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) {
        // example inside redirect:
        final typedUser = ref.read(authNotifierProvider).user;
        final role = typedUser?.role; // UserRole enum
        final roleStr = role?.toString().split('.').last.toLowerCase() ?? '';
        if (roleStr == 'customer') return '/customer/dashboard';
        if (roleStr == 'merchant') return '/merchant/dashboard';
        if (roleStr == 'banker') return '/banker/dashboard';
        if (roleStr == 'admin') return '/admin/dashboard';
      }
      return null;
    },
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
  );
});
