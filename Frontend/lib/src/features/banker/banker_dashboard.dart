import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_notifier.dart';
import '../../core/dashboard_repository.dart';
import '../../core/loan_repository.dart';
import '../../widgets/activity_list.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/stagger_reveal.dart';
import '../../widgets/stats_card.dart';

class BankerDashboard extends ConsumerWidget {
  const BankerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final name = user?.name ?? 'Banker';
    final userId = user?.id ?? '';
    final dashboardAsync = ref.watch(dashboardProvider);
    final loanSnapshotAsync = ref.watch(dashboardLoanSnapshotProvider);
    final data = dashboardAsync.valueOrNull?.data ?? const <String, dynamic>{};
    final loans = loanSnapshotAsync.valueOrNull?.items ?? const [];

    final queue = _asMap(data['queue']);
    final performance = _asMap(data['performance']);
    final myPending = _toInt(queue['myPending']);
    final unassigned = _toInt(queue['unassigned']);
    final approved = _toInt(performance['APPROVED']);
    final rejected = _toInt(performance['REJECTED']);
    final unread = _asList(data['notifications']).where((e) {
      if (e is Map) return e['status'] == 'unread';
      return false;
    }).length;

    final requestable = loans.where((l) {
      if (l.bankerId != null) return false;
      if (!(l.status == 'SUBMITTED' || l.status == 'UNDER_REVIEW')) return false;
      final requests = l.metadata['assignmentRequests'];
      if (requests is! List) return true;
      return !requests.any((r) =>
          r is Map && r['bankerId']?.toString() == userId && r['status']?.toString() == 'PENDING');
    }).length;

    final requestedByMe = loans.where((l) {
      final requests = l.metadata['assignmentRequests'];
      if (requests is! List) return false;
      return requests.any((r) =>
          r is Map && r['bankerId']?.toString() == userId && r['status']?.toString() == 'PENDING');
    }).length;

    final assignedToMe = loans.where((l) => l.bankerId == userId).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text('Banker Dashboard', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            onPressed: () => context.push('/security'),
            icon: const Icon(Icons.security_outlined),
          ),
          IconButton(
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      bottomNavigationBar: _DashboardBottomNav(
        currentIndex: 0,
        onTap: (index) => _handleNavTap(context, index),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9F4ED), Color(0xFFF8FAFD)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => ref.refresh(dashboardProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              children: [
                StaggerReveal(
                  delayMs: 20,
                  child: DashboardHeader(
                    title: 'Welcome, $name',
                    subtitle: 'Review queues, decisions, and risk alerts',
                    avatarText: name.isNotEmpty ? name[0].toUpperCase() : 'B',
                  ),
                ),
                const SizedBox(height: 14),
                if (dashboardAsync.isLoading)
                  const StaggerReveal(delayMs: 40, child: LinearProgressIndicator(minHeight: 3)),
                if (dashboardAsync.hasError)
                  StaggerReveal(
                    delayMs: 40,
                    child: _ErrorBanner(onRetry: () => ref.refresh(dashboardProvider)),
                  ),
                StaggerReveal(
                  delayMs: 80,
                  child: _QuickActions(
                    title: 'Quick Actions',
                    actions: const [
                      _QuickActionData('Assign', Icons.assignment_ind_rounded, route: '/loans'),
                      _QuickActionData('Approve', Icons.task_alt_rounded, route: '/loans'),
                      _QuickActionData('Review KYC', Icons.verified_user_rounded, route: '/kyc/review'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StaggerReveal(
                  delayMs: 140,
                  child: Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'My Pending',
                          value: myPending.toString(),
                          subtitle: 'Assigned to you',
                          icon: Icons.fact_check_rounded,
                          accentColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Unassigned',
                          value: unassigned.toString(),
                          subtitle: 'Available pool',
                          icon: Icons.inbox_rounded,
                          accentColor: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StaggerReveal(
                  delayMs: 190,
                  child: Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Approved / Rejected',
                          value: '$approved / $rejected',
                          subtitle: 'Decision ratio',
                          icon: Icons.pie_chart_rounded,
                          accentColor: const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Unread Alerts',
                          value: unread.toString(),
                          subtitle: 'Needs attention',
                          icon: Icons.notifications_active_rounded,
                          accentColor: const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StaggerReveal(
                  delayMs: 250,
                  child: _Panel(
                    title: 'Assignment Queue',
                    child: _AssignmentColumns(
                      requestable: requestable,
                      requestedByMe: requestedByMe,
                      assignedToMe: assignedToMe,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StaggerReveal(
                  delayMs: 300,
                  child: _Panel(
                    title: 'Recent Activity',
                    child: const SizedBox(
                      height: 320,
                      child: ActivityList(
                        role: 'banker',
                        lockToAncestorScroll: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return <dynamic>[];
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _handleNavTap(BuildContext context, int index) {
    if (index == 0) return;
    if (index == 2) {
      context.push('/loans');
      return;
    }
    final labels = ['Home', 'Queue', 'Loans', 'Profile'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${labels[index]} screen will be connected next.')),
    );
  }
}

class _AssignmentColumns extends StatelessWidget {
  final int requestable;
  final int requestedByMe;
  final int assignedToMe;

  const _AssignmentColumns({
    required this.requestable,
    required this.requestedByMe,
    required this.assignedToMe,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniCol(label: 'To Request', value: requestable.toString(), color: const Color(0xFFD97706))),
        const SizedBox(width: 8),
        Expanded(child: _MiniCol(label: 'Requested', value: requestedByMe.toString(), color: const Color(0xFF2563EB))),
        const SizedBox(width: 8),
        Expanded(child: _MiniCol(label: 'Assigned', value: assignedToMe.toString(), color: const Color(0xFF16A34A))),
      ],
    );
  }
}

class _MiniCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniCol({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DashboardBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DashboardBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.inbox_rounded), label: 'Queue'),
        NavigationDestination(icon: Icon(Icons.request_quote_rounded), label: 'Loans'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Unable to load latest data.')),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final String title;
  final List<_QuickActionData> actions;

  const _QuickActions({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: actions
            .map(
              (a) => FilledButton.tonalIcon(
                onPressed: () {
                  if (a.route != null && a.route!.isNotEmpty) {
                    context.push(a.route!);
                  }
                },
                icon: Icon(a.icon, size: 18),
                label: Text(a.label),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final String? route;

  const _QuickActionData(this.label, this.icon, {this.route});
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
