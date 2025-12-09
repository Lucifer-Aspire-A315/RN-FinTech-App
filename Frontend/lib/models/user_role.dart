// lib/src/models/user_role.dart
enum UserRole {
  customer,
  merchant,
  banker,
  admin,
  unknown,
}

UserRole userRoleFromString(String? s) {
  if (s == null) return UserRole.unknown;
  final v = s.toLowerCase();
  if (v == 'customer') return UserRole.customer;
  if (v == 'merchant') return UserRole.merchant;
  if (v == 'banker') return UserRole.banker;
  if (v == 'admin') return UserRole.admin;
  return UserRole.unknown;
}
