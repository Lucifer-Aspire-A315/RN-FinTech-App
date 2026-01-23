import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../core/auth_repository.dart';

class EmailNotVerifiedScreen extends ConsumerStatefulWidget {
  final String email;
  const EmailNotVerifiedScreen({super.key, required this.email});

  @override
  ConsumerState<EmailNotVerifiedScreen> createState() =>
      _EmailNotVerifiedScreenState();
}

class _EmailNotVerifiedScreenState
    extends ConsumerState<EmailNotVerifiedScreen> {
  bool _loading = false;
  String? _message;

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await ref.read(authRepositoryProvider).resendVerification(widget.email);

      setState(() {
        _message =
            'Verification email sent again. Please check your inbox.';
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to resend email. Try again later.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(DT.gapLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email_outlined, size: 72),
              const SizedBox(height: DT.gap),
              const Text(
                'Email not verified',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: DT.gapSm),
              Text(
                'We’ve sent a verification link to:\n${widget.email}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DT.gap),
              if (_message != null)
                Text(
                  _message!,
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: DT.gap),
              ElevatedButton(
                onPressed: _loading ? null : _resend,
                child: _loading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Resend verification email'),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
