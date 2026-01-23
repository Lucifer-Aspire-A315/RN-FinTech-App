// lib/src/app.dart
import 'package:fintech_frontend/src/routing/router_provider.dart';
import 'package:fintech_frontend/src/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Fintech App',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F9FC),
        colorSchemeSeed: const Color(0xFF00BCD4),
        textTheme: appTextTheme(context),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
