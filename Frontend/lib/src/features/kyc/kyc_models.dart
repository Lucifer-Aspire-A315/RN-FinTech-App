class KycRequiredDocument {
  final String type;
  final String displayName;
  final bool isRequired;

  const KycRequiredDocument({
    required this.type,
    required this.displayName,
    required this.isRequired,
  });

  factory KycRequiredDocument.fromMap(Map<String, dynamic> map) {
    return KycRequiredDocument(
      type: map['type']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? map['type']?.toString() ?? 'Document',
      isRequired: map['isRequired'] == true,
    );
  }
}

class KycStatusDocument {
  final String id;
  final String type;
  final String status;
  final String? url;
  final String? docTypeName;
  final DateTime? createdAt;

  const KycStatusDocument({
    required this.id,
    required this.type,
    required this.status,
    this.url,
    this.docTypeName,
    this.createdAt,
  });

  factory KycStatusDocument.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return KycStatusDocument(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      status: map['status']?.toString() ?? 'PENDING',
      url: map['url']?.toString(),
      docTypeName: map['docTypeName']?.toString(),
      createdAt: parseDate(map['createdAt']),
    );
  }
}

class KycStatusResponse {
  final List<KycStatusDocument> documents;
  final List<KycRequiredDocument> requiredDocuments;
  final int percentComplete;
  final String overallStatus;

  const KycStatusResponse({
    required this.documents,
    required this.requiredDocuments,
    required this.percentComplete,
    required this.overallStatus,
  });
}

class KycUploadRequest {
  final String uploadUrl;
  final String kycDocId;
  final String publicId;
  final String apiKey;
  final String signature;
  final int timestamp;
  final String? folder;

  const KycUploadRequest({
    required this.uploadUrl,
    required this.kycDocId,
    required this.publicId,
    required this.apiKey,
    required this.signature,
    required this.timestamp,
    this.folder,
  });

  factory KycUploadRequest.fromMap(Map<String, dynamic> map) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return KycUploadRequest(
      uploadUrl: map['uploadUrl']?.toString() ?? '',
      kycDocId: map['kycDocId']?.toString() ?? '',
      publicId: map['publicId']?.toString() ?? map['public_id']?.toString() ?? '',
      apiKey: map['apiKey']?.toString() ?? '',
      signature: map['signature']?.toString() ?? '',
      timestamp: toInt(map['timestamp']),
      folder: map['folder']?.toString(),
    );
  }
}

class KycPendingItem {
  final String id;
  final String type;
  final String status;
  final String? url;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userRole;
  final int daysPending;

  const KycPendingItem({
    required this.id,
    required this.type,
    required this.status,
    this.url,
    this.userId,
    this.userName,
    this.userEmail,
    this.userRole,
    required this.daysPending,
  });

  factory KycPendingItem.fromMap(Map<String, dynamic> map) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final userMap = map['user'] is Map ? (map['user'] as Map).cast<String, dynamic>() : null;

    return KycPendingItem(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      status: map['status']?.toString() ?? 'PENDING',
      url: map['url']?.toString(),
      userId: map['userId']?.toString() ?? userMap?['id']?.toString(),
      userName: map['userFullName']?.toString() ?? userMap?['name']?.toString(),
      userEmail: userMap?['email']?.toString(),
      userRole: map['userRole']?.toString() ?? userMap?['role']?.toString(),
      daysPending: toInt(map['daysPending']),
    );
  }
}

class KycOnBehalfTarget {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;

  const KycOnBehalfTarget({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });

  factory KycOnBehalfTarget.fromMap(Map<String, dynamic> map) {
    return KycOnBehalfTarget(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
    );
  }
}
