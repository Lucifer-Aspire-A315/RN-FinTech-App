// lib/src/features/auth/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_notifier.dart';
import '../../core/design_tokens.dart';

enum SignupRole { customer, merchant, banker }

extension SignupRoleExt on SignupRole {
  String get label {
    switch (this) {
      case SignupRole.customer:
        return 'Customer';
      case SignupRole.merchant:
        return 'Merchant';
      case SignupRole.banker:
        return 'Banker';
    }
  }

  String get roleString => label.toUpperCase();
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  SignupRole _role = SignupRole.customer;
  int _step = 0;
  bool _loading = false;
  String? _error;

  // Common
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  // Merchant
  final _bizName = TextEditingController();
  final _bizGstin = TextEditingController();
  final _bizAddress = TextEditingController();

  // Banker
  final _employeeId = TextEditingController();
  final _bankBranch = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _bizName.dispose();
    _bizGstin.dispose();
    _bizAddress.dispose();
    _employeeId.dispose();
    _bankBranch.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'role': _role.roleString,
    };

    if (_phone.text.trim().isNotEmpty) {
      payload['phone'] = _phone.text.trim();
    }

    if (_role == SignupRole.merchant) {
      payload.addAll({
        'businessName': _bizName.text.trim(),
        if (_bizGstin.text.trim().isNotEmpty)
          'gstNumber': _bizGstin.text.trim(),
        if (_bizAddress.text.trim().isNotEmpty)
          'address': _bizAddress.text.trim(),
      });
    }

    if (_role == SignupRole.banker) {
      payload.addAll({
        // TEMP – must be replaced with real bank selection later
        'bankId': 'TEMP_BANK_ID',
        'branch': _bankBranch.text.trim(),
        'employeeId': _employeeId.text.trim(),
      });
    }

    return payload;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signup(_buildPayload());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created. Please verify your email before logging in.',
          ),
        ),
      );

      // 🔁 Go back to login
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Signup failed. Please check details and try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMulti = _role != SignupRole.customer;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(DT.gap),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      elevation: DT.elevationHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DT.radius),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(DT.gapLg),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Sign up',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: DT.gap),

                              /// ROLE SELECTOR
                              Wrap(
                                spacing: DT.gapSm,
                                children: SignupRole.values.map((r) {
                                  return ChoiceChip(
                                    label: Text(r.label),
                                    selected: _role == r,
                                    onSelected: (_) {
                                      setState(() {
                                        _role = r;
                                        _step = 0;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: DT.gap),

                              /// STEP 1 – BASIC
                              if (!isMulti || _step == 0) ...[
                                _field(_name, 'Full name'),
                                _emailField(),
                                _passwordField(),
                                _field(_phone, 'Phone (optional)',
                                    required: false),
                              ],

                              /// STEP 2 – ROLE SPECIFIC
                              if (isMulti && _step == 1) ...[
                                if (_role == SignupRole.merchant)
                                  _field(_bizName, 'Business name'),
                                if (_role == SignupRole.banker) ...[
                                  _field(_employeeId, 'Employee ID'),
                                  _field(_bankBranch, 'Branch'),
                                ],
                              ],

                              if (_error != null) ...[
                                const SizedBox(height: DT.gapSm),
                                Text(_error!,
                                    style: const TextStyle(color: Colors.red)),
                              ],

                              const SizedBox(height: DT.gap),

                              /// ACTIONS
                              Row(
                                children: [
                                  if (isMulti && _step > 0)
                                    OutlinedButton(
                                      onPressed: () => setState(() => _step--),
                                      child: const Text('Back'),
                                    ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                            if (isMulti && _step == 0) {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                setState(() => _step = 1);
                                              }
                                            } else {
                                              _submit();
                                            }
                                          },
                                    child: _loading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : Text(isMulti && _step == 0
                                            ? 'Next'
                                            : 'Create account'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DT.gapSm),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _emailField() => _field(_email, 'Email');

  Widget _passwordField() => Padding(
        padding: const EdgeInsets.only(bottom: DT.gapSm),
        child: TextFormField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
          validator: (v) =>
              (v == null || v.length < 8) ? 'Min 8 characters' : null,
        ),
      );
}
