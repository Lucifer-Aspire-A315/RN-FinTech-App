// lib/src/features/auth/login_screen.dart

import 'package:fintech_frontend/models/user_role.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_notifier.dart';
import '../../core/design_tokens.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.9, -0.6),
            end: Alignment(0.8, 0.8),
            colors: [
              Color(0xFF071028),
              Color(0xFF04293A),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(DT.gap),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 960 : 420),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Expanded(child: _LeftMarketingPanel()),
                                SizedBox(width: DT.gap),
                                Expanded(child: _LoginCard()),
                              ],
                            )
                          : const _LoginCard(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────────────────────── LEFT PANEL ───────────────────────── */

class _LeftMarketingPanel extends StatelessWidget {
  const _LeftMarketingPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Welcome to FinPlatform',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Secure lending, fast approvals — built for customers, merchants and banks.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 28),
        Card(
          elevation: 8,
          color: Colors.white.withOpacity(0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DT.radius),
          ),
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚡ Instant approvals',
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 6),
                Text('💳 Flexible repayment plans',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/* ───────────────────────── LOGIN CARD ───────────────────────── */

class _LoginCard extends ConsumerStatefulWidget {
  const _LoginCard();

  @override
  ConsumerState<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends ConsumerState<_LoginCard> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final authNotifier = ref.read(authNotifierProvider.notifier);

    try {
      await authNotifier.login(
        _email.text.trim(),
        _password.text,
      );

      final typedUser = ref.read(authNotifierProvider).user;
      debugPrint('[LoginScreen] logged in user: $typedUser');

      if (!mounted) return;

      if (typedUser != null) {
        switch (typedUser.role) {
          case UserRole.customer:
            context.go('/customer/dashboard');
            return;
          case UserRole.merchant:
            context.go('/merchant/dashboard');
            return;
          case UserRole.banker:
            context.go('/banker/dashboard');
            return;
          case UserRole.admin:
            context.go('/admin/dashboard');
            return;
          default:
            context.go('/login');
            return;
        }
      } else {
        context.go('/login');
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      // 🔥 THIS IS THE IMPORTANT PART
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: DT.elevationHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DT.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: DT.gap),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email required';
                  }
                  return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())
                      ? null
                      : 'Enter valid email';
                },
              ),
              const SizedBox(height: DT.gapSm),
              TextFormField(
                controller: _password,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        size: 18),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password required' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: DT.gapSm),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: DT.gap),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DT.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: DT.gapSm),
              RichText(
                text: TextSpan(
                  text: 'New here? ',
                  style: TextStyle(color: DT.primaryVariant),
                  children: [
                    TextSpan(
                      text: 'Create account',
                      style: TextStyle(
                        color: DT.accent,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.push('/signup'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
