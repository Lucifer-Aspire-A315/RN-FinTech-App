import 'package:fintech_frontend/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // << important for asset loading on web
  runApp(const ProviderScope(child: App()));
}
