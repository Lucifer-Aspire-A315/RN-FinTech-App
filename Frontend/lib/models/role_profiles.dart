// lib/src/models/role_profiles.dart
class RoleData {
  const RoleData();
}

class CustomerProfile extends RoleData {
  final String? kycStatus; // example
  final Map<String, dynamic>? extras;
  const CustomerProfile({this.kycStatus, this.extras});

  factory CustomerProfile.fromMap(Map<String, dynamic> m) {
    return CustomerProfile(
      kycStatus: m['kycStatus']?.toString(),
      extras: Map<String, dynamic>.from(m)..removeWhere((k,_) => k == 'kycStatus'),
    );
  }

  Map<String, dynamic> toMap() => {
    if (kycStatus != null) 'kycStatus': kycStatus,
    if (extras != null) ...?extras,
  };
}

class MerchantProfile extends RoleData {
  final String businessName;
  final String? businessReg;
  final String? gstin;
  final String? address;
  final Map<String, dynamic>? extras;

  const MerchantProfile({
    required this.businessName,
    this.businessReg,
    this.gstin,
    this.address,
    this.extras,
  });

  factory MerchantProfile.fromMap(Map<String, dynamic> m) {
    return MerchantProfile(
      businessName: (m['businessName'] ?? m['business_name'] ?? '').toString(),
      businessReg: (m['businessReg'] ?? m['business_reg'])?.toString(),
      gstin: m['gstin']?.toString(),
      address: m['address']?.toString(),
      extras: Map<String, dynamic>.from(m)..removeWhere((k,_) => ['businessName','business_name','businessReg','business_reg','gstin','address'].contains(k)),
    );
  }

  Map<String, dynamic> toMap() => {
    'businessName': businessName,
    if (businessReg != null) 'businessReg': businessReg,
    if (gstin != null) 'gstin': gstin,
    if (address != null) 'address': address,
    if (extras != null) ...?extras,
  };
}

class BankerProfile extends RoleData {
  final String employeeId;
  final String bankName;
  final String? branch;
  final Map<String, dynamic>? extras;

  const BankerProfile({
    required this.employeeId,
    required this.bankName,
    this.branch,
    this.extras,
  });

  factory BankerProfile.fromMap(Map<String, dynamic> m) {
    return BankerProfile(
      employeeId: (m['employeeId'] ?? m['employee_id'] ?? '').toString(),
      bankName: (m['bankName'] ?? m['bank_name'] ?? '').toString(),
      branch: m['branch']?.toString(),
      extras: Map<String, dynamic>.from(m)..removeWhere((k,_) => ['employeeId','employee_id','bankName','bank_name','branch'].contains(k)),
    );
  }

  Map<String, dynamic> toMap() => {
    'employeeId': employeeId,
    'bankName': bankName,
    if (branch != null) 'branch': branch,
    if (extras != null) ...?extras,
  };
}
