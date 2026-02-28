import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

class AdminUserItem {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final bool isEmailVerified;
  final DateTime? createdAt;

  const AdminUserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.isEmailVerified,
    this.createdAt,
  });

  factory AdminUserItem.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return AdminUserItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      isEmailVerified: map['isEmailVerified'] == true,
      createdAt: parseDate(map['createdAt']),
    );
  }
}

class AdminUserListResult {
  final List<AdminUserItem> users;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const AdminUserListResult({
    required this.users,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class AdminUserRepository {
  final Dio _dio;

  const AdminUserRepository(this._dio);

  Future<AdminUserListResult> listUsers({
    String? role,
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get('/admin/users', queryParameters: {
      if (role != null && role.isNotEmpty) 'role': role,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'limit': limit,
    });

    final root = (res.data as Map).cast<String, dynamic>();
    final data = (root['data'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final users = (data['users'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => AdminUserItem.fromMap(e.cast<String, dynamic>()))
        .toList();
    final pagination =
        (data['pagination'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    int toInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return AdminUserListResult(
      users: users,
      page: toInt(pagination['page'], page),
      limit: toInt(pagination['limit'], limit),
      total: toInt(pagination['total'], users.length),
      totalPages: toInt(pagination['totalPages'], 1),
    );
  }

  Future<void> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    await _dio.put('/admin/users/$userId/status', data: {'status': status});
  }
}

final adminUserRepositoryProvider = Provider<AdminUserRepository>((ref) {
  return AdminUserRepository(ref.read(apiClientProvider));
});
