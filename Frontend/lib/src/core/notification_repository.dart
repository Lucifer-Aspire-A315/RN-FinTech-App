import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

class NotificationItem {
  final String id;
  final String type;
  final String message;
  final String status;
  final DateTime? createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.message,
    required this.status,
    this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return NotificationItem(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'GENERAL',
      message: map['message']?.toString() ?? '',
      status: map['status']?.toString() ?? 'unread',
      createdAt: parseDate(map['createdAt']),
    );
  }
}

class NotificationListResult {
  final List<NotificationItem> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const NotificationListResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class NotificationRepository {
  final Dio _dio;

  const NotificationRepository(this._dio);

  Future<NotificationListResult> list({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get('/notifications', queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page,
      'limit': limit,
    });

    final root = (res.data as Map).cast<String, dynamic>();
    final data = (root['data'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final rows = (data['notifications'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => NotificationItem.fromMap(e.cast<String, dynamic>()))
        .toList();
    final pagination = (data['pagination'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    int toInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return NotificationListResult(
      items: rows,
      page: toInt(pagination['page'], page),
      limit: toInt(pagination['limit'], limit),
      total: toInt(pagination['total'], rows.length),
      totalPages: toInt(pagination['totalPages'], 1),
    );
  }

  Future<void> markRead(String id) async {
    await _dio.put('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.put('/notifications/read-all');
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiClientProvider));
});
