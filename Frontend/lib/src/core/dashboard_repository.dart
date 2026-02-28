import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

class DashboardResponse {
  final String role;
  final Map<String, dynamic> data;

  const DashboardResponse({
    required this.role,
    required this.data,
  });
}

class DashboardRepository {
  final Dio _dio;
  const DashboardRepository(this._dio);

  Future<DashboardResponse> fetchDashboard() async {
    final res = await _dio.get('/dashboard');
    final map = (res.data as Map).cast<String, dynamic>();
    final data = (map['data'] is Map)
        ? (map['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    return DashboardResponse(
      role: map['role']?.toString() ?? 'UNKNOWN',
      data: data,
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.read(apiClientProvider));
});

final dashboardProvider = FutureProvider<DashboardResponse>((ref) async {
  return ref.read(dashboardRepositoryProvider).fetchDashboard();
});

