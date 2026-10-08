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
  final String? shopStatus;
  final String? rejectionReason;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.shopName,
    this.shopAddress,
    this.shopStatus,
    this.rejectionReason,
    this.createdAt,
  });

  bool get isCustomer => role == UserRole.customer;
  bool get isShopOwner => role == UserRole.shopOwner;
  bool get isAdmin => role == UserRole.admin;

  bool get isShopPending => role == UserRole.shopOwner && (shopStatus == 'pending' || shopStatus == null);
  bool get isShopApproved => role == UserRole.shopOwner && shopStatus == 'approved';
  bool get isShopRejected => role == UserRole.shopOwner && shopStatus == 'rejected';

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    String? shopName,
    String? shopAddress,
    String? shopStatus,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopStatus: shopStatus ?? this.shopStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'shopName': shopName,
      'shopAddress': shopAddress,
      'shopStatus': shopStatus,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? id]) {
    final roleStr = (map['role'] as String? ?? 'customer').toLowerCase();
    UserRole role;
    if (roleStr.contains('owner') || roleStr.contains('seller') || roleStr.contains('shop')) {
      role = UserRole.shopOwner;
    } else if (roleStr.contains('admin')) {
      role = UserRole.admin;
    } else {
      role = UserRole.customer;
    }

    DateTime? parsedCreatedAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is DateTime) {
        parsedCreatedAt = map['createdAt'] as DateTime;
      } else {
        parsedCreatedAt = DateTime.tryParse(map['createdAt'].toString());
      }
    }

    return UserModel(
      id: id ?? (map['id'] as String? ?? 'user_${DateTime.now().millisecondsSinceEpoch}'),
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      role: role,
      shopName: map['shopName'] as String?,
      shopAddress: map['shopAddress'] as String?,
      shopStatus: map['shopStatus'] as String? ?? (role == UserRole.shopOwner ? 'approved' : null),
      rejectionReason: map['rejectionReason'] as String?,
      createdAt: parsedCreatedAt,
    );
  }
}
