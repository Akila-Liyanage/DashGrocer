import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../models/shop_order.dart';

/// Shows a short message at the bottom of the screen (NFR-02: clear feedback
/// after every action). Errors are shown in red.
void showAppMessage(
  ScaffoldMessengerState messenger,
  String message, {
  bool isError = false,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? ShopColors.error : null,
      ),
    );
}

/// Yes / no question. Returns true only when the confirm button is pressed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: ShopColors.error)
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// The green "Ready to hand off?" confirmation from the Figma file.
///
/// Marking an order ready notifies the customer, so the owner confirms first.
/// [unpackedCount] warns when some checklist items are not ticked yet.
Future<bool> confirmMarkReady(
  BuildContext context,
  ShopOrder order, {
  int unpackedCount = 0,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: ShopColors.greenContainer,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: ShopColors.primary,
                  child: Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to hand off?',
                        style: ShopText.subtitle.copyWith(
                          color: ShopColors.onGreenContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Marking order #${order.orderNumber} ready sends an '
                        'immediate notification to ${order.customerName}.',
                        style: ShopText.body.copyWith(
                          color: ShopColors.textPrimary,
                        ),
                      ),
                      if (unpackedCount > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          unpackedCount == 1
                              ? '1 item is not ticked on the checklist yet.'
                              : '$unpackedCount items are not ticked on the '
                                  'checklist yet.',
                          style: ShopText.bodyStrong.copyWith(
                            color: ShopColors.onErrorContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: ShopDecor.primaryButton(),
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Mark Ready'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ShopColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: ShopText.button,
                    ),
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Reasons offered when the shop rejects a new order.
const List<String> kRejectReasons = [
  'An item is out of stock',
  'Cannot prepare it by the pickup time',
  'The shop is closing early',
  'Other reason',
];

/// Asks why a new order is being rejected. Returns the reason, or null when
/// the owner backs out.
Future<String?> pickRejectReason(BuildContext context, ShopOrder order) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _RejectDialog(order: order),
  );
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.order});

  final ShopOrder order;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  String _reason = kRejectReasons.first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reject order #${widget.order.orderNumber}?'),
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${widget.order.customerName} will be told the order was '
              'cancelled. This cannot be undone.',
            ),
          ),
          const SizedBox(height: 8),
          for (final reason in kRejectReasons)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _reason = reason),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      reason == _reason
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: reason == _reason
                          ? ShopColors.primary
                          : ShopColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(reason)),
                  ],
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep Order'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ShopColors.error),
          onPressed: () => Navigator.of(context).pop(_reason),
          child: const Text('Reject Order'),
        ),
      ],
    );
  }
}

/// Asks for a whole number, for example how many units to restock.
/// Returns the number, or null when the owner cancels.
Future<int?> showQuantityDialog(
  BuildContext context, {
  required String title,
  required String fieldLabel,
  String? message,
  int initialValue = 10,
  int minimum = 1,
  String confirmLabel = 'Save',
}) {
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => _QuantityDialog(
      title: title,
      fieldLabel: fieldLabel,
      message: message,
      initialValue: initialValue,
      minimum: minimum,
      confirmLabel: confirmLabel,
    ),
  );
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({
    required this.title,
    required this.fieldLabel,
    required this.message,
    required this.initialValue,
    required this.minimum,
    required this.confirmLabel,
  });

  final String title;
  final String fieldLabel;
  final String? message;
  final int initialValue;
  final int minimum;
  final String confirmLabel;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.initialValue}');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < widget.minimum) {
      setState(() => _error = 'Enter a number of ${widget.minimum} or more');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[
            Text(message),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: InputDecoration(
              labelText: widget.fieldLabel,
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
