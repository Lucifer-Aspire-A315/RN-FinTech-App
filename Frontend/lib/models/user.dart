// lib/src/models/user.dart
import 'package:collection/collection.dart';
import 'user_role.dart';
import 'role_profiles.dart';

class User {
  final String id;
  final String email;
  final UserRole role;
  final String name;
  final String? phone;
  final DateTime? createdAt;
  final RoleData? roleData; // role-specific profile

  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.phone,
    this.createdAt,
    this.roleData,
  });

  factory User.fromMap(Map<String, dynamic> m) {
    final roleStr = (m['role'] ?? m['user_role'] ?? '').toString();
    final role = userRoleFromString(roleStr);
    RoleData? roleData;

    // Try to extract role-specific map from top-level keys or nested 'profile'
    final roleMap = (m['profile'] is Map) ? Map<String,dynamic>.from(m['profile']) : Map<String,dynamic>.from(m);

    if (role == UserRole.customer) {
      roleData = CustomerProfile.fromMap(roleMap);
    } else if (role == UserRole.merchant) {
      roleData = MerchantProfile.fromMap(roleMap);
    } else if (role == UserRole.banker) {
      roleData = BankerProfile.fromMap(roleMap);
    }

    return User(
      id: (m['id'] ?? m['_id'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      role: role,
      name: (m['name'] ?? '').toString(),
      phone: m['phone']?.toString(),
      createdAt: m['createdAt'] != null ? DateTime.tryParse(m['createdAt'].toString()) : null,
      roleData: roleData,
    );
  }

  Map<String, dynamic> toMap() {
    final out = <String, dynamic>{
      'id': id,
      'email': email,
      'role': role.toString().split('.').last.toUpperCase(),
      'name': name,
      if (phone != null) 'phone': phone,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };

    if (roleData != null) {
      if (roleData is CustomerProfile) out['profile'] = (roleData as CustomerProfile).toMap();
      if (roleData is MerchantProfile) out['profile'] = (roleData as MerchantProfile).toMap();
      if (roleData is BankerProfile) out['profile'] = (roleData as BankerProfile).toMap();
    }

    return out;
  }

  User copyWith({
    String? id,
    String? email,
    UserRole? role,
    String? name,
    String? phone,
    DateTime? createdAt,
    RoleData? roleData,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      roleData: roleData ?? this.roleData,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && const DeepCollectionEquality().equals(toMap(), other.toMap());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toMap());
}
