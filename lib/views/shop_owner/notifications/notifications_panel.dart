import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../core/formatters.dart';
import '../../../models/shop_alert.dart';
import '../../../models/shop_order.dart';
import '../../../services/shop_store.dart';
import '../shop_actions.dart';

/// Opens the notifications panel as a floating card under the header.
///
/// [onOpenOrder] and [onOpenSettings] are called after the panel closes.
Future<void> showNotificationsPanel(
  BuildContext context, {
  required ShopStore store,
  required ShopActions actions,
  required ValueChanged<ShopOrder> onOpenOrder,
  required VoidCallback onOpenSettings,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _NotificationsPanel(
      store: store,
      actions: actions,
      onOpenOrder: (order) {
        Navigator.of(dialogContext).pop();
        onOpenOrder(order);
      },
      onOpenSettings: () {
        Navigator.of(dialogContext).pop();
        onOpenSettings();
      },
    ),
  );
}

class _NotificationsPanel extends StatelessWidget {
  const _NotificationsPanel({
    required this.store,
    required this.actions,
    required this.onOpenOrder,
    required this.onOpenSettings,
  });

  final ShopStore store;
  final ShopActions actions;
  final ValueChanged<ShopOrder> onOpenOrder;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
      backgroundColor: ShopColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        // Listening to the store keeps the list live while the panel is open.
        child: ListenableBuilder(
          listenable: store,
          builder: (context, child) {
            final alerts = store.alerts;
            final unread = alerts.where((alert) => alert.unread).length;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Text('Notifications', style: ShopText.title),
                      const SizedBox(width: 8),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ShopColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$unread New',
                            style: ShopText.label.copyWith(color: Colors.white),
                          ),
                        ),
                      const Spacer(),
                      if (unread > 0)
                        TextButton(
                          onPressed: actions.markAlertsRead,
                          child: const Text('Mark all read'),
                        ),
                      IconButton(
                        tooltip: 'Close notifications',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
                if (alerts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          size: 32,
                          color: ShopColors.secondary,
                        ),
                        const SizedBox(height: 8),
                        Text('You are all caught up', style: ShopText.subtitle),
                        Text(
                          'New orders and low stock warnings appear here.',
                          style: ShopText.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      itemCount: alerts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        final order = alert.order;
                        final product = alert.product;
                        return _AlertTile(
                          alert: alert,
                          onTap: order == null
                              ? null
                              : () => onOpenOrder(order),
                          busy: product != null && store.isBusy(product.id),
                          onRestock: product == null
                              ? null
                              : () => actions.addStock(
                                    context,
                                    product,
                                    ShopActions.quickAddAmount,
                                  ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      style: ShopDecor.tonalButton(radius: 12),
                      onPressed: onOpenSettings,
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Notification Settings'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    required this.onTap,
    required this.onRestock,
    required this.busy,
  });

  final ShopAlert alert;

  /// Opens the order. Null for stock alerts.
  final VoidCallback? onTap;

  /// Adds stock. Null for order alerts.
  final VoidCallback? onRestock;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconBackground;
    final Color iconColor;
    if (alert.type == ShopAlertType.newOrder) {
      icon = Icons.shopping_bag_outlined;
      iconBackground = ShopColors.greenContainer;
      iconColor = ShopColors.onGreenContainer;
    } else if (alert.type == ShopAlertType.pickupDue) {
      icon = Icons.timer_outlined;
      iconBackground = ShopColors.errorContainer;
      iconColor = ShopColors.error;
    } else {
      icon = Icons.inventory_2_outlined;
      iconBackground = ShopColors.warningContainer;
      iconColor = ShopColors.onWarningContainer;
    }

    final time = alert.time;
    final restock = onRestock;

    return Material(
      // Unread alerts are tinted; read ones are plain white.
      color: alert.unread ? ShopColors.surfaceLow : ShopColors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (alert.unread)
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: 6),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: ShopColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(alert.title, style: ShopText.subtitle),
                        ),
                        if (time != null) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(timeAgo(time), style: ShopText.label),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(alert.body, style: ShopText.body),
                    if (restock != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: ShopColors.surfaceMid,
                            foregroundColor: ShopColors.primary,
                            disabledBackgroundColor: ShopColors.surfaceHigh,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: ShopText.bodyStrong,
                          ),
                          onPressed: busy ? null : restock,
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: Text(
                            busy
                                ? 'Adding...'
                                : 'Restock +${ShopActions.quickAddAmount}',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
