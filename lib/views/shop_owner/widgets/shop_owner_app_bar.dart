import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../models/owner_profile.dart';
import 'owner_avatar.dart';

/// Header used on the four main tabs: the profile icon on the left (opens
/// the owner's "My Profile" screen) and the notification bell (with the
/// unread count) on the right.
class ShopOwnerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ShopOwnerAppBar({
    super.key,
    required this.owner,
    required this.onProfile,
    required this.onNotifications,
    this.unreadCount = 0,
  });

  /// The logged-in owner. Their photo replaces the person icon once set.
  final OwnerProfile owner;

  /// Called when the profile icon is tapped.
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  /// Number shown on the bell. Hidden while it is 0.
  final int unreadCount;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      backgroundColor: ShopColors.background,
      foregroundColor: ShopColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      // 8 here plus 8 of padding inside keeps the icon 16 from the edge
      // while giving it a 48 x 48 touch area.
      titleSpacing: 8,
      title: Tooltip(
        message: 'My profile',
        child: InkResponse(
          onTap: onProfile,
          radius: 24,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: OwnerAvatar(owner: owner),
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: onNotifications,
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
            child: const Icon(
              Icons.notifications_none,
              color: ShopColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}

/// Header for screens opened on top of the tabs: a back arrow and a title.
class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DetailAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ShopColors.background,
      foregroundColor: ShopColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      title: Text(title, style: ShopText.title),
      actions: actions,
    );
  }
}
