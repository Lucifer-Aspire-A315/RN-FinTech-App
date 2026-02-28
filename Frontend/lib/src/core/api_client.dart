import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'auth_repository.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final repo = ref.read(authRepositoryProvider);
  bool isRefreshing = false;

  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
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
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final shouldRefresh = status == 401 &&
            error.requestOptions.path != '/auth/login' &&
            error.requestOptions.path != '/auth/refresh-token';

        if (!shouldRefresh) {
          handler.next(error);
          return;
        }

        if (isRefreshing) {
          handler.next(error);
          return;
        }

        isRefreshing = true;
        try {
          final refreshToken = await repo.getRefreshToken();
          if (refreshToken == null) {
            await repo.logout();
            handler.next(error);
            return;
          }

          final refreshRes = await dio.post(
            '/auth/refresh-token',
            data: {'refreshToken': refreshToken},
            options: Options(headers: {'Authorization': null}),
          );

          final data = refreshRes.data['data'] as Map<String, dynamic>;
          final newAccess = data['token']?.toString();
          final newRefresh = data['refreshToken']?.toString();
          if (newAccess == null || newRefresh == null) {
            await repo.logout();
            handler.next(error);
            return;
          }

          await repo.applyRefreshedTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );

          final retryOptions = error.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccess';
          final retryResponse = await dio.fetch(retryOptions);
          handler.resolve(retryResponse);
        } catch (_) {
          await repo.logout();
          handler.next(error);
        } finally {
          isRefreshing = false;
        }
      },
    ),
  );

  return dio;
});
