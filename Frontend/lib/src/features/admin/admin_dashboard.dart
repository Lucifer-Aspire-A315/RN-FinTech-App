import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_notifier.dart';
import '../../core/dashboard_repository.dart';
import '../../widgets/activity_list.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/stagger_reveal.dart';
import '../../widgets/stats_card.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final name = user?.name ?? 'Admin';
    final dashboardAsync = ref.watch(dashboardProvider);
    final data = dashboardAsync.valueOrNull?.data ?? const <String, dynamic>{};
    final users = _asMap(data['users']);
    final loans = _asMap(data['loans']);

    final totalUsers = _sumUserCounts(users);
    final totalLoans = _toInt(loans['totalCount']);
    final totalVolume = loans['totalVolume']?.toString() ?? '0';
    final pendingLoans = _extractStatusCount(_asMap(loans['byStatus'])['SUBMITTED']);
    final recentAudits = (_asList(data['recentActivity'])).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text('Admin Dashboard', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_rounded),
          ),
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
            colors: [Color(0xFFEAF3EC), Color(0xFFF7FAFD)],
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
                    title: 'Hello, $name',
                    subtitle: 'System overview and operational controls',
                    avatarText: name.isNotEmpty ? name[0].toUpperCase() : 'A',
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
                    title: 'Admin Actions',
                    actions: const [
                      _QuickActionData('Manage Users', Icons.groups_rounded, route: '/admin/users'),
                      _QuickActionData(
                        'Loan Types',
                        Icons.tune_rounded,
                        route: '/admin/loan-types',
                      ),
                      _QuickActionData(
                        'Banks',
                        Icons.account_balance_rounded,
                        route: '/admin/banks',
                      ),
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
                          title: 'Users',
                          value: totalUsers.toString(),
                          subtitle: 'All roles',
                          icon: Icons.groups_rounded,
                          accentColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Loans',
                          value: totalLoans.toString(),
                          subtitle: 'Volume: $totalVolume',
                          icon: Icons.account_balance_wallet_rounded,
                          accentColor: const Color(0xFF16A34A),
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
                          title: 'Pending',
                          value: pendingLoans.toString(),
                          subtitle: 'Need banker action',
                          icon: Icons.pending_actions_rounded,
                          accentColor: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Recent Audits',
                          value: recentAudits.toString(),
                          subtitle: 'Latest system events',
                          icon: Icons.history_toggle_off_rounded,
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
                    title: 'Activity Feed',
                    child: const SizedBox(
                      height: 320,
                      child: ActivityList(
                        role: 'admin',
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

  int _sumUserCounts(Map<String, dynamic> users) {
    if (users.isEmpty) return 0;
    var total = 0;
    for (final value in users.values) {
      if (value is Map) {
        total += _toInt(value['count']);
      } else {
        total += _toInt(value);
      }
    }
    return total;
  }

  int _extractStatusCount(dynamic value) {
    if (value is Map) {
      return _toInt(value['count']);
    }
    return _toInt(value);
  }

  void _handleNavTap(BuildContext context, int index) {
    if (index == 0) return;
    if (index == 1) {
      context.push('/admin/users');
      return;
    }
    if (index == 2) {
      context.push('/loans');
      return;
    }
    if (index == 3) {
      context.push('/profile');
      return;
    }
    final labels = ['Home', 'Users', 'Loans', 'Profile'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${labels[index]} screen will be connected next.')),
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
        NavigationDestination(icon: Icon(Icons.groups_rounded), label: 'Users'),
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
