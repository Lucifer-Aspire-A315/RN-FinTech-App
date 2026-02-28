import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_notifier.dart';
import 'auth_state.dart';

final routerRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);

  ref.listen<AuthState>(authNotifierProvider, (_, __) {
    notifier.value++;
  });

  return notifier;
});
