import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/grocery_service.dart';

/// Asks "Did you collect your order?" and, if yes, marks it as collected.
/// Returns true when the order was marked as collected.
Future<bool> confirmOrderCollected(BuildContext context, String orderId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Did you collect your order?',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1E293B),
        ),
      ),
      content: Text(
        'Order $orderId will be marked as collected and the shop will be told. '
        'Only confirm once you have the groceries with you.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: const Color(0xFF64748B),
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            'Not yet',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            'Yes, collected',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final done = GroceryService().confirmPickupByCustomer(orderId);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        done
            ? 'Thank you! Order $orderId is marked as collected.'
            : 'This order is not ready for pickup yet.',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      ),
      backgroundColor: done ? AppColors.brandGreenDark : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
  return done;
}

/// Green "I collected my order" button for orders that are ready for pickup.
class CollectOrderButton extends StatelessWidget {
  final String orderId;
  final bool compact;

  const CollectOrderButton({super.key, required this.orderId, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 42 : 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 10 : 12)),
        ),
        onPressed: () => confirmOrderCollected(context, orderId),
        icon: const Icon(Icons.done_all_rounded, size: 18),
        label: Text(
          'I collected my order',
          style: GoogleFonts.plusJakartaSans(
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
