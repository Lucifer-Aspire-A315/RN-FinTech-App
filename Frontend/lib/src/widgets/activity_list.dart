import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'summary_card.dart';

class ActivityList extends ConsumerWidget {
  final String role;
  final bool shrinkWrap;
  final bool lockToAncestorScroll;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  final int maxItemsToShow;

  const ActivityList({
    super.key,
    required this.role,
    this.shrinkWrap = false,
    this.lockToAncestorScroll = true,
    this.physics,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
    this.maxItemsToShow = 50,
  });

  List<Map<String, String>> _sampleData() {
    return <Map<String, String>>[
      {'title': 'Payment received', 'subtitle': 'Rs 2,400 - 2 hours ago'},
      {'title': 'EMI due', 'subtitle': 'Rs 3,200 - 3 days left'},
      {'title': 'New offer', 'subtitle': '0% interest for 2 months'},
      {'title': 'Profile verified', 'subtitle': 'KYC complete'},
      {'title': 'Invoice paid', 'subtitle': 'Rs 18,700 - Yesterday'},
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _sampleData();
    final hasScrollableAncestor = Scrollable.maybeOf(context) != null;

    final effectiveShrinkWrap =
        shrinkWrap || (lockToAncestorScroll && hasScrollableAncestor);
    final effectivePhysics = physics ??
        (effectiveShrinkWrap
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics());

    return ListView.separated(
      padding: padding,
      shrinkWrap: effectiveShrinkWrap,
      physics: effectivePhysics,
      itemBuilder: (context, idx) {
        final item = items[idx % items.length];
        final color = _activityColor(idx);
        return SummaryCard(
          title: item['title']!,
          subtitle: item['subtitle'],
          leading: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(_activityIcon(idx), size: 16, color: color),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {},
          ),
          onTap: () {},
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: items.length.clamp(0, maxItemsToShow),
    );
  }

  Color _activityColor(int index) {
    const colors = <Color>[
      Color(0xFF2563EB),
      Color(0xFF16A34A),
      Color(0xFF7C3AED),
      Color(0xFFD97706),
      Color(0xFF0EA5E9),
    ];
    return colors[index % colors.length];
  }

  IconData _activityIcon(int index) {
    const icons = <IconData>[
      Icons.account_balance_wallet_rounded,
      Icons.calendar_month_rounded,
      Icons.local_offer_rounded,
      Icons.verified_rounded,
      Icons.receipt_long_rounded,
    ];
    return icons[index % icons.length];
  }
}
