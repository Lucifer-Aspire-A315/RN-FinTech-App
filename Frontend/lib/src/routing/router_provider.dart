import 'package:fintech_frontend/src/core/auth_change_notifier.dart';
import 'package:fintech_frontend/src/core/auth_notifier.dart';
import 'package:fintech_frontend/src/features/auth/email_not_verified_screen.dart';
import 'package:fintech_frontend/src/features/auth/forgot_password_screen.dart';
import 'package:fintech_frontend/src/features/auth/login_screen.dart';
import 'package:fintech_frontend/src/features/auth/reset_password_screen.dart';
import 'package:fintech_frontend/src/features/auth/sign_up_screen.dart';
import 'package:fintech_frontend/src/features/auth/verify_email_screen.dart';
import 'package:fintech_frontend/src/features/admin/admin_dashboard.dart';
import 'package:fintech_frontend/src/features/admin/bank_management_screen.dart';
import 'package:fintech_frontend/src/features/admin/loan_type_management_screen.dart';
import 'package:fintech_frontend/src/features/banker/banker_dashboard.dart';
import 'package:fintech_frontend/src/features/customer/customer_dashboard.dart';
import 'package:fintech_frontend/src/features/merchant/merchant_dashboard.dart';
import 'package:fintech_frontend/src/features/loans/loan_apply_screen.dart';
import 'package:fintech_frontend/src/features/loans/loan_detail_screen.dart';
import 'package:fintech_frontend/src/features/loans/loan_list_screen.dart';
import 'package:fintech_frontend/src/features/kyc/kyc_center_screen.dart';
import 'package:fintech_frontend/src/features/kyc/kyc_review_screen.dart';
import 'package:fintech_frontend/src/features/settings/security_screen.dart';
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
          location.startsWith('/forgot-password') ||
          location.startsWith('/reset-password') ||
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
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final token = state.queryParameters['token'];
          return ResetPasswordScreen(tokenFromLink: token);
        },
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

      GoRoute(
        path: '/admin/dashboard',
        builder: (_, __) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/loan-types',
        builder: (_, __) => const LoanTypeManagementScreen(),
      ),
      GoRoute(
        path: '/admin/banks',
        builder: (_, __) => const BankManagementScreen(),
      ),

      GoRoute(
        path: '/security',
        builder: (_, __) => const SecurityScreen(),
      ),

      GoRoute(
        path: '/loans',
        builder: (_, __) => const LoanListScreen(),
      ),
      GoRoute(
        path: '/loans/apply',
        builder: (_, __) => const LoanApplyScreen(),
      ),
      GoRoute(
        path: '/loans/:id',
        builder: (_, state) => LoanDetailScreen(loanId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/kyc',
        builder: (_, __) => const KycCenterScreen(),
      ),
      GoRoute(
        path: '/kyc/review',
        builder: (_, __) => const KycReviewScreen(),
      ),
    ],
  );
});
