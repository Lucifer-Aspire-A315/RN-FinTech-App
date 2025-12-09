// lib/src/core/auth_notifier.dart
import 'dart:async';
import 'package:fintech_frontend/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'auth_state.dart';
import 'auth_change_notifier.dart';

const _BASE_URL = 'http://localhost:3000/api/v1'; // adjust if needed

final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  return AuthChangeNotifier();
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final changeNotifier = ref.read(authChangeNotifierProvider);
  return AuthNotifier(ref, changeNotifier);
});

class ApiError implements Exception {
  final String message;
  final Map<String, dynamic>? details;
  ApiError(this.message, {this.details});
  @override
  String toString() => message;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final AuthChangeNotifier authChange;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;

  AuthNotifier(this.ref, this.authChange) : super(const AuthState()) {
    _dio = Dio(BaseOptions(
      baseUrl: _BASE_URL,
      connectTimeout: const Duration(milliseconds: 10000),
      receiveTimeout: const Duration(milliseconds: 10000),
    ));
    // try restore session in background
    unawaited(_restoreSessionIfPossible());
  }

  // typed accessors
  String? get accessToken => state.accessToken;
  User? get user => state.user;

  Future<void> _restoreSessionIfPossible() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return;
    try {
      final res =
          await _dio.post('/auth/refresh', data: {'refreshToken': refresh});
      debugPrint(
          '[AuthNotifier] refresh response: status=${res.statusCode} data=${res.data}');
      if (res.statusCode == 200 && res.data != null) {
        final extracted = _extractAuthMapFromResponse(res.data);
        final access = extracted['access'] as String?;
        final newRefresh = extracted['refresh'] as String?;
        final userMap = extracted['userMap'] as Map<String, dynamic>?;

        User? typedUser = userMap != null ? User.fromMap(userMap) : null;

        if (newRefresh != null)
          await _storage.write(key: 'refresh_token', value: newRefresh);

        // If no user object returned, try to fetch profile
        if (typedUser == null && access != null) {
          final fetched = await _fetchProfile(access);
          if (fetched != null) typedUser = fetched;
        }

        state = AuthState(accessToken: access, user: typedUser);
        debugPrint(
            '[AuthNotifier] restore -> new state: access=${state.accessToken != null}, user=${state.user}');
        authChange.notify();
      }
    } catch (e) {
      debugPrint('[AuthNotifier] restore error: $e');
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final res = await _dio
          .post('/auth/login', data: {'email': email, 'password': password});
      debugPrint(
          '[AuthNotifier] login response: status=${res.statusCode} data=${res.data}');
      if (res.statusCode == 200 && res.data != null) {
        final extracted = _extractAuthMapFromResponse(res.data);
        final access = extracted['access'] as String?;
        final refresh = extracted['refresh'] as String?;
        final userMap = extracted['userMap'] as Map<String, dynamic>?;

        User? typedUser = userMap != null ? User.fromMap(userMap) : null;

        if (refresh != null)
          await _storage.write(key: 'refresh_token', value: refresh);

        // If we have access token but no user, try to fetch profile endpoints
        if (typedUser == null && access != null) {
          final fetched = await _fetchProfile(access);
          if (fetched != null) typedUser = fetched;
        }

        state = AuthState(accessToken: access, user: typedUser);
        debugPrint(
            '[AuthNotifier] new state: access=${state.accessToken != null}, user=${state.user}');
        authChange.notify();
        return;
      }
      throw ApiError('Login failed: ${res.statusCode}');
    } on DioException catch (e) {
      debugPrint(
          '[AuthNotifier] login DioError: ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.data != null && e.response!.data is Map) {
        final d = Map<String, dynamic>.from(e.response!.data as Map);
        throw ApiError(d['message'] ?? 'Login failed', details: d);
      }
      throw ApiError(e.message.toString());
    }
  }

  Future<void> signup({required Map<String, dynamic> payload}) async {
    try {
      final res = await _dio.post('/auth/signup', data: payload);
      debugPrint(
          '[AuthNotifier] signup response: status=${res.statusCode} data=${res.data}');
      if ((res.statusCode == 201 || res.statusCode == 200) &&
          res.data != null) {
        final extracted = _extractAuthMapFromResponse(res.data);
        final access = extracted['access'] as String?;
        final refresh = extracted['refresh'] as String?;
        final userMap = extracted['userMap'] as Map<String, dynamic>?;

        User? typedUser = userMap != null ? User.fromMap(userMap) : null;

        if (refresh != null)
          await _storage.write(key: 'refresh_token', value: refresh);

        // if we have access token but no user, try to fetch profile endpoints
        if (typedUser == null && access != null) {
          final fetched = await _fetchProfile(access);
          if (fetched != null) typedUser = fetched;
        }

        if (access != null || typedUser != null) {
          state = AuthState(accessToken: access, user: typedUser);
          debugPrint(
              '[AuthNotifier] new state after signup: access=${state.accessToken != null}, user=${state.user}');
          authChange.notify();
        }
        return;
      }
      throw ApiError('Signup failed: ${res.statusCode}');
    } on DioError catch (e) {
      debugPrint(
          '[AuthNotifier] signup DioError: ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.data != null && e.response!.data is Map) {
        final d = Map<String, dynamic>.from(e.response!.data as Map);
        if (d.containsKey('errors') && d['errors'] is Map) {
          throw ApiError(d['message'] ?? 'Validation failed',
              details: Map<String, dynamic>.from(d['errors']));
        }
        throw ApiError(d['message'] ?? 'Signup failed', details: d);
      }
      throw ApiError(e.message.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    state = const AuthState();
    await _storage.delete(key: 'refresh_token');
    authChange.notify();
  }

  Map<String, dynamic> _extractAuthMapFromResponse(dynamic raw) {
    // Return map with keys: 'access', 'refresh', 'userMap'
    try {
      if (raw == null) return {};
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        // Common shape 1: { accessToken, refreshToken, user }
        if (m.containsKey('accessToken') ||
            m.containsKey('refreshToken') ||
            m.containsKey('user')) {
          return {
            'access': m['accessToken'],
            'refresh': m['refreshToken'],
            'userMap': m['user'],
          }..removeWhere((k, v) => v == null);
        }

        // Common shape 2: { token, refreshToken, user } (flat)
        if (m.containsKey('token') ||
            m.containsKey('refreshToken') ||
            m.containsKey('user')) {
          return {
            'access': m['token'] ?? m['accessToken'],
            'refresh': m['refreshToken'],
            'userMap': m['user'],
          }..removeWhere((k, v) => v == null);
        }

        // Common shape 3: { success:true, data: { user, token, refreshToken } }
        if (m.containsKey('data') && m['data'] is Map) {
          final data = Map<String, dynamic>.from(m['data'] as Map);
          return {
            'access': data['token'] ?? data['accessToken'] ?? data['access'],
            'refresh': data['refreshToken'] ?? data['refresh'],
            'userMap': data['user'] ?? data['userMap'],
          }..removeWhere((k, v) => v == null);
        }

        // Common shape 4: nested under 'result' or other wrappers
        for (final key in ['result', 'payload', 'response']) {
          if (m.containsKey(key) && m[key] is Map) {
            final data = Map<String, dynamic>.from(m[key] as Map);
            if (data.containsKey('token') ||
                data.containsKey('accessToken') ||
                data.containsKey('user')) {
              return {
                'access': data['token'] ?? data['accessToken'],
                'refresh': data['refreshToken'],
                'userMap': data['user'],
              }..removeWhere((k, v) => v == null);
            }
          }
        }

        // Fallback: if map itself contains 'user' or tokens deeper, try to find them
        if (m.containsKey('user')) {
          return {'userMap': m['user']};
        }
        if (m.containsKey('token')) {
          return {'access': m['token']};
        }
      }
    } catch (_) {}
    return {};
  }

  Future<User?> _fetchProfile(String? accessToken) async {
    if (accessToken == null) return null;
    try {
      final client = Dio(BaseOptions(
          baseUrl: _BASE_URL,
          connectTimeout: const Duration(milliseconds: 10000),
          receiveTimeout: const Duration(milliseconds: 10000)));
      client.options.headers['Authorization'] = 'Bearer $accessToken';

      // Try common profile endpoints in order
      final candidates = ['/auth/me', '/users/me', '/me', '/profile'];
      for (final path in candidates) {
        try {
          final res = await client.get(path);
          debugPrint(
              '[AuthNotifier] profile fetch ${path} -> status=${res.statusCode} data=${res.data}');
          if (res.statusCode == 200 && res.data is Map) {
            final data = Map<String, dynamic>.from(res.data as Map);
            // if backend wraps user under `user` key, extract it
            final userMap = (data['user'] is Map)
                ? Map<String, dynamic>.from(data['user'])
                : data;
            if (userMap.isNotEmpty) return User.fromMap(userMap);
          }
        } catch (e) {
          // ignore and try next
        }
      }
    } catch (e) {
      debugPrint('[AuthNotifier] _fetchProfile failed: $e');
    }
    return null;
  }

  Future<bool> refreshTokenIfNeeded() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return false;
    try {
      final res =
          await _dio.post('/auth/refresh', data: {'refreshToken': refresh});
      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        final access = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        final userMap = data['user'] as Map<String, dynamic>?;
        final typedUser = userMap != null ? User.fromMap(userMap) : state.user;
        if (newRefresh != null)
          await _storage.write(key: 'refresh_token', value: newRefresh);
        state = AuthState(accessToken: access, user: typedUser);
        debugPrint(
            '[AuthNotifier] new state: access=${state.accessToken != null}, user=${state.user}');
        authChange.notify();
        return true;
      }
    } catch (_) {}
    state = const AuthState();
    await _storage.delete(key: 'refresh_token');
    authChange.notify();
    return false;
  }
}
