// lib/src/core/auth_repository.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref);
});

const BASE_URL = 'http://localhost:3000/api/v1'; // <-- replace this

class UserProfile {
  final String id;
  final String email;
  final String role;
  final String name;

  UserProfile(
      {required this.id,
      required this.email,
      required this.role,
      required this.name});

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'].toString(),
        email: m['email'] as String,
        role: m['role'] as String,
        name: (m['name'] ?? '') as String,
      );
}

class ApiError implements Exception {
  final String message;
  final Map<String, dynamic>? details;
  ApiError(this.message, {this.details});
  @override
  String toString() => message;
}

class AuthRepository {
  final Ref ref;
  final _storage = const FlutterSecureStorage();
  String? accessToken; // kept in memory
  UserProfile? user;

  late final Dio _dio;

  AuthRepository(this.ref) {
    _dio = Dio(BaseOptions(
      baseUrl: BASE_URL,
      connectTimeout: const Duration(milliseconds: 10000),
      receiveTimeout: const Duration(milliseconds: 10000),
    ));
  }

  // LOGIN
  Future<void> login({required String email, required String password}) async {
    try {
      final res = await _dio
          .post('/auth/login', data: {'email': email, 'password': password});
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        accessToken = data['accessToken'] as String?;
        final refresh = data['refreshToken'] as String?;
        if (refresh != null)
          await _storage.write(key: 'refresh_token', value: refresh);
        if (data['user'] != null)
          user = UserProfile.fromMap(Map<String, dynamic>.from(data['user']));
        return;
      }
      throw ApiError('Login failed: ${res.statusCode}');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        final d = Map<String, dynamic>.from(e.response!.data as Map);
        throw ApiError(d['message'] ?? 'Login failed', details: d);
      }
      throw ApiError(e.message.toString());
    } catch (e) {
      rethrow;
    }
  }

  // SIGNUP - dynamic payload for role-specific fields
  // `payload` should contain at least { email, password, role, ... }
  Future<void> signup({required Map<String, dynamic> payload}) async {
    try {
      final res = await _dio.post('/auth/signup', data: payload);
      if (res.statusCode == 201 || res.statusCode == 200) {
        // backend may return tokens or require email verification — handle both:
        final data = res.data as Map<String, dynamic>?;

        if (data != null) {
          accessToken = data['accessToken'] as String?;
          final refresh = data['refreshToken'] as String?;
          if (refresh != null)
            await _storage.write(key: 'refresh_token', value: refresh);
          if (data['user'] != null)
            user = UserProfile.fromMap(Map<String, dynamic>.from(data['user']));
        }
        return;
      }
      throw ApiError('Signup failed: ${res.statusCode}');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        final d = Map<String, dynamic>.from(e.response!.data as Map);
        // Some backends return validation errors as { errors: {field: message} }
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
    accessToken = null;
    user = null;
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> refreshTokenIfNeeded() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return false;
    try {
      final res =
          await _dio.post('/auth/refresh', data: {'refreshToken': refresh});
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        accessToken = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newRefresh != null)
          await _storage.write(key: 'refresh_token', value: newRefresh);
        if (data['user'] != null)
          user = UserProfile.fromMap(Map<String, dynamic>.from(data['user']));
        return true;
      }
    } catch (_) {}
    return false;
  }
}
