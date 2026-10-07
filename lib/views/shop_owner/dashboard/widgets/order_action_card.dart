import 'package:flutter/material.dart';

import '../../../../core/theme/shop_owner_theme.dart';
import '../../../../core/formatters.dart';
import '../../../../models/shop_order.dart';
import '../../chat/shop_owner_chat_screen.dart';
import '../../widgets/button_spinner.dart';
import '../../widgets/status_pill.dart';

/// One order that still needs work, with the single next step as its main
/// button: "Start Preparing" for new orders, "Mark Ready for Pickup" for
/// orders being prepared.
class OrderActionCard extends StatelessWidget {
  const OrderActionCard({
    super.key,
    required this.order,
    required this.now,
    required this.busy,
    required this.onViewDetails,
    required this.onPrimaryAction,
  });

  final ShopOrder order;

  /// Passed in so every card on screen uses the same clock.
  final DateTime now;

  /// True while this order's status change is being saved.
  final bool busy;
  final VoidCallback onViewDetails;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final isPreparing = order.status == OrderStatus.preparing;
    final accent = StatusColors.of(order.status).accent;

    return Container(
      decoration: ShopDecor.card(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '#${order.orderNumber}',
                                  style: ShopText.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _Chip(order.itemCountLabel),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.customerName,
                            style: ShopText.bodyStrong,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // How the order is paid: "Paid Online" or
                          // "Pay at Store".
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                order.isPaidOnline
                                    ? Icons.credit_card
                                    : Icons.payments_outlined,
                                size: 12,
                                color: order.isPaidOnline
                                    ? ShopColors.primary
                                    : ShopColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order.paymentLabel,
                                style: ShopText.label.copyWith(
                                  color: order.isPaidOnline
                                      ? ShopColors.primary
                                      : ShopColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(status: order.status),
                  ],
                ),
                const SizedBox(height: 8),
                PickupStrip(pickupTime: order.pickupTime, now: now),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Tooltip(
                      message: 'View order details',
                      child: Material(
                        color: ShopColors.surfaceMid,
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onViewDetails,
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 20,
                              color: ShopColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Chat with ${order.customerName}',
                      child: Material(
                        color: const Color(0xFFE8F6EB),
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShopOwnerChatScreen(
                                  customerName: order.customerName,
                                  customerPhone: order.customerPhone,
                                  orderId: '#${order.orderNumber}',
                                  orderItemSummary: order.itemCountLabel,
                                  orderPickupSlot: 'Pickup Slot: ${order.pickupTime}',
                                  orderStatusLabel: order.status.name.toUpperCase(),
                                ),
                              ),
                            );
                          },
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 19,
                              color: ShopColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: busy ? null : onPrimaryAction,
                          style: ShopDecor.primaryButton(
                            color: isPreparing
                                ? ShopColors.secondary
                                : ShopColors.primaryButton,
                          ),
                          child: busy
                              ? const ButtonSpinner()
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isPreparing) ...[
                                      const Icon(
                                        Icons.check_circle_outline,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Flexible(
                                      child: Text(
                                        isPreparing
                                            ? 'Mark Ready for Pickup'
                                            : 'Start Preparing',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Coloured bar down the left edge of the card.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: ColoredBox(
              color: accent,
              child: const SizedBox(width: 4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ShopColors.surfaceMid,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: ShopText.label),
    );
  }
}

/// "Pickup Slot: Today, 4:00 PM ........ in 35m"
class PickupStrip extends StatelessWidget {
  const PickupStrip({super.key, required this.pickupTime, required this.now});

  final DateTime pickupTime;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final countdown = pickupCountdown(pickupTime, now: now);
    final Color countdownColor;
    if (countdown.isUrgent) {
      countdownColor = ShopColors.error;
    } else if (countdown.urgency == PickupUrgency.soon) {
      countdownColor = ShopColors.primary;
    } else {
      countdownColor = ShopColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: ShopDecor.tile(),
      child: Row(
        children: [
          const Icon(Icons.alarm, size: 16, color: ShopColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Pickup Slot: ${formatPickupSlot(pickupTime, now: now)}',
              style: ShopText.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            countdown.label,
            style: ShopText.label.copyWith(color: countdownColor),
          ),
        ],
      ),
    );
  }
}
