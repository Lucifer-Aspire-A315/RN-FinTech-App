import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/loans/loan_models.dart';
import 'api_client.dart';

class LoanRepository {
  final Dio _dio;

  const LoanRepository(this._dio);

  Future<LoanListResult> listLoans({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '/loan',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
    );

    final data = (res.data['data'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => LoanSummary.fromMap(e.cast<String, dynamic>()))
        .toList();

    final pagination = (res.data['pagination'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    int toInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return LoanListResult(
      items: data,
      page: toInt(pagination['page'], page),
      limit: toInt(pagination['limit'], limit),
      total: toInt(pagination['total'], data.length),
      totalPages: toInt(pagination['totalPages'], 1),
    );
  }

  Future<LoanSummary> getLoan(String id) async {
    final res = await _dio.get('/loan/$id');
    final map = (res.data['data'] as Map).cast<String, dynamic>();
    return LoanSummary.fromMap(map);
  }

  Future<void> applyLoan({
    required String loanTypeId,
    required num amount,
    int? tenorMonths,
    Map<String, dynamic>? applicant,
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>> documents = const <Map<String, dynamic>>[],
  }) async {
    await _dio.post('/loan/apply', data: {
      'loanTypeId': loanTypeId,
      'amount': amount,
      if (tenorMonths != null) 'tenorMonths': tenorMonths,
      if (applicant != null) 'applicant': applicant,
      'metadata': metadata ?? <String, dynamic>{},
      'documents': documents,
    });
  }

  Future<void> cancelLoan(String id, {String? reason}) async {
    await _dio.post('/loan/$id/cancel', data: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<void> assignBanker({
    required String id,
    required String bankerId,
  }) async {
    await _dio.post('/loan/$id/assign', data: {'bankerId': bankerId});
  }

  Future<void> requestAssignment({
    required String id,
    String? note,
    required num proposedInterestRate,
  }) async {
    await _dio.post('/loan/$id/request-assignment', data: {
      if (note != null && note.isNotEmpty) 'note': note,
      'proposedInterestRate': proposedInterestRate,
    });
  }

  Future<void> assignmentDecision({
    required String id,
    required String bankerId,
    required bool approve,
    String? notes,
  }) async {
    await _dio.post('/loan/$id/assignment-decision', data: {
      'bankerId': bankerId,
      'approve': approve,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<void> approveLoan({
    required String id,
    num? interestRate,
    String? notes,
  }) async {
    await _dio.post('/loan/$id/approve', data: {
      if (interestRate != null) 'interestRate': interestRate,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<void> rejectLoan({
    required String id,
    required String notes,
  }) async {
    await _dio.post('/loan/$id/reject', data: {'notes': notes});
  }

  Future<void> disburseLoan({
    required String id,
    required String referenceId,
    String? notes,
  }) async {
    await _dio.post('/loan/$id/disburse', data: {
      'referenceId': referenceId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<List<LoanTypeOption>> listLoanTypes() async {
    final res = await _dio.get('/loan-types');
    final items = (res.data['data'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => LoanTypeOption.fromMap(e.cast<String, dynamic>()))
        .where((e) => e.id.isNotEmpty)
        .toList();
    return items;
  }

  Future<List<BankerOption>> listBankers() async {
    final res = await _dio.get('/admin/users', queryParameters: {
      'role': 'BANKER',
      'status': 'ACTIVE',
      'limit': 100,
      'page': 1,
    });

    final data = (res.data['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final users = (data['users'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => BankerOption.fromMap(e.cast<String, dynamic>()))
        .where((e) => e.id.isNotEmpty)
        .toList();
    return users;
  }

  Future<List<BankOption>> listBanks() async {
    final res = await _dio.get('/banks');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map && raw['data'] is List)
            ? (raw['data'] as List)
            : const <dynamic>[];

    return list
        .whereType<Map>()
        .map((e) => BankOption.fromMap(e.cast<String, dynamic>()))
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  Future<void> createLoanType({
    required String name,
    String? code,
    String? description,
    required num interestRate,
    int? minTenure,
    int? maxTenure,
    num? minAmount,
    num? maxAmount,
    List<String>? bankIds,
    Map<String, dynamic>? schema,
    List<String>? requiredDocuments,
  }) async {
    await _dio.post('/loan-types', data: {
      'name': name,
      if (code != null && code.isNotEmpty) 'code': code,
      if (description != null && description.isNotEmpty) 'description': description,
      'interestRate': interestRate,
      if (minTenure != null) 'minTenure': minTenure,
      if (maxTenure != null) 'maxTenure': maxTenure,
      if (minAmount != null) 'minAmount': minAmount,
      if (maxAmount != null) 'maxAmount': maxAmount,
      if (bankIds != null && bankIds.isNotEmpty) 'bankIds': bankIds,
      'schema': schema ?? <String, dynamic>{},
      'requiredDocuments': requiredDocuments ?? const <String>[],
    });
  }

  Future<void> deleteLoanType(String id) async {
    await _dio.delete('/loan-types/$id');
  }

  Future<void> createBank({
    required String name,
    List<String>? loanTypeIds,
  }) async {
    await _dio.post('/admin/banks', data: {
      'name': name,
      if (loanTypeIds != null && loanTypeIds.isNotEmpty) 'loanTypeIds': loanTypeIds,
    });
  }

  Future<void> deleteBank(String id) async {
    await _dio.delete('/admin/banks/$id');
  }
}

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepository(ref.read(apiClientProvider));
});

final dashboardLoanSnapshotProvider = FutureProvider<LoanListResult>((ref) async {
  return ref.read(loanRepositoryProvider).listLoans(page: 1, limit: 100);
});
