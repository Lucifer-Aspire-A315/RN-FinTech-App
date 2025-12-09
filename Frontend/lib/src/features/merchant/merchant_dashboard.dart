// lib/src/features/merchant/merchant_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_notifier.dart';
import '../../core/design_tokens.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/activity_list.dart';

class MerchantDashboard extends ConsumerWidget {
  const MerchantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final name = user?.name ?? 'Merchant';

    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1000;

    return Scaffold(
      appBar: AppBar(
        title: Text('Merchant Dashboard',
            style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
              onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded))
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              DashboardHeader(
                title: 'Good morning, $name',
                subtitle: 'Your store performance at a glance',
                avatarText: name.isNotEmpty ? name[0].toUpperCase() : 'M',
                trailing: FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Create Order'),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: const [
                                Row(
                                  children: [
                                    Expanded(
                                        child: StatsCard(
                                            title: 'Today Sales',
                                            value: '₹ 42,500',
                                            subtitle: '+12%')),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: StatsCard(
                                            title: 'Pending',
                                            value: '18 orders',
                                            subtitle: 'Awaiting action')),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Expanded(child: ActivityList(role: 'merchant')),
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
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(DT.radius)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Payouts',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 8),
                                        Text('Next payout: ₹ 1,24,000',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge),
                                        const SizedBox(height: 12),
                                        OutlinedButton(
                                            onPressed: () {},
                                            child: const Text('View payouts')),
                                      ],
                                    ),
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
                                        Text('Quick Links',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 8),
                                        Wrap(spacing: 8, children: [
                                          ActionChip(
                                              label: const Text('Catalog'),
                                              onPressed: () {}),
                                          ActionChip(
                                              label: const Text('Invoices'),
                                              onPressed: () {}),
                                          ActionChip(
                                              label: const Text('Reports'),
                                              onPressed: () {}),
                                        ]),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      )
                    : ListView(
                        children: [
                          const Row(
                            children: [
                              Expanded(
                                  child: StatsCard(
                                      title: 'Today Sales',
                                      value: '₹ 42,500',
                                      subtitle: '+12%')),
                              SizedBox(width: 12),
                              Expanded(
                                  child: StatsCard(
                                      title: 'Pending',
                                      value: '18 orders',
                                      subtitle: 'Awaiting action')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(DT.radius)),
                            child: const Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ActivityList(
                                  role: 'merchant',
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics()),
                            ),
                          ),
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
