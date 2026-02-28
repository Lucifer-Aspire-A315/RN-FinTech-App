import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

class ProfilePayload {
  final Map<String, dynamic> user;
  final Map<String, dynamic> profile;

  const ProfilePayload({
    required this.user,
    required this.profile,
  });
}

class ProfileRepository {
  final Dio _dio;

  const ProfileRepository(this._dio);

  Future<ProfilePayload> getProfile() async {
    final res = await _dio.get('/profile');
    final data = (res.data['data'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return ProfilePayload(
      user: (data['user'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
      profile: (data['profile'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
    );
  }

  Future<ProfilePayload> updateProfile(Map<String, dynamic> updateData) async {
    final res = await _dio.put('/profile', data: updateData);
    final data = (res.data['data'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return ProfilePayload(
      user: (data['user'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
      profile: (data['profile'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
    );
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/profile');
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(apiClientProvider));
});
