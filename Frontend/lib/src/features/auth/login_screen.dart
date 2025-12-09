// lib/src/features/auth/login_screen.dart
import 'package:fintech_frontend/models/user_role.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../core/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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
          email: _email.text.trim(), password: _password.text);

      // after await authNotifier.login(...)
      final typedUser = ref.read(authNotifierProvider).user;
      debugPrint('[LoginScreen] logged in user: $typedUser');

      if (typedUser != null) {
        // typedUser.role is UserRole enum from models/user_role.dart
        switch (typedUser.role) {
          case UserRole.customer:
            context.go('/customer/dashboard');
            break;
          case UserRole.merchant:
            context.go('/merchant/dashboard');
            break;
          case UserRole.banker:
            context.go('/banker/dashboard');
            break;
          case UserRole.admin:
            context.go('/admin/dashboard');
            break;
          default:
            context.go('/');
        }
      } else {
        // No user returned (maybe backend requires email verification) -> go to login root
        context.go('/');
      }

      // Prefer router to handle redirect via refreshListenable, but navigate immediately too.
    } on ApiError catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Login failed. Check credentials or network.';
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.9, -0.6),
            end: Alignment(0.8, 0.8),
            colors: [Color(0xFF071028), Color(0xFF04293A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DT.gap),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 920 : 420),
                child: Row(
                  children: [
                    if (isWide)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Text('Welcome to FinPlatform',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            Text(
                                'Secure lending, fast approvals — built for customers, merchants and banks.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.white70)),
                            const SizedBox(height: 28),
                            Card(
                              elevation: 6,
                              color: Colors.white.withOpacity(0.06),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(DT.radius)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Instant approvals',
                                        style: TextStyle(color: Colors.white)),
                                    SizedBox(height: 6),
                                    Text('Low interest plans',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DT.radius)),
                        elevation: DT.elevationHigh,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Sign in',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: DT.gap),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _email,
                                      decoration: const InputDecoration(
                                          labelText: 'Email'),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Email required';
                                        final ok =
                                            RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                                .hasMatch(v.trim());
                                        return ok
                                            ? null
                                            : 'Enter a valid email';
                                      },
                                    ),
                                    const SizedBox(height: DT.gapSm),
                                    TextFormField(
                                      controller: _password,
                                      obscureText: !_showPassword,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        suffixIcon: IconButton(
                                          icon: Icon(_showPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                          onPressed: () => setState(() =>
                                              _showPassword = !_showPassword),
                                        ),
                                      ),
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Password required'
                                          : null,
                                    ),
                                    const SizedBox(height: DT.gapSm),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                                value: true, onChanged: null),
                                            const Text('Remember'),
                                          ],
                                        ),
                                        TextButton(
                                            onPressed: () {
                                              /* TODO: forgot password */
                                            },
                                            child: const Text('Forgot?')),
                                      ],
                                    ),
                                    if (_error != null) ...[
                                      const SizedBox(height: DT.gapSm),
                                      Text(_error!,
                                          style: const TextStyle(
                                              color: Colors.red)),
                                    ],
                                    const SizedBox(height: DT.gap),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: DT.accent,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        child: _loading
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))
                                            : const Text('Sign in',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                      ),
                                    ),
                                    const SizedBox(height: DT.gapSm),
                                    RichText(
                                      text: TextSpan(
                                        text: 'New here? ',
                                        style:
                                            TextStyle(color: DT.primaryVariant),
                                        children: [
                                          TextSpan(
                                            text: 'Create account',
                                            style: TextStyle(
                                                color: DT.accent,
                                                fontWeight: FontWeight.w600),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () =>
                                                  GoRouter.of(context)
                                                      .push('/signup'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: DT.gapSm),
                                    Row(
                                      children: const [
                                        Expanded(child: Divider()),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Text('or',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        Expanded(child: Divider()),
                                      ],
                                    ),
                                    const SizedBox(height: DT.gapSm),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.login),
                                            label: const Text('Google'),
                                          ),
                                        ),
                                        const SizedBox(width: DT.gapSm),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.facebook),
                                            label: const Text('Facebook'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
