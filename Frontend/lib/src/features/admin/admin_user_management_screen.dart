import 'package:fintech_frontend/src/core/admin_user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen> {
  bool _loading = false;
  bool _actionLoading = false;
  String? _error;
  String? _roleFilter;
  String? _statusFilter;
  String _search = '';
  int _page = 1;
  static const int _limit = 20;
  final _searchCtrl = TextEditingController();

  AdminUserListResult _result =
      const AdminUserListResult(users: [], page: 1, limit: _limit, total: 0, totalPages: 1);

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ref.read(adminUserRepositoryProvider).listUsers(
            role: _roleFilter,
            status: _statusFilter,
            search: _search,
            page: _page,
            limit: _limit,
          );
      if (!mounted) return;
      setState(() {
        _result = data;
        _page = data.page;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(AdminUserItem user, String status) async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(adminUserRepositoryProvider).updateUserStatus(
            userId: user.id,
            status: status,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated ${user.name} to $status')),
      );
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Users'),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          if (_actionLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (_error != null)
            Card(
              child: ListTile(
                title: const Text('Failed to load users'),
                subtitle: Text(_error!),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search name/email/phone',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onSubmitted: (v) {
                    setState(() {
                      _search = v.trim();
                      _page = 1;
                    });
                    _fetch();
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _search = _searchCtrl.text.trim();
                    _page = 1;
                  });
                  _fetch();
                },
                child: const Text('Go'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip('All Roles', _roleFilter == null, () {
                setState(() {
                  _roleFilter = null;
                  _page = 1;
                });
                _fetch();
              }),
              _filterChip('Customer', _roleFilter == 'CUSTOMER', () {
                setState(() {
                  _roleFilter = 'CUSTOMER';
                  _page = 1;
                });
                _fetch();
              }),
              _filterChip('Merchant', _roleFilter == 'MERCHANT', () {
                setState(() {
                  _roleFilter = 'MERCHANT';
                  _page = 1;
                });
                _fetch();
              }),
              _filterChip('Banker', _roleFilter == 'BANKER', () {
                setState(() {
                  _roleFilter = 'BANKER';
                  _page = 1;
                });
                _fetch();
              }),
              _filterChip('Admin', _roleFilter == 'ADMIN', () {
                setState(() {
                  _roleFilter = 'ADMIN';
                  _page = 1;
                });
                _fetch();
              }),
              _filterChip('Active', _statusFilter == 'ACTIVE', () {
                setState(() {
                  _statusFilter = 'ACTIVE';
                  _page = 1;
                });
                _fetch();
              }),
              _filterChip('Suspended', _statusFilter == 'SUSPENDED', () {
                setState(() {
                  _statusFilter = 'SUSPENDED';
                  _page = 1;
                });
                _fetch();
              }),
              _filterChip('Pending', _statusFilter == 'PENDING', () {
                setState(() {
                  _statusFilter = 'PENDING';
                  _page = 1;
                });
                _fetch();
              }),
              _filterChip('Rejected', _statusFilter == 'REJECTED', () {
                setState(() {
                  _statusFilter = 'REJECTED';
                  _page = 1;
                });
                _fetch();
              }),
              _filterChip('All Status', _statusFilter == null, () {
                setState(() {
                  _statusFilter = null;
                  _page = 1;
                });
                _fetch();
              }),
            ],
          ),
          const SizedBox(height: 10),
          if (_result.users.isEmpty && !_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No users found.'),
              ),
            ),
          ..._result.users.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('${u.email} | ${u.phone}'),
                      Text('Role: ${u.role} | Status: ${u.status} | Verified: ${u.isEmailVerified ? 'Yes' : 'No'}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statusBtn(u, 'ACTIVE'),
                          _statusBtn(u, 'SUSPENDED'),
                          _statusBtn(u, 'PENDING'),
                          _statusBtn(u, 'REJECTED'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_result.total > 0)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing ${_result.users.length} of ${_result.total}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  onPressed: _page > 1 && !_loading
                      ? () {
                          setState(() => _page--);
                          _fetch();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('${_result.page}/${_result.totalPages}'),
                IconButton(
                  onPressed: _page < _result.totalPages && !_loading
                      ? () {
                          setState(() => _page++);
                          _fetch();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }

  Widget _statusBtn(AdminUserItem user, String target) {
    final selected = user.status == target;
    return OutlinedButton(
      onPressed: (_actionLoading || selected) ? null : () => _updateStatus(user, target),
      child: Text(target),
    );
  }
}
