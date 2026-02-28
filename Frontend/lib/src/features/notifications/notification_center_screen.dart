import 'package:fintech_frontend/src/core/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  bool _loading = false;
  bool _actionLoading = false;
  String? _error;
  String? _statusFilter;
  int _page = 1;
  static const int _limit = 20;
  NotificationListResult _result = const NotificationListResult(
    items: [],
    page: 1,
    limit: _limit,
    total: 0,
    totalPages: 1,
  );

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(notificationRepositoryProvider).list(
            status: _statusFilter,
            page: _page,
            limit: _limit,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _page = result.page;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id) async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(notificationRepositoryProvider).markRead(id);
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

  Future<void> _markAllRead() async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
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
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: (_loading || _actionLoading || _result.items.isEmpty) ? null : _markAllRead,
            child: const Text('Mark all read'),
          ),
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('All', null),
                _chip('Unread', 'unread'),
                _chip('Read', 'read'),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            if (_actionLoading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (_error != null)
              Card(
                child: ListTile(
                  title: const Text('Failed to load notifications'),
                  subtitle: Text(_error!),
                ),
              ),
            if (_result.items.isEmpty && !_loading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No notifications found.'),
                ),
              ),
            ..._result.items.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      n.status == 'unread' ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    ),
                    title: Text(n.message),
                    subtitle: Text(
                      '${n.type} | ${n.createdAt?.toLocal().toString().split('.').first ?? '-'}',
                    ),
                    trailing: n.status == 'unread'
                        ? TextButton(
                            onPressed: _actionLoading ? null : () => _markRead(n.id),
                            child: const Text('Mark read'),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            if (_result.total > 0)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Showing ${_result.items.length} of ${_result.total}',
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
      ),
    );
  }

  Widget _chip(String label, String? status) {
    return ChoiceChip(
      label: Text(label),
      selected: _statusFilter == status,
      onSelected: (_) {
        setState(() {
          _statusFilter = status;
          _page = 1;
        });
        _fetch();
      },
    );
  }
}
