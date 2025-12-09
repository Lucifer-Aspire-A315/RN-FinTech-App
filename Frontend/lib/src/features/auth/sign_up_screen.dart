// lib/src/features/auth/signup_screen.dart
import 'package:fintech_frontend/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/auth_notifier.dart';

enum SignupRole { customer, merchant, banker, admin }

extension SignupRoleExt on SignupRole {
  String get label {
    switch (this) {
      case SignupRole.customer:
        return 'Customer';
      case SignupRole.merchant:
        return 'Merchant';
      case SignupRole.banker:
        return 'Banker';
      case SignupRole.admin:
        return 'Admin';
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

  int _step = 0; // for multi-step merchant/banker
  bool _loading = false;
  String? _error;

  // common fields
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  // merchant-specific
  final _bizName = TextEditingController();
  final _bizReg = TextEditingController();
  final _bizGstin = TextEditingController();
  final _bizAddress = TextEditingController();

  // banker-specific
  final _employeeId = TextEditingController();
  final _bankName = TextEditingController();
  final _bankBranch = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _bizName.dispose();
    _bizReg.dispose();
    _bizGstin.dispose();
    _bizAddress.dispose();
    _employeeId.dispose();
    _bankName.dispose();
    _bankBranch.dispose();
    super.dispose();
  }

  // Build role-specific payload. IMPORTANT: adjust keys to match your backend's expected field names
  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'role': _role.roleString, // e.g. CUSTOMER
    }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));

    if (_role == SignupRole.merchant) {
      payload.addAll({
        // adapt these keys if your backend expects snake_case
        'businessName': _bizName.text.trim(),
        'businessReg': _bizReg.text.trim().isEmpty ? null : _bizReg.text.trim(),
        'gstin': _bizGstin.text.trim().isEmpty ? null : _bizGstin.text.trim(),
        'address':
            _bizAddress.text.trim().isEmpty ? null : _bizAddress.text.trim(),
      }..removeWhere((k, v) => v == null || (v is String && v.isEmpty)));
    }

    if (_role == SignupRole.banker) {
      payload.addAll({
        'employeeId': _employeeId.text.trim(),
        'bankName': _bankName.text.trim(),
        'branch':
            _bankBranch.text.trim().isEmpty ? null : _bankBranch.text.trim(),
      }..removeWhere((k, v) => v == null || (v is String && v.isEmpty)));
    }

    return payload;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final notifier = ref.read(authNotifierProvider.notifier);

    try {
      final payload = _buildPayload();
      await notifier.signup(payload: payload);

      // typed user available at provider now (if backend returned user)
      final typedUser = ref.read(authNotifierProvider).user;
debugPrint('[SignupScreen] signed up user: $typedUser');

if (typedUser != null) {
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
  context.go('/login'); // backend might require verification first
}

    } on ApiError catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Signup failed. Please try again.';
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  Widget _roleChips() {
    return Wrap(
      spacing: DT.gapSm,
      children: SignupRole.values.map((r) {
        final selected = r == _role;
        return ChoiceChip(
          label: Text(r.label),
          selected: selected,
          onSelected: (_) => setState(() {
            _role = r;
            _step = 0;
          }),
          selectedColor: DT.accent.withOpacity(0.12),
          backgroundColor: DT.surfaceElevated,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;
    final isMulti = _role == SignupRole.merchant || _role == SignupRole.banker;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DT.gap),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 720 : 420),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DT.radius)),
                elevation: DT.elevationHigh,
                child: Padding(
                  padding: const EdgeInsets.all(DT.gapLg),
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sign up',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            TextButton(
                                onPressed: () => context.go('/login'),
                                child: const Text('Have an account?')),
                          ]),
                      const SizedBox(height: DT.gap),
                      _roleChips(),
                      const SizedBox(height: DT.gap),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (isMulti) StepperHeader(step: _step, total: 2),
                            // Step 0: basic info
                            if (!isMulti || _step == 0) ...[
                              TextFormField(
                                  controller: _name,
                                  decoration: const InputDecoration(
                                      labelText: 'Full name'),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null),
                              const SizedBox(height: DT.gapSm),
                              TextFormField(
                                  controller: _email,
                                  decoration:
                                      const InputDecoration(labelText: 'Email'),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Required';
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                        .hasMatch(v.trim()))
                                      return 'Enter valid email';
                                    return null;
                                  }),
                              const SizedBox(height: DT.gapSm),
                              TextFormField(
                                  controller: _password,
                                  decoration: const InputDecoration(
                                      labelText: 'Password'),
                                  obscureText: true,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Required';
                                    if (v.length < 8) return 'Min 8 chars';
                                    return null;
                                  }),
                              const SizedBox(height: DT.gapSm),
                              TextFormField(
                                  controller: _phone,
                                  decoration: const InputDecoration(
                                      labelText: 'Phone (optional)'),
                                  keyboardType: TextInputType.phone),
                              const SizedBox(height: DT.gapSm),
                            ],
                            // Step 1: role-specific
                            if (!isMulti || _step == 1) ...[
                              if (_role == SignupRole.merchant) ...[
                                TextFormField(
                                    controller: _bizName,
                                    decoration: const InputDecoration(
                                        labelText: 'Business name'),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Required'
                                            : null),
                                const SizedBox(height: DT.gapSm),
                                TextFormField(
                                    controller: _bizReg,
                                    decoration: const InputDecoration(
                                        labelText:
                                            'Business registration (optional)')),
                                const SizedBox(height: DT.gapSm),
                                TextFormField(
                                    controller: _bizGstin,
                                    decoration: const InputDecoration(
                                        labelText: 'GSTIN (optional)')),
                                const SizedBox(height: DT.gapSm),
                                TextFormField(
                                    controller: _bizAddress,
                                    decoration: const InputDecoration(
                                        labelText: 'Address (optional)')),
                                const SizedBox(height: DT.gapSm),
                              ],
                              if (_role == SignupRole.banker) ...[
                                TextFormField(
                                    controller: _employeeId,
                                    decoration: const InputDecoration(
                                        labelText: 'Employee ID'),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Required'
                                            : null),
                                const SizedBox(height: DT.gapSm),
                                TextFormField(
                                    controller: _bankName,
                                    decoration: const InputDecoration(
                                        labelText: 'Bank name'),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Required'
                                            : null),
                                const SizedBox(height: DT.gapSm),
                                TextFormField(
                                    controller: _bankBranch,
                                    decoration: const InputDecoration(
                                        labelText: 'Branch (optional)')),
                                const SizedBox(height: DT.gapSm),
                              ],
                              if (_role == SignupRole.customer ||
                                  _role == SignupRole.admin) ...[
                                // nothing else for now; extend if needed
                                const SizedBox.shrink(),
                              ],
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: DT.gapSm),
                              Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                            ],
                            const SizedBox(height: DT.gap),
                            Row(
                              children: [
                                if (isMulti && _step > 0)
                                  OutlinedButton(
                                      onPressed: () =>
                                          setState(() => _step = _step - 1),
                                      child: const Text('Back')),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: _loading
                                      ? null
                                      : () {
                                          if (isMulti) {
                                            if (_step == 0) {
                                              if (!_formKey.currentState!
                                                  .validate()) return;
                                              setState(() => _step = 1);
                                              return;
                                            } else {
                                              _submit();
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
                                              strokeWidth: 2))
                                      : Text(isMulti
                                          ? (_step == 0
                                              ? 'Next'
                                              : 'Create account')
                                          : 'Create account'),
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
          ),
        ),
      ),
    );
  }
}

class StepperHeader extends StatelessWidget {
  final int step;
  final int total;
  const StepperHeader({super.key, required this.step, required this.total});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(total, (i) {
            final active = i <= step;
            return Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? DT.accent : DT.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: DT.gapSm),
      ],
    );
  }
}
