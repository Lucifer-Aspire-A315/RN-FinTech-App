// lib/src/routing/role_router.dart
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
import '../core/auth_repository.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
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
    // Read auth provider via ProviderScope.containerOf to avoid listening
    final container = ProviderScope.containerOf(context, listen: false);
    final auth = container.read(authRepositoryProvider);
    final loggedIn = auth.user != null && auth.accessToken != null;

    // Use state.location (version-stable) instead of state.subloc/state.uri or GoRouter.of(context)
    final location = state.location;

    // allow unauthenticated users to access login & signup
    final isAuthRoute = location == '/login' || location == '/signup';

    if (!loggedIn && !isAuthRoute) return '/login';

    if (loggedIn && isAuthRoute) {
      final role = (auth.user?.role ?? '').toLowerCase();
      if (role == 'customer') return '/customer/dashboard';
      if (role == 'merchant') return '/merchant/dashboard';
      if (role == 'banker') return '/banker/dashboard';
      if (role == 'admin') return '/admin/dashboard';
    }
    return null;
  },
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text(state.error.toString()))),
);
