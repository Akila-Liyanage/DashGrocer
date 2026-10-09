import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/grocery_service.dart';
import '../../services/review_service.dart';
import 'track_order_screen.dart';

class _NotificationStyle {
  final IconData icon;
  final Color color;
  final Color background;

  const _NotificationStyle(this.icon, this.color, this.background);
}

/// Icon and colour that say what kind of notification this is.
_NotificationStyle _styleFor(String title) {
  if (title.startsWith('Order Cancelled')) {
    return const _NotificationStyle(Icons.cancel_rounded, Color(0xFFDC2626), Color(0xFFFEE2E2));
  }
  if (title.startsWith('Order Ready')) {
    return const _NotificationStyle(Icons.storefront_rounded, AppColors.brandGreenDark, Color(0xFFE8F6EB));
  }
  if (title.startsWith('Order Accepted')) {
    return const _NotificationStyle(Icons.inventory_2_rounded, Color(0xFF0284C7), Color(0xFFE0F2FE));
  }
  if (title.startsWith('Order Completed') || title.startsWith('Order Collected')) {
    return const _NotificationStyle(Icons.done_all_rounded, Color(0xFF475569), Color(0xFFF1F5F9));
  }
  return const _NotificationStyle(Icons.check_circle_rounded, AppColors.brandGreen, Color(0xFFE8F6EB));
}

class CustomerNotificationsSheet extends StatelessWidget {
  const CustomerNotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GroceryService(),
      builder: (context, _) {
        final groceryService = GroceryService();
        final notifications = groceryService.customerNotifications;

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.brandGreen,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Notifications',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    if (notifications.any((n) => !n.isRead))
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          groceryService.markAllCustomerNotificationsAsRead();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            'Mark read',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandGreen,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'No notifications yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your order updates will appear here.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const Divider(
                        color: Color(0xFFF1F5F9),
                        height: 18,
                        thickness: 1,
                      ),
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            // Opening a notification marks it as read
                            groceryService.markCustomerNotificationRead(notif.id);
                            if (notif.orderId != null) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TrackOrderScreen(orderId: notif.orderId!),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _styleFor(notif.title).background,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _styleFor(notif.title).icon,
                                    color: _styleFor(notif.title).color,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: notif.isRead
                                                    ? const Color(0xFF475569)
                                                    : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            // Worked out from the time it was sent, so it keeps moving on
                                            ReviewService.timeAgo(notif.time),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        notif.message,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          height: 1.35,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
