import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../core/formatters.dart';
import '../../../services/shop_store.dart';
import '../shop_actions.dart';
import '../widgets/button_spinner.dart';
import '../widgets/filter_pill.dart';
import '../widgets/shop_owner_app_bar.dart';

/// Pickup Slot Management & Capacity.
///
/// The shop chooses how long each pickup slot is and how many orders it can
/// take per slot. The customer app reads these two values to build the
/// pickup time list (FR-04), which stops too many orders arriving at once.
class PickupSlotsScreen extends StatefulWidget {
  const PickupSlotsScreen({
    super.key,
    required this.store,
    required this.actions,
  });

  final ShopStore store;
  final ShopActions actions;

  @override
  State<PickupSlotsScreen> createState() => _PickupSlotsScreenState();
}

class _PickupSlotsScreenState extends State<PickupSlotsScreen> {
  static const List<int> _slotChoices = [15, 30, 45, 60];
  static const int _maxCapacity = 50;

  late int _slotMinutes;
  late int _capacity;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _slotMinutes = widget.store.shop.slotMinutes;
    _capacity = widget.store.shop.maxOrdersPerSlot;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await widget.actions.saveShop(
      context,
      widget.store.shop.copyWith(
        slotMinutes: _slotMinutes,
        maxOrdersPerSlot: _capacity,
      ),
      success: 'Pickup slot settings saved.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final slots = widget.store.shop
        .copyWith(slotMinutes: _slotMinutes)
        .pickupSlotsFor(today);

    return Scaffold(
      appBar: const DetailAppBar(title: 'Pickup Slots'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: ShopDecor.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Slot Length', style: ShopText.subtitle),
                      Text(
                        'How far apart the pickup times offered to '
                        'customers are.',
                        style: ShopText.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FilterPillRow(
                  children: [
                    for (final minutes in _slotChoices)
                      FilterPill(
                        label: '$minutes min',
                        selected: _slotMinutes == minutes,
                        onTap: () => setState(() => _slotMinutes = minutes),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: ShopDecor.card(),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Orders per Slot', style: ShopText.subtitle),
                      Text(
                        'A slot stops being offered once it has this many '
                        'orders.',
                        style: ShopText.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Fewer orders per slot',
                  onPressed: _capacity > 1
                      ? () => setState(() => _capacity--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$_capacity',
                    style: ShopText.title,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton.filled(
                  tooltip: 'More orders per slot',
                  onPressed: _capacity < _maxCapacity
                      ? () => setState(() => _capacity++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: ShopDecor.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Pickup Slots", style: ShopText.subtitle),
                Text(
                  slots.isEmpty
                      ? 'The shop is closed today, so no slots are offered.'
                      : '${slots.length} slots, built from your opening '
                          'hours.',
                  style: ShopText.body,
                ),
                if (slots.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final start in slots)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: ShopDecor.tile(),
                          child: Text(
                            formatMinutesOfDay(start),
                            style: ShopText.label.copyWith(
                              color: ShopColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: ShopDecor.primaryButton(radius: 12),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const ButtonSpinner()
                  : const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
