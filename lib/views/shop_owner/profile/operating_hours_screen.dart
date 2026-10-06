import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../core/formatters.dart';
import '../../../services/shop_store.dart';
import '../shop_actions.dart';
import '../widgets/button_spinner.dart';
import '../widgets/dialogs.dart';
import '../widgets/shop_owner_app_bar.dart';

/// Store Operating Hours: opening and closing times for Monday to Saturday
/// and for Sunday. Customers can only choose pickup slots inside these hours.
class OperatingHoursScreen extends StatefulWidget {
  const OperatingHoursScreen({
    super.key,
    required this.store,
    required this.actions,
  });

  final ShopStore store;
  final ShopActions actions;

  @override
  State<OperatingHoursScreen> createState() => _OperatingHoursScreenState();
}

class _OperatingHoursScreenState extends State<OperatingHoursScreen> {
  late int _weekdayOpen;
  late int _weekdayClose;
  late int _sundayOpen;
  late int _sundayClose;
  late bool _sundayClosed;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final shop = widget.store.shop;
    _weekdayOpen = shop.weekdayOpen;
    _weekdayClose = shop.weekdayClose;
    _sundayOpen = shop.sundayOpen;
    _sundayClose = shop.sundayClose;
    _sundayClosed = shop.sundayClosed;
  }

  /// Opens the time picker and returns minutes since midnight.
  Future<int?> _pickTime(int current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    return picked == null ? null : picked.hour * 60 + picked.minute;
  }

  Future<void> _save() async {
    final weekdayOk = _weekdayClose > _weekdayOpen;
    final sundayOk = _sundayClosed || _sundayClose > _sundayOpen;
    if (!weekdayOk || !sundayOk) {
      showAppMessage(
        ScaffoldMessenger.of(context),
        'The closing time must be later than the opening time.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    final saved = await widget.actions.saveShop(
      context,
      widget.store.shop.copyWith(
        weekdayOpen: _weekdayOpen,
        weekdayClose: _weekdayClose,
        sundayOpen: _sundayOpen,
        sundayClose: _sundayClose,
        sundayClosed: _sundayClosed,
      ),
      success: 'Operating hours saved.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DetailAppBar(title: 'Store Operating Hours'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _HoursCard(
            title: 'Monday to Saturday',
            open: _weekdayOpen,
            close: _weekdayClose,
            onPickOpen: () async {
              final value = await _pickTime(_weekdayOpen);
              if (value != null && mounted) setState(() => _weekdayOpen = value);
            },
            onPickClose: () async {
              final value = await _pickTime(_weekdayClose);
              if (value != null && mounted) setState(() => _weekdayClose = value);
            },
          ),
          const SizedBox(height: 12),
          _HoursCard(
            title: 'Sunday',
            open: _sundayOpen,
            close: _sundayClose,
            closed: _sundayClosed,
            onClosedChanged: (value) => setState(() => _sundayClosed = value),
            onPickOpen: () async {
              final value = await _pickTime(_sundayOpen);
              if (value != null && mounted) setState(() => _sundayOpen = value);
            },
            onPickClose: () async {
              final value = await _pickTime(_sundayClose);
              if (value != null && mounted) setState(() => _sundayClose = value);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: ShopDecor.primaryButton(radius: 12),
              onPressed: _saving ? null : _save,
              child: _saving ? const ButtonSpinner() : const Text('Save Hours'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursCard extends StatelessWidget {
  const _HoursCard({
    required this.title,
    required this.open,
    required this.close,
    required this.onPickOpen,
    required this.onPickClose,
    this.closed = false,
    this.onClosedChanged,
  });

  final String title;
  final int open;
  final int close;
  final VoidCallback onPickOpen;
  final VoidCallback onPickClose;

  /// True when the shop does not open on this day.
  final bool closed;

  /// When set, a "Closed" switch is shown.
  final ValueChanged<bool>? onClosedChanged;

  @override
  Widget build(BuildContext context) {
    final closedSwitch = onClosedChanged;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShopDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: ShopText.subtitle)),
              if (closedSwitch != null) ...[
                Text('Closed', style: ShopText.body),
                const SizedBox(width: 4),
                Switch(value: closed, onChanged: closedSwitch),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (closed)
            Text('The shop is closed on this day.', style: ShopText.body)
          else
            Row(
              children: [
                Expanded(
                  child: _TimeBox(
                    label: 'Opens',
                    minutes: open,
                    onTap: onPickOpen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeBox(
                    label: 'Closes',
                    minutes: close,
                    onTap: onPickClose,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Tappable box showing one time, for example "Opens 8:00 AM".
class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.minutes,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShopColors.inputFill,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: ShopText.label),
                    Text(formatMinutesOfDay(minutes), style: ShopText.title),
                  ],
                ),
              ),
              const Icon(
                Icons.schedule,
                size: 18,
                color: ShopColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
