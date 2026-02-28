import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/kyc/kyc_models.dart';
import 'api_client.dart';

class KycRepository {
  final Dio _apiDio;
  final Dio _externalDio;

  const KycRepository(this._apiDio, this._externalDio);

  Future<List<KycRequiredDocument>> getRequiredDocuments({String? loanType}) async {
    final res = await _apiDio.get('/kyc/required', queryParameters: {
      if (loanType != null && loanType.isNotEmpty) 'loanType': loanType,
    });
    final root = (res.data as Map).cast<String, dynamic>();
    final data = (root['data'] is Map)
        ? (root['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final list = (data['requiredDocuments'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => KycRequiredDocument.fromMap(e.cast<String, dynamic>()))
        .toList();
    return list;
  }

  Future<KycStatusResponse> getStatus({String? status}) async {
    final res = await _apiDio.get('/kyc/status', queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
    });
    final root = (res.data as Map).cast<String, dynamic>();
    final data = (root['data'] is Map)
        ? (root['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    final docs = (data['documents'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => KycStatusDocument.fromMap(e.cast<String, dynamic>()))
        .toList();

    final required = (data['requiredDocuments'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => KycRequiredDocument.fromMap(e.cast<String, dynamic>()))
        .toList();

    final completion = (data['completion'] is Map)
        ? (data['completion'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return KycStatusResponse(
      documents: docs,
      requiredDocuments: required,
      percentComplete: toInt(completion['percentComplete']),
      overallStatus: data['overallStatus']?.toString() ?? 'INCOMPLETE',
    );
  }

  Future<KycUploadRequest> createUploadRequest({
    required String docType,
    String? targetUserId,
  }) async {
    final onBehalf = targetUserId != null && targetUserId.isNotEmpty;
    final res = await _apiDio.post(
      onBehalf ? '/kyc/on-behalf/upload-url' : '/kyc/upload-url',
      data: {
        if (onBehalf) 'targetUserId': targetUserId,
        'docType': docType,
      },
    );
    final root = (res.data as Map).cast<String, dynamic>();
    final data = (root['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return KycUploadRequest.fromMap(data);
  }

  Future<Map<String, dynamic>> uploadToCloudinary({
    required KycUploadRequest request,
    required Uint8List bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'api_key': request.apiKey,
      'timestamp': request.timestamp,
      'signature': request.signature,
      'public_id': request.publicId,
      if (request.folder != null && request.folder!.isNotEmpty) 'folder': request.folder,
    });

    final res = await _externalDio.post(
      request.uploadUrl,
      data: form,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    if (res.data is Map) return (res.data as Map).cast<String, dynamic>();
    return <String, dynamic>{};
  }

  Future<void> completeUpload({
    required String kycDocId,
    required String publicId,
    required int fileSize,
    required String contentType,
    String? targetUserId,
  }) async {
    final onBehalf = targetUserId != null && targetUserId.isNotEmpty;
    await _apiDio.post(
      onBehalf ? '/kyc/on-behalf/complete-upload' : '/kyc/complete-upload',
      data: {
        'kycDocId': kycDocId,
        'publicId': publicId,
        'fileSize': fileSize,
        'contentType': contentType,
      },
    );
  }

  Future<List<KycPendingItem>> getPendingForReview({int limit = 20}) async {
    final res = await _apiDio.get('/kyc/pending', queryParameters: {'limit': limit});
    final root = (res.data as Map).cast<String, dynamic>();
    final data = (root['data'] is Map)
        ? (root['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final docs = (data['documents'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => KycPendingItem.fromMap(e.cast<String, dynamic>()))
        .toList();
    return docs;
  }

  Future<KycPendingItem> getForReview(String kycDocId) async {
    final res = await _apiDio.get('/kyc/$kycDocId/review');
    final root = (res.data as Map).cast<String, dynamic>();
    final data = (root['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return KycPendingItem.fromMap(data);
  }

  Future<void> verifyDocument({
    required String kycDocId,
    required bool approved,
    String? notes,
  }) async {
    await _apiDio.post('/kyc/$kycDocId/verify', data: {
      'status': approved ? 'VERIFIED' : 'REJECTED',
      'notes': notes ?? '',
    });
  }
}

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  final external = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  return KycRepository(ref.read(apiClientProvider), external);
});
