// lib/src/widgets/dashboard_header.dart
import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class DashboardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String avatarText;
  final Widget? trailing;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.avatarText,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          child: Text(avatarText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
          ]),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
