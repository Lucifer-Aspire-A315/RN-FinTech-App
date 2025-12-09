// lib/src/features/customer/customer_dashboard_responsive.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_notifier.dart';
import '../../core/design_tokens.dart';

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _page = 0;
  Timer? _autoPlay;

  @override
  void initState() {
    super.initState();
    _autoPlay = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) return;
      final next = (_page + 1) % 3;
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final user = auth.user;
    final name = (user?.name ?? 'User').split(' ').first;
    final avatarLetter = (name.isNotEmpty ? name[0].toUpperCase() : 'U');

    return Scaffold(
      backgroundColor: DT.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded),
        label: const Text('Apply'),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          if (isWide) {
            return _buildWideLayout(context, name, avatarLetter);
          } else {
            return _buildMobileSliverLayout(context, name, avatarLetter);
          }
        }),
      ),
    );
  }

  // ----------------- Mobile (single column) using Slivers -----------------
  Widget _buildMobileSliverLayout(
      BuildContext context, String name, String avatarLetter) {
    return CustomScrollView(
      slivers: [
        // Hero area as SliverToBoxAdapter
        SliverToBoxAdapter(child: _heroSection(context, name, avatarLetter)),

        SliverToBoxAdapter(child: const SizedBox(height: 12)),

        // Stats carousel
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 3,
              onPageChanged: (p) => setState(() => _page = p),
              itemBuilder: (context, idx) => _statCard(context, idx),
            ),
          ),
        ),

        // Dots
        SliverToBoxAdapter(child: _dotsIndicator()),

        // Quick actions (horizontal scroller)
        SliverToBoxAdapter(child: _quickActions()),

        // Promotions (horizontal)
        SliverToBoxAdapter(child: _promoStrip()),

        // Recent activity header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                Text('Recent activity',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('See all')),
              ],
            ),
          ),
        ),

        // Activity list as a SliverList (no nested ListView!)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, idx) {
              // Replace with API-driven items; this is sample content
              final samples = [
                {
                  'title': 'Payment received',
                  'subtitle': '₹2,400 — 2 hours ago'
                },
                {'title': 'EMI due', 'subtitle': '₹3,200 — 3 days left'},
                {'title': 'New offer', 'subtitle': '0% interest for 2 months'},
                {'title': 'Profile verified', 'subtitle': 'KYC complete'},
                {'title': 'Invoice paid', 'subtitle': '₹18,700 — Yesterday'},
              ];
              final item = samples[idx % samples.length];
              return _activityTile(context, item['title']!, item['subtitle']!);
            }, childCount: 6),
          ),
        ),

        SliverToBoxAdapter(child: const SizedBox(height: 90)),
      ],
    );
  }

  // ----------------- Wide (desktop/tablet) layout -----------------
  Widget _buildWideLayout(
      BuildContext context, String name, String avatarLetter) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _heroSection(context, name, avatarLetter)),
        SliverToBoxAdapter(child: const SizedBox(height: 16)),
        // Use a SliverToBoxAdapter containing Row with two columns (left main, right sidebar)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - main content
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: _statCard(context, 0)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard(context, 1)),
                      ]),
                      const SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DT.radius)),
                        elevation: DT.elevationLow,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Recent activity',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium)),
                              const SizedBox(height: 12),
                              // Activity list as Column inside fixed card
                              ...List.generate(5, (i) {
                                final samples = [
                                  {
                                    'title': 'Payment received',
                                    'subtitle': '₹2,400 — 2 hours ago'
                                  },
                                  {
                                    'title': 'EMI due',
                                    'subtitle': '₹3,200 — 3 days left'
                                  },
                                  {
                                    'title': 'New offer',
                                    'subtitle': '0% interest for 2 months'
                                  },
                                  {
                                    'title': 'Profile verified',
                                    'subtitle': 'KYC complete'
                                  },
                                  {
                                    'title': 'Invoice paid',
                                    'subtitle': '₹18,700 — Yesterday'
                                  },
                                ];
                                final item = samples[i % samples.length];
                                return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _activityTile(context,
                                        item['title']!, item['subtitle']!));
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right column - sidebar
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DT.radius)),
                        elevation: DT.elevationLow,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Credit Score',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                  value: 0.76, minHeight: 10),
                              const SizedBox(height: 10),
                              Text(
                                  'Good standing — keep payments on time to improve.',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('Improve score')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DT.radius)),
                        elevation: DT.elevationLow,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quick Actions',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                Wrap(spacing: 8, children: [
                                  ActionChip(
                                      label: const Text('Pay due'),
                                      onPressed: () {}),
                                  ActionChip(
                                      label: const Text('Repayment plan'),
                                      onPressed: () {}),
                                  ActionChip(
                                      label: const Text('Statements'),
                                      onPressed: () {}),
                                  ActionChip(
                                      label: const Text('Support'),
                                      onPressed: () {}),
                                ]),
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 60)),
      ],
    );
  }

  // ----------------- Reusable small widgets -----------------
  Widget _heroSection(BuildContext context, String name, String avatarLetter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: DT.accent.withOpacity(0.12)),
            child: Center(
                child: Text(avatarLetter,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome back,',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 2),
              Text(name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Here\'s your financial snapshot',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600])),
            ]),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Application'),
          )
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, int index) {
    final items = [
      {'title': 'Credit Limit', 'value': '₹150,000', 'subtitle': 'Available'},
      {'title': 'Outstanding', 'value': '₹23,450', 'subtitle': 'Due 5 days'},
      {'title': 'On-time rate', 'value': '92%', 'subtitle': 'Payments on time'},
    ];
    final item = items[index % items.length];

    // Constrain max height so icon + text never overflow their container
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 110,
          maxHeight: 160, // cap height to avoid overflow on small screens
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 8))
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [DT.accent, DT.accent.withOpacity(0.8)])),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['title']!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['value']!,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['subtitle']!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _dotsIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                    color: active ? DT.accent : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12)),
              );
            })),
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      {'icon': Icons.payments_rounded, 'label': 'Pay'},
      {'icon': Icons.schedule, 'label': 'EMI'},
      {'icon': Icons.history, 'label': 'Statements'},
      {'icon': Icons.support_agent, 'label': 'Support'},
    ];
    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final a = actions[i];
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 6))
                  ]),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                CircleAvatar(
                    radius: 20,
                    backgroundColor: DT.primary.withOpacity(0.06),
                    child: Icon(a['icon'] as IconData,
                        size: 18, color: DT.primary)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(a['label'] as String,
                        style: Theme.of(context).textTheme.bodySmall)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _promoStrip() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, i) {
          final palettes = [
            [DT.accent, DT.accent.withOpacity(0.9)],
            [DT.primary.withOpacity(0.95), DT.primary.withOpacity(0.7)],
            [Colors.deepPurple, Colors.purpleAccent],
            [Colors.orange, Colors.deepOrangeAccent],
          ];
          final colors = palettes[i % palettes.length];
          return Container(
            width: 260,
            margin: const EdgeInsets.only(right: 12),
            // Constrain each promo card so internal layout can't expand past the strip height
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 96, maxHeight: 120),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: colors.first.withOpacity(0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Use mainAxisSize.min and Flexible to avoid Spacer forcing overflow
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        i == 1 ? 'Exclusive' : 'Tailored',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          i == 1
                              ? '0% interest for 2 months'
                              : 'Get higher limit',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: SizedBox(
                          height: 34,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {},
                            child: const Text('Learn',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _activityTile(BuildContext context, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ]),
      child: ListTile(
        onTap: () {},
        leading: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
              color: DT.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.receipt_long_outlined, color: DT.accent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
