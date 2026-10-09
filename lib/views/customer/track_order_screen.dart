import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/seller_order_model.dart';
import '../../services/grocery_service.dart';
import 'widgets/cancel_order_dialog.dart';
import 'widgets/collect_order_button.dart';

class TrackOrderScreen extends StatelessWidget {
  final String orderId;

  const TrackOrderScreen({
    super.key,
    this.orderId = '#FP-2028-0142',
  });

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  /// "October 15 2026"
  static String _formatDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day} ${date.year}';
  }

  /// How many of the five steps are finished for each order status:
  ///   Pending          -> 1  (Order Placed)
  ///   Preparing        -> 2  (+ Order Confirmed)
  ///   Ready for Pickup -> 4  (+ Order Prepared, Ready for Pickup)
  ///   Completed        -> 5  (+ Pickup Order)
  /// A cancelled order stays at 1.
  static int _stepsDone(String status) {
    switch (status) {
      case 'Preparing':
        return 2;
      case 'Ready for Pickup':
        return 4;
      case 'Completed':
        return 5;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listening to GroceryService makes this screen follow the order live:
    // when the shop changes the status, the steps below update by themselves.
    final groceryService = GroceryService();
    return ListenableBuilder(
      listenable: groceryService,
      builder: (context, _) =>
          _buildScreen(context, groceryService.orderById(orderId)),
    );
  }

  /// Shown when the order number is not in the list (for example the order was
  /// removed), instead of made-up order details.
  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Track Order',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 14),
              Text(
                'We could not find this order',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Order $orderId is not in your orders. It may have been removed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF868889),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(BuildContext context, StoreOrder? order) {
    if (order == null) return _buildNotFound(context);

    final cancelled = order.status == 'Cancelled';
    final stepsDone = _stepsDone(order.status);
    final placedOn = _formatDate(order.createdAt);

    // Text under each step: the date for the first, then Done, the step
    // being worked on, and Pending for the rest.
    String stepNote(int index) {
      if (index == 0) return placedOn;
      if (cancelled) return 'Cancelled';
      if (index < stepsDone) return index == 4 ? 'Collected' : 'Done';
      if (index == stepsDone) {
        // The step the order is on right now, in words that say what is happening.
        switch (index) {
          case 1:
            return 'Waiting for the shop to accept';
          case 2:
            return 'The shop is packing your order';
          case 4:
            return 'Ready now. Collect it at the shop (${order.pickupLabel()})';
          default:
            return 'In progress';
        }
      }
      return 'Pending';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Track Order',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Order Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.brandGreenSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.brandGreen,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order $orderId',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Placed on $placedOn\n${order.itemsSummary}\n'
                                  '${order.formattedTotal}  •  ${order.paymentMethod}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF868889),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Shown instead of progress when the shop cancelled.
                    if (cancelled)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cancel_outlined,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                order.cancelledByCustomer
                                    ? 'You cancelled this order.'
                                    : 'This order was cancelled by the shop.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Vertical Stepper Timeline, filled in from the order's
                    // current status.
                    _buildTimelineStep(
                      icon: Icons.receipt_long_outlined,
                      title: 'Order Placed',
                      subtitle: stepNote(0),
                      isCompleted: stepsDone > 0,
                      isFirst: true,
                    ),
                    _buildTimelineStep(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Order Confirmed',
                      subtitle: stepNote(1),
                      isCompleted: stepsDone > 1,
                    ),
                    _buildTimelineStep(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Order Prepared',
                      subtitle: stepNote(2),
                      isCompleted: stepsDone > 2,
                    ),
                    _buildTimelineStep(
                      icon: Icons.storefront_outlined,
                      title: 'Ready for Pickup',
                      subtitle: stepNote(3),
                      isCompleted: stepsDone > 3,
                    ),
                    _buildTimelineStep(
                      icon: Icons.done_all_rounded,
                      title: 'Pickup Order',
                      subtitle: stepNote(4),
                      isCompleted: stepsDone > 4,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Order Confirmed Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The customer can cancel until the shop has finished packing.
                  if (GroceryService().canCustomerCancel(order)) ...[
                    CancelOrderButton(orderId: orderId),
                    const SizedBox(height: 12),
                  ],
                  // Once the shop says it is ready, the customer confirms they
                  // collected it, which completes the order.
                  if (GroceryService().canCustomerConfirmPickup(order)) ...[
                    CollectOrderButton(orderId: orderId),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          cancelled ? 'Back' : 'Order Confirmed',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stepper Circle & Connector Line
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.brandGreen : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.brandGreen : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isCompleted ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isCompleted ? AppColors.brandGreen : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Step text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w600,
                    color: isCompleted ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF868889),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
