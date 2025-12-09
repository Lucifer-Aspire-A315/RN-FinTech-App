// lib/src/widgets/activity_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_tokens.dart';
import 'summary_card.dart';

/// ActivityList - a self-adapting activity list widget safe to embed inside other
/// scrollables. It will automatically switch to a shrink-wrapped, non-scrolling
/// variant when it detects a Scrollable ancestor (or when shrinkWrap=true is passed).
///
/// Usage:
/// - ActivityList(role: 'customer') -> normal list (scrollable) when placed in a fixed-height area
/// - ActivityList(role: 'customer', shrinkWrap: true) -> always shrink-wrapped and non-scrollable
class ActivityList extends ConsumerWidget {
  final String role; // 'customer' | 'merchant' | 'banker' | 'admin'
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  final int maxItemsToShow; // when rendering as Column fallback

  const ActivityList({
    super.key,
    required this.role,
    this.shrinkWrap = false,
    this.physics,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
    this.maxItemsToShow = 50,
  });

  // Sample data used until you wire real API calls
  List<Map<String, String>> _sampleData() {
    return <Map<String, String>>[
      {'title': 'Payment received', 'subtitle': '₹ 2,400 — 2 hours ago'},
      {'title': 'EMI due', 'subtitle': '₹ 3,200 — 3 days left'},
      {'title': 'New offer', 'subtitle': '0% interest for 2 months'},
      {'title': 'Profile verified', 'subtitle': 'KYC complete'},
      {'title': 'Invoice paid', 'subtitle': '₹ 18,700 — Yesterday'},
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _sampleData();
    // detect whether an outer Scrollable exists (ListView/CustomScrollView/SingleChildScrollView etc.)
    final hasScrollableAncestor = Scrollable.of(context) != null;

    // If user explicitly asks for shrinkWrap OR we found a scrollable ancestor,
    // render a shrink-wrapped non-scrolling list to avoid nested scroll conflicts.
    final effectiveShrinkWrap = shrinkWrap || hasScrollableAncestor;
    final effectivePhysics = physics ??
        (effectiveShrinkWrap
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics());

    // Defensive: if only a few items and shrink-wrapped asked, render Column (simpler).
    if (effectiveShrinkWrap && items.length <= 10) {
      return Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(
            items.length.clamp(0, maxItemsToShow),
            (idx) {
              final item = items[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SummaryCard(
                  title: item['title'] ?? '',
                  subtitle: item['subtitle'],
                  leading: const Icon(Icons.circle, size: 14),
                  trailing: IconButton(
                      icon: const Icon(Icons.chevron_right), onPressed: () {}),
                  onTap: () {},
                ),
              );
            },
          ),
        ),
      );
    }

    // Otherwise render a ListView with appropriate shrinkWrap/physics.
    return ListView.separated(
      padding: padding,
      shrinkWrap: effectiveShrinkWrap,
      physics: effectivePhysics,
      itemBuilder: (context, idx) {
        final item = items[idx % items.length];
        return SummaryCard(
          title: item['title'] ?? '',
          subtitle: item['subtitle'],
          leading: const Icon(Icons.circle, size: 14),
          trailing: IconButton(
              icon: const Icon(Icons.chevron_right), onPressed: () {}),
          onTap: () {},
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: items.length.clamp(0, maxItemsToShow),
    );
  }
}
