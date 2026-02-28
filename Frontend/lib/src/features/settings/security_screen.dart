import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_repository.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loadingPassword = false;
  bool _loadingSessions = false;
  String? _message;
  String? _error;
  List<UserSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    try {
      final sessions = await ref.read(authRepositoryProvider).listSessions();
      setState(() => _sessions = sessions);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loadingPassword = true;
      _message = null;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).changePassword(
            oldPassword: _oldPassword.text,
            newPassword: _newPassword.text,
          );
      setState(() => _message = 'Password changed successfully.');
      _oldPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingPassword = false);
    }
  }

  Future<void> _revokeSession(String id) async {
    try {
      await ref.read(authRepositoryProvider).revokeSession(id);
      await _loadSessions();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Change Password',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _oldPassword,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current password'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Current password required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPassword,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New password'),
                      validator: (v) =>
                          (v == null || v.length < 8) ? 'Min 8 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPassword,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm new password'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirm password';
                        if (v != _newPassword.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_message != null)
                      Text(_message!, style: const TextStyle(color: Colors.green)),
                    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadingPassword ? null : _changePassword,
                      child: _loadingPassword
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Active Sessions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: _loadingSessions ? null : _loadSessions,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  if (_loadingSessions)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (!_loadingSessions && _sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No active sessions found.'),
                    ),
                  ..._sessions.map(
                    (session) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(session.deviceInfo ?? 'Unknown device'),
                      subtitle: Text(
                        [
                          if (session.ipAddress != null) 'IP: ${session.ipAddress}',
                          if (session.lastActive != null)
                            'Last active: ${session.lastActive}',
                        ].join('  |  '),
                      ),
                      trailing: TextButton(
                        onPressed: () => _revokeSession(session.id),
                        child: const Text('Revoke'),
                      ),
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


