// lib/src/widgets/stats_card.dart
import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Widget? trailing;

  const StatsCard({super.key, required this.title, required this.value, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: DT.elevationLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.radius)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 6),
                Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                ],
              ]),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
