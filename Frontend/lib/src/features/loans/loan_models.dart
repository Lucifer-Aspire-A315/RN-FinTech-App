class LoanSummary {
  final String id;
  final String status;
  final num amount;
  final String? applicantId;
  final String? merchantId;
  final String? bankerId;
  final String? loanTypeName;
  final String? applicantName;
  final String? merchantName;
  final String? bankerName;
  final Map<String, dynamic> metadata;
  final List<LoanDocumentItem> documents;
  final DateTime? createdAt;

  const LoanSummary({
    required this.id,
    required this.status,
    required this.amount,
    this.applicantId,
    this.merchantId,
    this.bankerId,
    this.loanTypeName,
    this.applicantName,
    this.merchantName,
    this.bankerName,
    this.metadata = const <String, dynamic>{},
    this.documents = const <LoanDocumentItem>[],
    this.createdAt,
  });

  factory LoanSummary.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    String? nestedName(dynamic value) {
      if (value is Map) return value['name']?.toString();
      return null;
    }

    num parseAmount(dynamic value) {
      if (value is num) return value;
      return num.tryParse(value?.toString() ?? '') ?? 0;
    }

    return LoanSummary(
      id: map['id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'UNKNOWN',
      amount: parseAmount(map['amount']),
      applicantId: map['applicantId']?.toString(),
      merchantId: map['merchantId']?.toString(),
      bankerId: map['bankerId']?.toString(),
      loanTypeName: map['loanType'] is Map
          ? (map['loanType'] as Map)['name']?.toString()
          : null,
      applicantName: nestedName(map['applicant']),
      merchantName: nestedName(map['merchant']),
      bankerName: nestedName(map['banker']),
      metadata: map['metadata'] is Map
          ? (map['metadata'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{},
      documents: (map['documents'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => LoanDocumentItem.fromMap(e.cast<String, dynamic>()))
          .toList(),
      createdAt: parseDate(map['createdAt']),
    );
  }
}

class LoanDocumentItem {
  final String id;
  final String type;
  final String? filename;
  final String? fileType;
  final String? url;
  final DateTime? createdAt;

  const LoanDocumentItem({
    required this.id,
    required this.type,
    this.filename,
    this.fileType,
    this.url,
    this.createdAt,
  });

  factory LoanDocumentItem.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    final resolvedUrl =
        map['url']?.toString() ?? map['secureUrl']?.toString() ?? map['secure_url']?.toString();

    return LoanDocumentItem(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? map['fileType']?.toString() ?? 'attachment',
      filename: map['filename']?.toString(),
      fileType: map['fileType']?.toString(),
      url: resolvedUrl,
      createdAt: parseDate(map['createdAt']),
    );
  }
}

class LoanTypeOption {
  final String id;
  final String name;
  final String? code;
  final String? description;
  final num? interestRate;
  final num? minAmount;
  final num? maxAmount;
  final int? minTenure;
  final int? maxTenure;
  final Map<String, dynamic> schema;
  final List<String> requiredDocuments;

  const LoanTypeOption({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.interestRate,
    this.minAmount,
    this.maxAmount,
    this.minTenure,
    this.maxTenure,
    this.schema = const <String, dynamic>{},
    this.requiredDocuments = const <String>[],
  });

  factory LoanTypeOption.fromMap(Map<String, dynamic> map) {
    num? toNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final rawSchema = map['schema'];
    final schema = rawSchema is Map
        ? rawSchema.cast<String, dynamic>()
        : <String, dynamic>{};

    final requiredDocs = (map['requiredDocuments'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();

    return LoanTypeOption(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Loan Type',
      code: map['code']?.toString(),
      description: map['description']?.toString(),
      interestRate: toNum(map['interestRate']),
      minAmount: toNum(map['minAmount']),
      maxAmount: toNum(map['maxAmount']),
      minTenure: toInt(map['minTenure']),
      maxTenure: toInt(map['maxTenure']),
      schema: schema,
      requiredDocuments: requiredDocs,
    );
  }
}

class LoanListResult {
  final List<LoanSummary> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const LoanListResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class BankerOption {
  final String id;
  final String name;
  final String email;

  const BankerOption({
    required this.id,
    required this.name,
    required this.email,
  });

  factory BankerOption.fromMap(Map<String, dynamic> map) {
    return BankerOption(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Banker',
      email: map['email']?.toString() ?? '',
    );
  }
}

class BankOption {
  final String id;
  final String name;

  const BankOption({
    required this.id,
    required this.name,
  });

  factory BankOption.fromMap(Map<String, dynamic> map) {
    return BankOption(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Bank',
    );
  }
}
