import 'package:fintech_frontend/models/user_role.dart';
import 'package:fintech_frontend/src/core/auth_notifier.dart';
import 'package:fintech_frontend/src/core/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _pincode = TextEditingController();
  final _businessName = TextEditingController();
  final _gstNumber = TextEditingController();
  final _branch = TextEditingController();
  final _employeeId = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  String? _error;
  Map<String, dynamic> _user = const <String, dynamic>{};
  Map<String, dynamic> _profile = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _pincode.dispose();
    _businessName.dispose();
    _gstNumber.dispose();
    _branch.dispose();
    _employeeId.dispose();
    super.dispose();
  }

  void _bindControllers() {
    _name.text = _user['name']?.toString() ?? '';
    _address.text = _profile['address']?.toString() ?? '';
    _pincode.text = _profile['pincode']?.toString() ?? '';
    _businessName.text = _profile['businessName']?.toString() ?? '';
    _gstNumber.text = _profile['gstNumber']?.toString() ?? '';
    _branch.text = _profile['branch']?.toString() ?? '';
    _employeeId.text = _profile['employeeId']?.toString() ?? '';
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = await ref.read(profileRepositoryProvider).getProfile();
      if (!mounted) return;
      setState(() {
        _user = payload.user;
        _profile = payload.profile;
      });
      _bindControllers();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final role = _role;
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
    };
    if (role == UserRole.customer) {
      payload['address'] = _address.text.trim();
      payload['pincode'] = _pincode.text.trim();
    } else if (role == UserRole.merchant) {
      payload['businessName'] = _businessName.text.trim();
      payload['gstNumber'] = _gstNumber.text.trim();
      payload['address'] = _address.text.trim();
      payload['pincode'] = _pincode.text.trim();
    } else if (role == UserRole.banker) {
      payload['branch'] = _branch.text.trim();
      payload['pincode'] = _pincode.text.trim();
      payload['employeeId'] = _employeeId.text.trim();
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref.read(profileRepositoryProvider).updateProfile(payload);
      if (!mounted) return;
      setState(() {
        _user = updated.user;
        _profile = updated.profile;
      });
      _bindControllers();
      await ref.read(authNotifierProvider.notifier).refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete account?'),
            content: const Text(
              'This will deactivate your account. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    setState(() => _deleting = true);
    try {
      await ref.read(profileRepositoryProvider).deleteAccount();
      if (!mounted) return;
      await ref.read(authNotifierProvider.notifier).logout();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  UserRole get _role {
    final raw = _user['role']?.toString();
    return userRoleFromString(raw);
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    final email = _user['email']?.toString() ?? '';
    final phone = _user['phone']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            final rolePath = role.name.toLowerCase();
            context.go('/$rolePath/dashboard');
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          if (_saving || _deleting)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (_error != null)
            Card(
              child: ListTile(
                title: const Text('Profile error'),
                subtitle: Text(_error!),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Role: ${_user['role'] ?? '-'}'),
                    const SizedBox(height: 8),
                    Text('Email: $email'),
                    const SizedBox(height: 4),
                    Text('Phone: $phone'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                    ),
                    if (role == UserRole.customer || role == UserRole.merchant) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                    ],
                    if (role == UserRole.customer || role == UserRole.merchant || role == UserRole.banker) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _pincode,
                        decoration: const InputDecoration(labelText: 'Pincode'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    if (role == UserRole.merchant) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _businessName,
                        decoration: const InputDecoration(labelText: 'Business Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Business name required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _gstNumber,
                        decoration: const InputDecoration(labelText: 'GST Number'),
                      ),
                    ],
                    if (role == UserRole.banker) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _branch,
                        decoration: const InputDecoration(labelText: 'Branch'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _employeeId,
                        decoration: const InputDecoration(labelText: 'Employee ID'),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_saving || _deleting || _loading) ? null : _save,
                        child: const Text('Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFFFF7F7),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danger Zone',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Delete account is blocked if there are active/associated loans.',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: (_deleting || _saving || _loading) ? null : _deleteAccount,
                      child: const Text('Delete Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
