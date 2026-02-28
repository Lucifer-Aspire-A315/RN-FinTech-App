class ApiEnvelope<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;
  final Map<String, dynamic>? pagination;

  const ApiEnvelope({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.pagination,
  });

  factory ApiEnvelope.fromMap(
    Map<String, dynamic> map, {
    T Function(dynamic raw)? dataParser,
  }) {
    return ApiEnvelope<T>(
      success: map['success'] == true,
      message: map['message']?.toString(),
      data: dataParser != null ? dataParser(map['data']) : map['data'] as T?,
      statusCode: map['statusCode'] is int ? map['statusCode'] as int : null,
      pagination: map['pagination'] is Map<String, dynamic>
          ? map['pagination'] as Map<String, dynamic>
          : null,
    );
  }
}

class PagedResult<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PagedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

