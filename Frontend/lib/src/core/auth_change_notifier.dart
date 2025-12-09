// lib/src/core/auth_change_notifier.dart
import 'package:flutter/foundation.dart';

class AuthChangeNotifier extends ChangeNotifier {
  // Call notify() whenever auth state changes
  void notify() => notifyListeners();
}
