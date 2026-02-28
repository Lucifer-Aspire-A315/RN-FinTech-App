import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

class UploadSignature {
  final String uploadUrl;
  final String publicId;
  final String apiKey;
  final String signature;
  final int timestamp;
  final String? folder;

  const UploadSignature({
    required this.uploadUrl,
    required this.publicId,
    required this.apiKey,
    required this.signature,
    required this.timestamp,
    this.folder,
  });

  factory UploadSignature.fromMap(Map<String, dynamic> map) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return UploadSignature(
      uploadUrl: map['uploadUrl']?.toString() ?? '',
      publicId: map['public_id']?.toString() ?? map['publicId']?.toString() ?? '',
      apiKey: map['apiKey']?.toString() ?? '',
      signature: map['signature']?.toString() ?? '',
      timestamp: toInt(map['timestamp']),
      folder: map['folder']?.toString(),
    );
  }
}

class UploadedAsset {
  final String publicId;
  final String secureUrl;
  final String originalFilename;
  final int bytes;
  final String? format;

  const UploadedAsset({
    required this.publicId,
    required this.secureUrl,
    required this.originalFilename,
    required this.bytes,
    this.format,
  });

  factory UploadedAsset.fromMap(Map<String, dynamic> map) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return UploadedAsset(
      publicId: map['public_id']?.toString() ?? '',
      secureUrl: map['secure_url']?.toString() ?? '',
      originalFilename: map['original_filename']?.toString() ?? '',
      bytes: toInt(map['bytes']),
      format: map['format']?.toString(),
    );
  }
}

class UploadRepository {
  final Dio _apiDio;
  final Dio _externalDio;

  const UploadRepository(this._apiDio, this._externalDio);

  Future<UploadSignature> getSignature({
    required String folder,
    String? filename,
  }) async {
    final res = await _apiDio.get('/uploads/sign', queryParameters: {
      'folder': folder,
      if (filename != null && filename.isNotEmpty) 'filename': filename,
    });
    final map = (res.data as Map).cast<String, dynamic>();
    return UploadSignature.fromMap(map);
  }

  Future<UploadedAsset> uploadToCloudinary({
    required UploadSignature signature,
    required Uint8List bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'api_key': signature.apiKey,
      'timestamp': signature.timestamp,
      'signature': signature.signature,
      'public_id': signature.publicId,
      if (signature.folder != null && signature.folder!.isNotEmpty)
        'folder': signature.folder,
    });

    final res = await _externalDio.post(
      signature.uploadUrl,
      data: form,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    final map = (res.data as Map).cast<String, dynamic>();
    return UploadedAsset.fromMap(map);
  }

  Future<void> registerLoanDocument({
    required String loanId,
    required String publicId,
    required String secureUrl,
    required String filename,
    required String fileType,
    required int bytes,
    required String type,
  }) async {
    await _apiDio.post('/uploads/loan/$loanId/register', data: {
      'publicId': publicId,
      'secureUrl': secureUrl,
      'filename': filename,
      'fileType': fileType,
      'bytes': bytes,
      'type': type,
    });
  }
}

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  final external = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  return UploadRepository(ref.read(apiClientProvider), external);
});
