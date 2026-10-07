import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';

/// Short in-app help for the shop owner.
Future<void> showSupportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: ShopColors.background,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Support', style: ShopText.title),
            const SizedBox(height: 12),
            const _HelpItem(
              icon: Icons.assignment_outlined,
              title: 'How an order moves',
              body: 'New, then Preparing, then Ready, then Completed. '
                  'Tap Start Preparing to accept an order. Marking it Ready '
                  'tells the customer to come and collect it.',
            ),
            const _HelpItem(
              icon: Icons.inventory_2_outlined,
              title: 'Keeping stock up to date',
              body: 'Use the In Stock switch on the Products tab when '
                  'something runs out. Customers cannot order products that '
                  'are out of stock.',
            ),
            const _HelpItem(
              icon: Icons.event_note_outlined,
              title: 'Pickup times',
              body: 'Customers choose a pickup slot inside your opening '
                  'hours. Change the hours and slot length in Settings.',
            ),
            const _HelpItem(
              icon: Icons.support_agent,
              title: 'Need more help?',
              body: 'Contact the person who set up this app for your shop.',
            ),
          ],
        ),
      ),
    ),
  );
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: ShopDecor.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: ShopColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ShopText.subtitle),
                const SizedBox(height: 2),
                Text(body, style: ShopText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
