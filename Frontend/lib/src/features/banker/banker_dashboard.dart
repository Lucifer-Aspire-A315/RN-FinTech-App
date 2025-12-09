// lib/src/features/banker/banker_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_notifier.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/activity_list.dart';
import '../../core/design_tokens.dart';

class BankerDashboard extends ConsumerWidget {
  const BankerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final name = user?.name ?? 'Banker';
    final isWide = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      appBar: AppBar(
          title: Text('Banker Workspace',
              style: Theme.of(context).textTheme.titleLarge),
          actions: [
            IconButton(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded))
          ]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              DashboardHeader(
                  title: 'Welcome, $name',
                  subtitle: 'Manage approvals & portfolios',
                  avatarText: name.isNotEmpty ? name[0] : 'B'),
              const SizedBox(height: 16),
              Expanded(
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: const [
                                Row(children: [
                                  Expanded(
                                      child: StatsCard(
                                          title: 'Pending Approvals',
                                          value: '12',
                                          subtitle: 'Action required')),
                                  SizedBox(width: 12),
                                  Expanded(
                                      child: StatsCard(
                                          title: 'Active Loans',
                                          value: '1,240',
                                          subtitle: 'Total')),
                                ]),
                                SizedBox(height: 12),
                                Expanded(child: ActivityList(role: 'banker')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(children: [
                              Card(
                                elevation: DT.elevationLow,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(DT.radius)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Risk Alerts',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 8),
                                        const Text(
                                            '3 accounts flagged for manual review'),
                                        const SizedBox(height: 12),
                                        OutlinedButton(
                                            onPressed: () {},
                                            child: const Text('View alerts')),
                                      ]),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Card(
                                elevation: DT.elevationLow,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(DT.radius)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Quick Actions',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 8),
                                        Wrap(spacing: 8, children: [
                                          ActionChip(
                                              label: const Text('Approve'),
                                              onPressed: () {}),
                                          ActionChip(
                                              label: const Text('Reject'),
                                              onPressed: () {}),
                                          ActionChip(
                                              label: const Text('Assign'),
                                              onPressed: () {}),
                                        ]),
                                      ]),
                                ),
                              ),
                            ]),
                          ),
                        ],
                      )
                    : ListView(
                        children: const [
                          Row(children: [
                            Expanded(
                                child: StatsCard(
                                    title: 'Pending Approvals',
                                    value: '12',
                                    subtitle: 'Action required')),
                            SizedBox(width: 12),
                            Expanded(
                                child: StatsCard(
                                    title: 'Active Loans',
                                    value: '1,240',
                                    subtitle: 'Total')),
                          ]),
                          SizedBox(height: 12),
                          Card(
                              child: SizedBox(
                            height: 400,
                            child: ActivityList(
                                role: 'banker',
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics()),
                          )),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
