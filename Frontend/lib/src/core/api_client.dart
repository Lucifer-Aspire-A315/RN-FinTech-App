import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final repo = ref.read(authRepositoryProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: BASE_URL,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (repo.accessToken != null) {
          options.headers['Authorization'] =
              'Bearer ${repo.accessToken}';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});
