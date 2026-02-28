import 'package:dio/dio.dart';
import 'package:fintech_frontend/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_config.dart';
import 'api_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final User user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

class UserSession {
  final String id;
  final String? deviceInfo;
  final String? ipAddress;
  final DateTime? lastActive;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const UserSession({
    required this.id,
    this.deviceInfo,
    this.ipAddress,
    this.lastActive,
    this.createdAt,
    this.expiresAt,
  });

  factory UserSession.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return UserSession(
      id: map['id']?.toString() ?? '',
      deviceInfo: map['deviceInfo']?.toString(),
      ipAddress: map['ipAddress']?.toString(),
      lastActive: parseDate(map['lastActive']),
      createdAt: parseDate(map['createdAt']),
      expiresAt: parseDate(map['expiresAt']),
    );
  }
}

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? accessToken;
  User? user;

  AuthRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  // ---------------- LOGIN ----------------
  Future<void> login(String email, String password) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromMap(
        res.data as Map<String, dynamic>,
        dataParser: (raw) => (raw as Map).cast<String, dynamic>(),
      );
      final data = envelope.data;
      if (data == null) {
        throw Exception('Unexpected login response');
      }

      accessToken = data['token']?.toString();
      final refreshToken = data['refreshToken']?.toString();
      if (accessToken == null || refreshToken == null) {
        throw Exception('Login session payload is incomplete');
      }

      await _storage.write(key: 'refresh_token', value: refreshToken);
      await _storage.write(key: 'access_token', value: accessToken);
      user = User.fromMap((data['user'] as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // ---------------- SIGNUP ----------------
  Future<void> signup(Map<String, dynamic> payload) async {
    try {
      await _dio.post('/auth/signup', data: payload);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // ---------------- REFRESH TOKEN ----------------
  Future<bool> refreshTokenIfNeeded() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return false;

    try {
      final res = await _dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refresh},
      );

      final data = res.data['data'];
      accessToken = data['token']?.toString();
      if (accessToken == null) return false;
      await _storage.write(
          key: 'refresh_token', value: data['refreshToken']);
      await _storage.write(key: 'access_token', value: accessToken);
      user = await fetchCurrentUser();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
    try {
      final refresh = await _storage.read(key: 'refresh_token');
      if (refresh != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refresh});
      }
    } catch (_) {}
    finally {
      accessToken = null;
      user = null;
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'access_token');
    }
  }

  Future<void> resendVerification(String email) async {
    await _dio.post('/auth/resend-verification', data: {
      'email': email,
    });
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post('/auth/request-password-reset', data: {'email': email});
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (accessToken == null) {
      throw Exception('Session expired. Please login again.');
    }

    try {
      await _dio.post(
        '/auth/change-password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
        options: _authOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<List<UserSession>> listSessions() async {
    if (accessToken == null) {
      throw Exception('Session expired. Please login again.');
    }

    try {
      final res = await _dio.get('/auth/sessions', options: _authOptions());
      final raw = (res.data['data'] as List?) ?? const [];
      return raw
          .whereType<Map>()
          .map((e) => UserSession.fromMap(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> revokeSession(String sessionId) async {
    if (accessToken == null) {
      throw Exception('Session expired. Please login again.');
    }

    try {
      await _dio.delete('/auth/sessions/$sessionId', options: _authOptions());
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<User> fetchCurrentUser() async {
    if (accessToken == null) {
      throw Exception('No access token available');
    }

    final res = await _dio.get(
      '/profile',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );

    final data = (res.data['data'] as Map?)?.cast<String, dynamic>();
    final userMap = (data?['user'] as Map?)?.cast<String, dynamic>();
    final profileMap = (data?['profile'] as Map?)?.cast<String, dynamic>() ?? {};

    if (userMap == null) {
      throw Exception('Invalid profile payload');
    }

    final merged = {...userMap, 'profile': profileMap};
    return User.fromMap(merged);
  }

  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');

  Future<void> applyRefreshedTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      }
    }
    return e.message ?? 'Request failed';
  }

  Options _authOptions() => Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      );

}
