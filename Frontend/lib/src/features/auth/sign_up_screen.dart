import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_config.dart';
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
  final Dio _authApi = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  SignupRole _role = SignupRole.customer;
  int _step = 0;
  bool _loading = false;
  bool _loadingBanks = false;
  String? _error;
  List<_BankOption> _banks = [];
  String? _selectedBankId;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  final _bizName = TextEditingController();
  final _bizGstin = TextEditingController();
  final _bizAddress = TextEditingController();

  final _employeeId = TextEditingController();
  final _bankBranch = TextEditingController();
  final _bankPincode = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

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
    _bankPincode.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    setState(() => _loadingBanks = true);
    try {
      final res = await _authApi.get('/banks');
      final raw = res.data;
      List list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['data'] is List) {
        list = raw['data'] as List;
      } else {
        list = const [];
      }

      final parsed = list
          .whereType<Map>()
          .map((e) => _BankOption.fromMap(e.cast<String, dynamic>()))
          .where((e) => e.id.isNotEmpty)
          .toList();

      setState(() {
        _banks = parsed;
        if (_banks.isNotEmpty && _selectedBankId == null) {
          _selectedBankId = _banks.first.id;
        }
      });
    } catch (_) {
      setState(() {
        _banks = [];
      });
    } finally {
      if (mounted) setState(() => _loadingBanks = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'role': _role.roleString,
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
    };

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
        'bankId': _selectedBankId,
        'branch': _bankBranch.text.trim(),
        'pincode': _bankPincode.text.trim(),
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
              'Account created. Please verify your email before logging in.'),
        ),
      );
      context.go('/login');
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
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
                              Wrap(
                                spacing: DT.gapSm,
                                children: SignupRole.values.map((role) {
                                  return ChoiceChip(
                                    label: Text(role.label),
                                    selected: _role == role,
                                    onSelected: (_) {
                                      setState(() {
                                        _role = role;
                                        _step = 0;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: DT.gap),
                              if (!isMulti || _step == 0) ...[
                                _field(_name, 'Full name'),
                                _emailField(),
                                _passwordField(),
                                _field(_phone, 'Phone', required: true),
                              ],
                              if (isMulti && _step == 1) ...[
                                if (_role == SignupRole.merchant) ...[
                                  _field(_bizName, 'Business name'),
                                  _field(_bizGstin, 'GST Number',
                                      required: false),
                                  _field(_bizAddress, 'Address',
                                      required: false),
                                ],
                                if (_role == SignupRole.banker) ...[
                                  if (_loadingBanks)
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(bottom: DT.gapSm),
                                      child: LinearProgressIndicator(),
                                    ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: DT.gapSm),
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedBankId,
                                      decoration: const InputDecoration(
                                          labelText: 'Bank'),
                                      items: _banks
                                          .map(
                                            (bank) => DropdownMenuItem<String>(
                                              value: bank.id,
                                              child: Text(bank.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _selectedBankId = v),
                                      validator: (v) {
                                        if (_role != SignupRole.banker) {
                                          return null;
                                        }
                                        if (v == null || v.isEmpty) {
                                          return 'Bank is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _field(_employeeId, 'Employee ID',
                                      required: false),
                                  _field(_bankBranch, 'Branch'),
                                  _field(_bankPincode, 'Pincode'),
                                  if (!_loadingBanks && _banks.isEmpty)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: _loadBanks,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry bank list'),
                                      ),
                                    ),
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

  Widget _emailField() => Padding(
        padding: const EdgeInsets.only(bottom: DT.gapSm),
        child: TextFormField(
          controller: _email,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())
                ? null
                : 'Enter valid email';
          },
        ),
      );

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

class _BankOption {
  final String id;
  final String name;

  const _BankOption({required this.id, required this.name});

  factory _BankOption.fromMap(Map<String, dynamic> map) {
    return _BankOption(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
    );
  }
}
