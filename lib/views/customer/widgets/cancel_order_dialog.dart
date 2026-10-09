import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/grocery_service.dart';

const List<String> _cancelReasons = [
  'Changed my mind',
  'Ordered by mistake',
  'Pickup time does not suit me',
  'Found a better price',
  'Other',
];

class _CancelChoice {
  final String reason;
  const _CancelChoice(this.reason);
}

/// Asks the customer to confirm cancelling [orderId], with an optional reason.
/// Returns null when the customer keeps the order.
Future<String?> _askCancelReason(BuildContext context, String orderId) async {
  String selected = _cancelReasons.first;

  final choice = await showDialog<_CancelChoice>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel this order?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order $orderId will be cancelled and the shop will be told. '
                'This cannot be undone.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Why are you cancelling?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              for (final reason in _cancelReasons)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setDialogState(() => selected = reason),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Icon(
                          selected == reason
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 20,
                          color: selected == reason
                              ? AppColors.brandGreen
                              : const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reason,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Keep order',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(dialogContext, _CancelChoice(selected)),
            child: Text(
              'Cancel order',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );

  return choice?.reason;
}

/// Confirms with the customer, then cancels the order and shows the result.
/// Returns true when the order was cancelled.
///
/// [onViewCancelled] adds a "View" button to the message, so the customer can
/// jump straight to where the cancelled order now is.
Future<bool> confirmAndCancelOrder(
  BuildContext context,
  String orderId, {
  VoidCallback? onViewCancelled,
}) async {
  final reason = await _askCancelReason(context, orderId);
  if (reason == null || !context.mounted) return false;

  final cancelled = GroceryService().cancelOrderByCustomer(orderId, reason: reason);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        cancelled
            ? 'Order $orderId was cancelled. You can find it under Cancelled.'
            : 'This order can no longer be cancelled because the shop has already prepared it.',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      ),
      backgroundColor: cancelled ? const Color(0xFF1E293B) : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 5),
      action: (cancelled && onViewCancelled != null)
          ? SnackBarAction(
              label: 'View',
              textColor: const Color(0xFF86EFAC),
              onPressed: onViewCancelled,
            )
          : null,
    ),
  );
  return cancelled;
}

/// Red outlined "Cancel Order" button used on the order screens.
class CancelOrderButton extends StatelessWidget {
  final String orderId;
  final bool compact;
  final VoidCallback? onViewCancelled;

  const CancelOrderButton({
    super.key,
    required this.orderId,
    this.compact = false,
    this.onViewCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 42 : 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF4444),
          side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
          ),
        ),
        onPressed: () => confirmAndCancelOrder(context, orderId, onViewCancelled: onViewCancelled),
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: Text(
          'Cancel Order',
          style: GoogleFonts.plusJakartaSans(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
