// lib/src/core/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_notifier.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000/api/v1', // replace if needed
    connectTimeout: const Duration(milliseconds: 10000),
    receiveTimeout: const Duration(milliseconds: 10000),
  ));

  // add interceptor that attaches access token and attempts refresh on 401
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final authState = ref.read(authNotifierProvider);
      final token = authState.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (err, handler) async {
      // Only attempt refresh once per request
      final requestOptions = err.requestOptions;
      final isUnauthorized = err.response?.statusCode == 401;
      final alreadyRetried = requestOptions.headers['x-retried'] == true;

      if (isUnauthorized && !alreadyRetried) {
        try {
          final authNotifier = ref.read(authNotifierProvider.notifier);
          final refreshed = await authNotifier.refreshTokenIfNeeded();
          if (refreshed) {
            final newToken = ref.read(authNotifierProvider).accessToken;
            if (newToken != null) {
              // mark retried to avoid loop
              requestOptions.headers['x-retried'] = true;
              requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final cloneReq = await dio.fetch(requestOptions);
              return handler.resolve(cloneReq);
            }
          }
        } catch (_) {
          // continue to error handling below
        }
      }
      return handler.next(err);
    },
  ));

  return dio;
});
