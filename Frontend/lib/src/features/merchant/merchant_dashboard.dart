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

class MerchantDashboard extends ConsumerWidget {
  const MerchantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final name = user?.name ?? 'Merchant';
    final dashboardAsync = ref.watch(dashboardProvider);
    final loanSnapshotAsync = ref.watch(dashboardLoanSnapshotProvider);
    final data = dashboardAsync.valueOrNull?.data ?? const <String, dynamic>{};
    final loans = loanSnapshotAsync.valueOrNull?.items ?? const [];

    final summary = _asMap(data['summary']);
    final totalApps = _toInt(summary['totalApps']);
    final approvalRate = _toInt(summary['approvalRate']);
    final disbursedAmount = summary['disbursedAmount']?.toString() ?? '0';
    final unread = _asList(data['notifications']).where((e) {
      if (e is Map) return e['status'] == 'unread';
      return false;
    }).length;

    final offerPendingDecision = loans.where((l) {
      if (l.bankerId != null) return false;
      final requests = l.metadata['assignmentRequests'];
      if (requests is! List) return false;
      return requests.any((r) => r is Map && r['status']?.toString() == 'PENDING');
    }).length;
    final offerAccepted = loans.where((l) => l.bankerId != null && l.status == 'UNDER_REVIEW').length;
    final offerClosed = loans.where((l) {
      final requests = l.metadata['assignmentRequests'];
      if (requests is! List) return false;
      return requests.any((r) =>
          r is Map &&
          (r['status']?.toString() == 'REJECTED' || r['status']?.toString() == 'AUTO_CANCELLED'));
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text('Merchant Dashboard', style: Theme.of(context).textTheme.titleLarge),
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
                    subtitle: 'Track applications, approvals, and payouts',
                    avatarText: name.isNotEmpty ? name[0].toUpperCase() : 'M',
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
                      _QuickActionData('Apply Loan', Icons.request_quote_rounded, route: '/loans/apply'),
                      _QuickActionData('Track Status', Icons.track_changes_rounded, route: '/loans'),
                      _QuickActionData('KYC Center', Icons.file_upload_rounded, route: '/kyc'),
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
                          title: 'Applications',
                          value: totalApps.toString(),
                          subtitle: 'Submitted',
                          icon: Icons.request_quote_rounded,
                          accentColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Approval Rate',
                          value: '$approvalRate%',
                          subtitle: 'Current success rate',
                          icon: Icons.trending_up_rounded,
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
                          title: 'Disbursed',
                          value: disbursedAmount,
                          subtitle: 'Total approved amount',
                          icon: Icons.account_balance_wallet_rounded,
                          accentColor: const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Unread Alerts',
                          value: unread.toString(),
                          subtitle: 'Notifications pending',
                          icon: Icons.notifications_rounded,
                          accentColor: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StaggerReveal(
                  delayMs: 250,
                  child: _Panel(
                    title: 'Assignment Offers',
                    child: _AssignmentColumns(
                      pendingDecision: offerPendingDecision,
                      accepted: offerAccepted,
                      closed: offerClosed,
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
                        role: 'merchant',
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
    if (index == 1) {
      context.push('/loans');
      return;
    }
    if (index == 3) {
      context.push('/profile');
      return;
    }
    final labels = ['Home', 'Loans', 'Payouts', 'Profile'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${labels[index]} screen will be connected next.')),
    );
  }
}

class _AssignmentColumns extends StatelessWidget {
  final int pendingDecision;
  final int accepted;
  final int closed;

  const _AssignmentColumns({
    required this.pendingDecision,
    required this.accepted,
    required this.closed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniCol(label: 'Pending', value: pendingDecision.toString(), color: const Color(0xFFD97706))),
        const SizedBox(width: 8),
        Expanded(child: _MiniCol(label: 'Accepted', value: accepted.toString(), color: const Color(0xFF16A34A))),
        const SizedBox(width: 8),
        Expanded(child: _MiniCol(label: 'Closed', value: closed.toString(), color: const Color(0xFF6B7280))),
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
        NavigationDestination(icon: Icon(Icons.request_quote_rounded), label: 'Loans'),
        NavigationDestination(icon: Icon(Icons.payments_rounded), label: 'Payouts'),
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
