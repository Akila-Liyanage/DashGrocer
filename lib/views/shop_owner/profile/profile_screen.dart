import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../services/shop_store.dart';
import '../shop_actions.dart';
import '../widgets/dialogs.dart';
import '../widgets/shop_owner_app_bar.dart';
import 'edit_store_info_screen.dart';
import 'operating_hours_screen.dart';
import 'pickup_slots_screen.dart';
import 'support_sheet.dart';

/// Shop Owner Profile: store information, settings and log out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.store,
    required this.actions,
    required this.onOpenNotifications,
    required this.onOpenUserProfile,
    required this.onLogout,
  });

  final ShopStore store;
  final ShopActions actions;
  final VoidCallback onOpenNotifications;

  /// Opens the owner's "My Profile" screen (the profile icon in the header).
  final VoidCallback onOpenUserProfile;

  /// Called after the owner confirms logging out.
  final VoidCallback onLogout;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      shopRoute<void>((context) => screen),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You will stop receiving new order alerts on this phone '
          'until you log in again.',
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (confirmed) onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, child) {
        final shop = store.shop;

        return Scaffold(
          appBar: ShopOwnerAppBar(
            owner: store.owner,
            onProfile: onOpenUserProfile,
            onNotifications: onOpenNotifications,
            unreadCount: store.unreadAlertCount,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // ------------------------------------------- store information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: ShopDecor.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: ShopColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Store Information',
                            style: ShopText.title,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _push(
                            context,
                            EditStoreInfoScreen(store: store, actions: actions),
                          ),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.storefront_outlined,
                      caption: 'STORE NAME',
                      lines: [shop.name],
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.location_on_outlined,
                      caption: 'PICKUP STAGING ADDRESS',
                      lines: [
                        shop.address.isEmpty ? 'Not set yet' : shop.address,
                      ],
                      note: shop.addressNote,
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.call,
                      caption: 'STORE INQUIRIES & SUPPORT',
                      lines: [
                        [shop.phone, shop.mobile]
                            .where((number) => number.isNotEmpty)
                            .join('  •  '),
                      ],
                      emptyText: 'No phone number set yet',
                      highlight: true,
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.schedule,
                      caption: 'OPEN HOURS',
                      lines: [
                        'Mon – Sat    ${shop.weekdayHoursLabel}',
                        'Sunday        ${shop.sundayHoursLabel}',
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---------------------------------------------------- settings
              Container(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                decoration: ShopDecor.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune,
                            size: 20,
                            color: ShopColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text('Settings', style: ShopText.title),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SettingRow(
                      icon: Icons.event_note_outlined,
                      title: 'Pickup Slot Management & Capacity',
                      subtitle: '${shop.slotMinutes} min slots, up to '
                          '${shop.maxOrdersPerSlot} orders each',
                      onTap: () => _push(
                        context,
                        PickupSlotsScreen(store: store, actions: actions),
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.volume_up_outlined,
                      title: 'Order Notification',
                      subtitle: shop.orderNotifications
                          ? 'New order alerts are on'
                          : 'New order alerts are off',
                      trailing: Switch(
                        value: shop.orderNotifications,
                        onChanged: (value) => actions.saveShop(
                          context,
                          shop.copyWith(orderNotifications: value),
                          success: value
                              ? 'New order alerts turned on.'
                              : 'New order alerts turned off.',
                        ),
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.more_time,
                      title: 'Store Operating Hours',
                      subtitle: 'Mon – Sat ${shop.weekdayHoursLabel}',
                      onTap: () => _push(
                        context,
                        OperatingHoursScreen(store: store, actions: actions),
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.support_agent,
                      title: 'Support',
                      subtitle: 'How the app works and who to contact',
                      onTap: () => showSupportSheet(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ----------------------------------------------------- log out
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ShopColors.errorContainer,
                    foregroundColor: ShopColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: ShopText.subtitle,
                  ),
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Log Out of Merchant Account'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pale block inside the Store Information card.
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.caption,
    required this.lines,
    this.note = '',
    this.emptyText = '',
    this.highlight = false,
  });

  final IconData icon;
  final String caption;
  final List<String> lines;

  /// Smaller grey line under the main lines.
  final String note;

  /// Shown instead when every line is empty.
  final String emptyText;

  /// Shows the lines in green, used for phone numbers.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final shown = lines.where((line) => line.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShopDecor.tile(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ShopColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caption, style: ShopText.label),
                const SizedBox(height: 2),
                if (shown.isEmpty)
                  Text(emptyText, style: ShopText.body)
                else
                  for (final line in shown)
                    Text(
                      line,
                      style: ShopText.subtitle.copyWith(
                        color: highlight
                            ? ShopColors.primary
                            : ShopColors.textPrimary,
                      ),
                    ),
                if (note.isNotEmpty) Text(note, style: ShopText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in the Settings card. Rows with [onTap] show an arrow; rows with
/// a [trailing] widget (the switch) show that instead.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: ShopDecor.tile(color: ShopColors.surfaceMid),
                child: Icon(icon, size: 18, color: ShopColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ShopText.subtitle),
                    Text(subtitle, style: ShopText.body),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: ShopColors.textSecondary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
