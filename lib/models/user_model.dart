enum UserRole {
  customer,
  shopOwner,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.shopOwner:
        return 'Shop Owner';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get description {
    switch (this) {
      case UserRole.customer:
        return 'Order groceries, pick up in-store, review items';
      case UserRole.shopOwner:
        return 'Manage products, update stock, process orders';
      case UserRole.admin:
        return 'Monitor system operations and user accounts';
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final String? shopName;
  final String? shopAddress;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.shopName,
    this.shopAddress,
  });

  bool get isCustomer => role == UserRole.customer;
  bool get isShopOwner => role == UserRole.shopOwner;
  bool get isAdmin => role == UserRole.admin;

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    String? shopName,
    String? shopAddress,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
    );
  }
}
