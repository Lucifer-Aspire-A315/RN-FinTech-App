import 'dart:async';
import 'package:fintech_frontend/src/core/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _DT {
  static const Color primary = Color(0xFF0F172A);
  static const Color accent = Color(0xFF06B6D4);
  static const Color bg = Color(0xFFF6F9FB);
  static const double radius = 16;
  static const double elevationLow = 6;
  static const double elevationHigh = 18;
  static final Gradient accentGradient = LinearGradient(
      colors: [accent, Color(0xFF00CFEA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
}

final _dummyAuthProvider = Provider((ref) => {'name': 'User', 'initial': 'U'});

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() =>
      _CustomerDashboardState();
}

class _CustomerDashboardState
    extends ConsumerState<CustomerDashboard>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _page = 0;
  Timer? _autoPlay;
  late final AnimationController _fadeController;
  late final PageController _promoPageController =
      PageController(viewportFraction: 0.92, initialPage: 1000);
  Timer? _promoAutoPlay;

  final Set<int> _promoButtonActive = {};

  @override
  void initState() {
    super.initState();

    _autoPlay = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_pageController.hasClients) return;
      final next = (_page + 1) % 3;
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();

    _promoAutoPlay = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_promoPageController.hasClients) return;
      final current = _promoPageController.page?.round() ??
          _promoPageController.initialPage;
      _promoPageController.animateToPage(current + 1,
          duration: const Duration(milliseconds: 550), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _promoAutoPlay?.cancel(); // stop promo autoplay
    _pageController.dispose();
    _promoPageController.dispose(); // dispose promo controller
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final name = auth.user?.name ?? 'User';
    final avatarLetter = (auth.user?.name ?? 'U')[0].toUpperCase();

    return Scaffold(
      backgroundColor: _DT.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        elevation: 14,
        backgroundColor: _DT.accent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Apply'),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity:
              CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: _buildHero(context, name, avatarLetter)),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildStatsCarousel(context)),
              SliverToBoxAdapter(child: _buildCarouselDots()),
              SliverToBoxAdapter(child: const SizedBox(height: 10)),
              SliverToBoxAdapter(child: _buildQuickActions(context)),
              SliverToBoxAdapter(child: const SizedBox(height: 10)),
              SliverToBoxAdapter(child: _buildPromoStrip(context)),
              SliverToBoxAdapter(child: const SizedBox(height: 6)),
              SliverToBoxAdapter(
                  child: _buildSectionHeader(context, 'Recent activity',
                      onSeeAll: () {})),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, idx) {
                    final items = [
                      {
                        'title': 'Payment received',
                        'subtitle': '₹2,400 — 2 hours ago'
                      },
                      {'title': 'EMI due', 'subtitle': '₹3,200 — 3 days left'},
                      {
                        'title': 'New offer',
                        'subtitle': '0% interest for 2 months'
                      },
                      {'title': 'Profile verified', 'subtitle': 'KYC complete'},
                      {
                        'title': 'Invoice paid',
                        'subtitle': '₹18,700 — Yesterday'
                      },
                    ];
                    final item = items[idx % items.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _activityCard(
                          context, item['title']!, item['subtitle']!),
                    );
                  }, childCount: 6),
                ),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 160)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, String name, String avatarLetter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: _DT.primary.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8))
              ],
            ),
            child: CircleAvatar(
              backgroundColor: _DT.accent.withOpacity(0.12),
              child: Text(avatarLetter,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Welcome back,',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Text(name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Here\'s your financial snapshot',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600])),
                ]),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _DT.primary,
              elevation: 8,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: Icon(Icons.add_rounded, color: _DT.accent),
            label: const Text('New Application'),
          )
        ],
      ),
    );
  }

  Widget _buildStatsCarousel(BuildContext context) {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _pageController,
        itemCount: 3,
        onPageChanged: (p) => setState(() => _page = p),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              // subtle parallax effect
              double scale = 1.0;
              try {
                final page = _pageController.page ?? _page.toDouble();
                scale = (1 - (page - index).abs() * 0.06).clamp(0.92, 1.0);
              } catch (_) {}
              return Transform.scale(scale: scale, child: child);
            },
            child: _statCard(context, index),
          );
        },
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 110, maxHeight: 160),
        child: Container(
          decoration: BoxDecoration(
            gradient: _DT.accentGradient,
            borderRadius: BorderRadius.circular(_DT.radius),
            boxShadow: [
              BoxShadow(
                  color: _DT.accent.withOpacity(0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12)),
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
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
                    color: Colors.white.withOpacity(0.2)),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title']!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(item['value']!,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(item['subtitle']!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // subtle mini-progress ring
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                          value: (index + 1) / 3.5,
                          color: Colors.white24,
                          strokeWidth: 4),
                      Text('${(index + 1) * 25}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: active ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? _DT.accent : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: _DT.accent.withOpacity(0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
            );
          }),
        ),
      ),
    );
  }

  // ---------- QUICK ACTIONS ----------
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.payments_rounded, 'label': 'Pay'},
      {'icon': Icons.schedule, 'label': 'EMI'},
      {'icon': Icons.receipt_long, 'label': 'Statements'},
      {'icon': Icons.support_agent, 'label': 'Support'},
    ];

    return SizedBox(
      height: 88,
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
              width: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 8))
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 18,
                      backgroundColor: _DT.primary.withOpacity(0.06),
                      child: Icon(a['icon'] as IconData,
                          size: 18, color: _DT.primary)),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(a['label'] as String,
                          style: Theme.of(context).textTheme.bodySmall)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- PROMO STRIP ----------
  Widget _buildPromoStrip(BuildContext context) {
    // palette definitions (same as before)
    final palettes = [
      {
        'colors': [Color(0xFF00CFEA), Color(0xFF06B6D4)],
        'darkOverlay': false,
      },
      {
        'colors': [Color(0xFF0F172A), Color(0xFF2B3440)],
        'darkOverlay': true,
      },
      {
        'colors': [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
        'darkOverlay': true,
      },
      {
        'colors': [Color(0xFFFF9A3C), Color(0xFFFF6A00)],
        'darkOverlay': false,
      },
    ];

    return SizedBox(
      height: 132,
      child: PageView.builder(
        controller: _promoPageController,
        padEnds: false,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final i = index % palettes.length;
          final p = palettes[i];
          final colors = (p['colors'] as List<Color>);
          final isDark = p['darkOverlay'] as bool;
          final buttonIsWhite = isDark;

          // animate scale slightly based on distance to center
          double scale = 1.0;
          try {
            final page = _promoPageController.page ??
                _promoPageController.initialPage.toDouble();
            scale = (1 - ((page - index).abs() * 0.06)).clamp(0.9, 1.0);
          } catch (_) {}

          return Transform.scale(
            scale: scale,
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 12, right: 6, top: 4, bottom: 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: colors.first.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Stack(
                    children: [
                      // text column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            i == 1 ? 'Exclusive' : 'Tailored',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Colors.white.withOpacity(0.95),
                                    shadows: const [
                                  Shadow(color: Colors.black26, blurRadius: 4),
                                ]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            i == 1
                                ? '0% interest for 2 months'
                                : 'Get higher limit',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    shadows: const [
                                  Shadow(color: Colors.black38, blurRadius: 6),
                                ]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            i == 1
                                ? 'Limited time offer — T&C apply'
                                : 'Apply to increase your limit instantly',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Colors.white.withOpacity(0.92)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // right-center CTA: uses AnimatedScale for micro-bounce on press/hover
                      Positioned(
                        right: 10,
                        top:
                            40, // center-ish vertical position — safe for all cards
                        child: MouseRegion(
                          onEnter: (_) =>
                              setState(() => _promoButtonActive.add(index)),
                          onExit: (_) =>
                              setState(() => _promoButtonActive.remove(index)),
                          child: GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _promoButtonActive.add(index)),
                            onTapUp: (_) => setState(
                                () => _promoButtonActive.remove(index)),
                            onTapCancel: () => setState(
                                () => _promoButtonActive.remove(index)),
                            onTap: () {
                              // your CTA action here
                            },
                            child: AnimatedScale(
                              scale: _promoButtonActive.contains(index)
                                  ? 0.93
                                  : 1.0,
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOut,
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonIsWhite
                                        ? Colors.white
                                        : Colors.black.withOpacity(0.72),
                                    elevation: 8,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(
                                    'Learn',
                                    style: TextStyle(
                                      color: buttonIsWhite
                                          ? colors.first
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
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
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }

  Widget _activityCard(BuildContext context, String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: ListTile(
        onTap: () {},
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        leading: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
              color: _DT.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.receipt_long, color: _DT.accent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
