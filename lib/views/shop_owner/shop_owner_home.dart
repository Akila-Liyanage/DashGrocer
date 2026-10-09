import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/theme/shop_owner_theme.dart';
import '../../models/owner_profile.dart';
import '../../models/shop_profile.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_shop_repository.dart';
import '../../services/grocery_shop_repository.dart';
import '../../services/mock_shop_repository.dart';
import '../../services/shop_repository.dart';
import 'shop_owner_shell.dart';

/// Entry point of the shop owner side.
///
/// `main.dart` opens this for every logged-in user whose role is shop owner.
/// It connects the rest of the app to the shop owner screens:
///   - orders and products come from the shared GroceryService, the same one
///     the customer screens use, so both sides see the same data,
///   - the logged-in user's id is the shop id, and their registration details
///     become the starting shop profile and "My Profile",
///   - Log Out calls the shared [AuthService], which returns to login.
class ShopOwnerHome extends StatefulWidget {
  final UserModel user;

  const ShopOwnerHome({
    super.key,
    required this.user,
  });

  @override
  State<ShopOwnerHome> createState() => _ShopOwnerHomeState();
}

class _ShopOwnerHomeState extends State<ShopOwnerHome> {
  late final ShopRepository _repository;

  /// Each owner has one shop, and its id is the owner's user id.
  String get _shopId => widget.user.id;

  @override
  void initState() {
    super.initState();

    final user = widget.user;
    final shopName = user.shopName ?? 'My Grocery Shop';
    final startingShop = ShopProfile(
      id: _shopId,
      name: shopName,
      address: user.shopAddress ?? '',
      phone: user.phoneNumber,
      status: user.shopStatus ?? 'approved',
      ownerName: user.fullName,
      ownerEmail: user.email,
      rejectionReason: user.rejectionReason ?? '',
    );
    final startingOwner = OwnerProfile(
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phoneNumber: user.phoneNumber,
    );

    // Shop settings and the owner's profile are saved in Firestore when
    // Firebase started in main.dart. Otherwise (for example in widget tests)
    // they are kept in memory.
    final firebaseReady = Firebase.apps.isNotEmpty;
    final ShopRepository profiles = firebaseReady
        ? FirestoreShopRepository()
        : MockShopRepository(
            shopId: _shopId,
            shop: startingShop,
            owner: startingOwner,
          );

    _repository = GroceryShopRepository(
      profiles: profiles,
      sellerId: user.id,
      sellerName: shopName,
      fallbackOwner: startingOwner,
    );

    if (firebaseReady) _createShopIfMissing(startingShop, startingOwner);
  }

  Future<void> _createShopIfMissing(
    ShopProfile shop,
    OwnerProfile owner,
  ) async {
    try {
      await _repository.ensureProfiles(shop: shop, owner: owner);
    } catch (error) {
      debugPrint('Could not create the shop profile: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ShopTheme.data,
      child: ShopOwnerShell(
        repository: _repository,
        shopId: _shopId,
        onLogout: () => AuthService().logout(),
      ),
    );
  }
}
