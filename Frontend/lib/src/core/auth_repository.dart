import 'package:dio/dio.dart';
import 'package:fintech_frontend/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


const BASE_URL = 'http://localhost:3000/api/v1';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? accessToken;
  User? user;

  AuthRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: BASE_URL,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  // ---------------- LOGIN ----------------
  Future<void> login(String email, String password) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = res.data['data'];
    accessToken = data['token'];
    await _storage.write(key: 'refresh_token', value: data['refreshToken']);

    user = User.fromMap(data['user']);
  }

  // ---------------- SIGNUP ----------------
  Future<void> signup(Map<String, dynamic> payload) async {
    final res = await _dio.post('/auth/signup', data: payload);

    if (res.data['data'] != null) {
      final data = res.data['data'];
      accessToken = data['token'];
      await _storage.write(key: 'refresh_token', value: data['refreshToken']);
      user = User.fromMap(data['user']);
    }
  }

  // ---------------- REFRESH TOKEN ----------------
  Future<bool> refreshTokenIfNeeded() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return false;

    try {
      final res = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );

      final data = res.data['data'];
      accessToken = data['token'];
      await _storage.write(
          key: 'refresh_token', value: data['refreshToken']);
      user = User.fromMap(data['user']);
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
    accessToken = null;
    user = null;
    await _storage.delete(key: 'refresh_token');
  }
}
