import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../models/owner_profile.dart';
import 'product_image.dart';

/// Round picture of the shop owner.
///
/// Shows the owner's photo when there is one. Otherwise it shows the person
/// icon, or the owner's initials when [showInitials] is true.
class OwnerAvatar extends StatelessWidget {
  const OwnerAvatar({
    super.key,
    required this.owner,
    this.radius = 16,
    this.showInitials = false,
  });

  final OwnerProfile owner;
  final double radius;
  final bool showInitials;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    if (owner.hasPhoto) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: ProductImage(
            imageUrl: owner.photoUrl,
            iconSize: radius,
            placeholderIcon: Icons.person_outline,
          ),
        ),
      );
    }

    final initials = owner.initials;
    return CircleAvatar(
      radius: radius,
      backgroundColor: ShopColors.primary,
      child: showInitials && initials.isNotEmpty
          ? Text(
              initials,
              style: ShopText.heading.copyWith(
                color: Colors.white,
                fontSize: radius * 0.75,
                height: 1,
              ),
            )
          : Icon(Icons.person_outline, size: radius * 1.125, color: Colors.white),
    );
  }
}
