import 'package:fintech_frontend/models/user_role.dart';
import 'package:fintech_frontend/src/core/auth_notifier.dart';
import 'package:fintech_frontend/src/core/loan_repository.dart';
import 'package:fintech_frontend/src/features/loans/loan_apply_screen.dart';
import 'package:fintech_frontend/src/features/loans/loan_detail_screen.dart';
import 'package:fintech_frontend/src/features/loans/loan_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _BankerQueueFilter { all, requestable, requestedByMe, assignedToMe }

class LoanListScreen extends ConsumerStatefulWidget {
  const LoanListScreen({super.key});

  @override
  ConsumerState<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends ConsumerState<LoanListScreen> {
  bool _loading = false;
  String? _error;
  String? _statusFilter;
  _BankerQueueFilter _bankerQueueFilter = _BankerQueueFilter.all;
  int _page = 1;
  static const int _limit = 20;
  LoanListResult _result =
      const LoanListResult(items: [], page: 1, limit: 20, total: 0, totalPages: 1);

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
      final repo = ref.read(loanRepositoryProvider);
      final result = await repo.listLoans(
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

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authNotifierProvider).user?.role ?? UserRole.unknown;
    final userId = ref.watch(authNotifierProvider).user?.id ?? '';
    final canApply = role == UserRole.merchant || role == UserRole.customer;
    final items = role == UserRole.banker ? _applyBankerQueueFilter(_result.items, userId) : _result.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: canApply
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoanApplyScreen()),
                );
                if (!mounted) return;
                _fetch();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Apply'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (role == UserRole.banker) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _bankerQueueChip('All', _BankerQueueFilter.all),
                  _bankerQueueChip('To Request', _BankerQueueFilter.requestable),
                  _bankerQueueChip('Requested', _BankerQueueFilter.requestedByMe),
                  _bankerQueueChip('Assigned', _BankerQueueFilter.assignedToMe),
                ],
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip('All', null),
                  _filterChip('Submitted', 'SUBMITTED'),
                  _filterChip('Under Review', 'UNDER_REVIEW'),
                  _filterChip('Approved', 'APPROVED'),
                  _filterChip('Rejected', 'REJECTED'),
                  _filterChip('Disbursed', 'DISBURSED'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: const Text('Failed to load loans'),
                  subtitle: Text(_error!),
                  trailing: TextButton(onPressed: _fetch, child: const Text('Retry')),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (items.isEmpty && !_loading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No loans found for selected filter.'),
                ),
              ),
            ...items.map(
              (loan) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LoanDetailScreen(loanId: loan.id),
                        ),
                      );
                      if (!mounted) return;
                      _fetch();
                    },
                    title: Text(loan.loanTypeName ?? 'Loan ${loan.id.substring(0, 6)}'),
                    subtitle: Text(
                      'Rs ${loan.amount.toStringAsFixed(0)} | ${loan.status.replaceAll('_', ' ')}${_queueLabel(role, loan, userId)}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
            ),
            if (_result.total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Showing ${_result.items.length} of ${_result.total} loans',
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String? status) {
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

  Widget _bankerQueueChip(String label, _BankerQueueFilter filter) {
    return ChoiceChip(
      label: Text(label),
      selected: _bankerQueueFilter == filter,
      onSelected: (_) {
        setState(() => _bankerQueueFilter = filter);
      },
    );
  }

  List<LoanSummary> _applyBankerQueueFilter(List<LoanSummary> items, String userId) {
    bool hasMyPendingRequest(LoanSummary loan) {
      final requests = loan.metadata['assignmentRequests'];
      if (requests is! List) return false;
      for (final r in requests) {
        if (r is Map &&
            r['bankerId']?.toString() == userId &&
            r['status']?.toString() == 'PENDING') {
          return true;
        }
      }
      return false;
    }

    switch (_bankerQueueFilter) {
      case _BankerQueueFilter.requestable:
        return items
            .where(
              (l) =>
                  l.bankerId == null &&
                  (l.status == 'SUBMITTED' || l.status == 'UNDER_REVIEW') &&
                  !hasMyPendingRequest(l),
            )
            .toList();
      case _BankerQueueFilter.requestedByMe:
        return items.where((l) => hasMyPendingRequest(l)).toList();
      case _BankerQueueFilter.assignedToMe:
        return items.where((l) => l.bankerId == userId).toList();
      case _BankerQueueFilter.all:
        return items;
    }
  }

  String _queueLabel(UserRole role, LoanSummary loan, String userId) {
    if (role != UserRole.banker) return '';
    if (loan.bankerId == userId) return ' | Assigned';

    final requests = loan.metadata['assignmentRequests'];
    if (requests is List) {
      for (final r in requests) {
        if (r is Map &&
            r['bankerId']?.toString() == userId &&
            r['status']?.toString() == 'PENDING') {
          return ' | Requested';
        }
      }
    }
    if (loan.bankerId == null) return ' | To Request';
    return '';
  }
}
