// simple helper if needed (not required)
import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DT.muted));
  }
}
