import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final authChangeNotifierProvider =
    Provider<AuthChangeNotifier>((ref) {
  return AuthChangeNotifier();
});
