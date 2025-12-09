// lib/src/features/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_notifier.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/activity_list.dart';
import '../../core/design_tokens.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final name = user?.name ?? 'Admin';
    final isWide = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      appBar: AppBar(title: Text('Admin Console', style: Theme.of(context).textTheme.titleLarge), actions: [
        IconButton(onPressed: () => ref.read(authNotifierProvider.notifier).logout(), icon: const Icon(Icons.logout_rounded))
      ]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              DashboardHeader(title: 'Hello, $name', subtitle: 'System overview & controls', avatarText: name.isNotEmpty ? name[0] : 'A'),
              const SizedBox(height: 16),
              Expanded(
                child: isWide
                    ? Row(children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: const [
                              Row(children: [
                                Expanded(child: StatsCard(title: 'Active Users', value: '12,430', subtitle: '+3.2%')),
                                SizedBox(width: 12),
                                Expanded(child: StatsCard(title: 'Transactions', value: '84,302', subtitle: '24h')),
                              ]),
                              SizedBox(height: 12),
                              Expanded(child: ActivityList(role: 'admin')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Card(
                                elevation: DT.elevationLow,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radius)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('System Health', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 8),
                                    const Text('All services running. No incidents.'),
                                    const SizedBox(height: 12),
                                    OutlinedButton(onPressed: () {}, child: const Text('View logs')),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Card(
                                elevation: DT.elevationLow,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radius)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Admin Actions', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 8),
                                    Wrap(spacing: 8, children: [
                                      ActionChip(label: const Text('Manage Users'), onPressed: () {}),
                                      ActionChip(label: const Text('Settings'), onPressed: () {}),
                                    ]),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        )
                      ])
                    : ListView(
                        children: const [
                          Row(children: [
                            Expanded(child: StatsCard(title: 'Active Users', value: '12,430', subtitle: '+3.2%')),
                            SizedBox(width: 12),
                            Expanded(child: StatsCard(title: 'Transactions', value: '84,302', subtitle: '24h')),
                          ]),
                          SizedBox(height: 12),
                          Card(child: SizedBox(height: 420, child: ActivityList(role: 'admin'))),
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
