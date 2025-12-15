import 'dart:async';
import 'package:flutter/material.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final PageController _promoController =
      PageController(viewportFraction: 0.88);
  int _promoIndex = 0;
  Timer? _timer;

  final List<_PromoCard> promos = const [
    _PromoCard(
      title: 'Smart Savings',
      description: 'Grow your money automatically with smart rules.',
      gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
    ),
    _PromoCard(
      title: 'Instant Payments',
      description: 'Send & receive money instantly with zero hassle.',
      gradient: LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)]),
    ),
    _PromoCard(
      title: 'Secure Banking',
      description: 'Enterprise-grade security for your funds.',
      gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]),
    ),
    _PromoCard(
      title: 'Track Spending',
      description: 'Visual insights into where your money goes.',
      gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_promoController.hasClients) return;

      _promoIndex = (_promoIndex + 1) % promos.length;
      _promoController.animateToPage(
        _promoIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildPromoSlider(),
          _buildQuickActions(),
          _buildActivityHeader(),
          _buildActivityList(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  // ───────────────── APP BAR ─────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Welcome back 👋',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Customer Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── PROMO SLIDER ─────────────────

  SliverToBoxAdapter _buildPromoSlider() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 190,
        child: PageView.builder(
          controller: _promoController,
          itemCount: promos.length,
          itemBuilder: (_, index) {
            final promo = promos[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                decoration: BoxDecoration(
                  gradient: promo.gradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: promo.gradient.colors.first.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promo.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text('Learn more'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ───────────────── QUICK ACTIONS ─────────────────

  SliverPadding _buildQuickActions() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildListDelegate.fixed([
          _QuickAction(icon: Icons.send, label: 'Send Money'),
          _QuickAction(icon: Icons.account_balance, label: 'Accounts'),
          _QuickAction(icon: Icons.credit_card, label: 'Cards'),
          _QuickAction(icon: Icons.bar_chart, label: 'Analytics'),
        ]),
      ),
    );
  }

  // ───────────────── ACTIVITY ─────────────────

  SliverToBoxAdapter _buildActivityHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text(
          'Recent Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  SliverList _buildActivityList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.withOpacity(0.1),
              child: const Icon(Icons.swap_horiz, color: Colors.indigo),
            ),
            title: Text('Transaction #${index + 1}'),
            subtitle: const Text('Completed'),
            trailing: const Text(
              '- ₹250',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          );
        },
        childCount: 10,
      ),
    );
  }
}

// ───────────────── MODELS & WIDGETS ─────────────────

class _PromoCard {
  final String title;
  final String description;
  final LinearGradient gradient;

  const _PromoCard({
    required this.title,
    required this.description,
    required this.gradient,
  });
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.indigo),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
