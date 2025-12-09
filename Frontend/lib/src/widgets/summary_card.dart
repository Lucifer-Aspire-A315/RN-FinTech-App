// lib/src/widgets/summary_card.dart
import 'package:flutter/material.dart';

/// A compact summary card used in lists or dashboards.
///
/// Safe to use inside scrollables (vertical or horizontal) because it
/// does not rely on Expanded inside an unbounded Row.
class SummaryCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double elevation;
  final EdgeInsetsGeometry padding;

  const SummaryCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.elevation = 2,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding,
          child: Row(
            // allow the Row to shrink-wrap when parent provides unbounded width
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(
                      minWidth: 40, maxWidth: 56, minHeight: 40, maxHeight: 56),
                  child: Center(child: leading),
                ),
                const SizedBox(width: 12),
              ],
              // Use Flexible with FlexFit.loose so the text can size itself
              Flexible(
                fit: FlexFit.loose,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                // trailing should not force the row to expand; constrain it
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 36, maxWidth: 120),
                  child:
                      Align(alignment: Alignment.centerRight, child: trailing),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
