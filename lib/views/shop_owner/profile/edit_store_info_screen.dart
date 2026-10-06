import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../services/shop_store.dart';
import '../shop_actions.dart';
import '../widgets/button_spinner.dart';
import '../widgets/shop_owner_app_bar.dart';

/// Edit the store name, pickup address and phone numbers.
class EditStoreInfoScreen extends StatefulWidget {
  const EditStoreInfoScreen({
    super.key,
    required this.store,
    required this.actions,
  });

  final ShopStore store;
  final ShopActions actions;

  @override
  State<EditStoreInfoScreen> createState() => _EditStoreInfoScreenState();
}

class _EditStoreInfoScreenState extends State<EditStoreInfoScreen> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _note;
  late final TextEditingController _phone;
  late final TextEditingController _mobile;

  String? _nameError;
  String? _addressError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final shop = widget.store.shop;
    _name = TextEditingController(text: shop.name);
    _address = TextEditingController(text: shop.address);
    _note = TextEditingController(text: shop.addressNote);
    _phone = TextEditingController(text: shop.phone);
    _mobile = TextEditingController(text: shop.mobile);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _note.dispose();
    _phone.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final address = _address.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Enter your store name' : null;
      _addressError =
          address.isEmpty ? 'Enter where customers collect orders' : null;
    });
    if (_nameError != null || _addressError != null) return;

    setState(() => _saving = true);
    final saved = await widget.actions.saveShop(
      context,
      widget.store.shop.copyWith(
        name: name,
        address: address,
        addressNote: _note.text.trim(),
        phone: _phone.text.trim(),
        mobile: _mobile.text.trim(),
      ),
      success: 'Store information saved.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) Navigator.of(context).pop();
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label,
              style:
                  ShopText.bodyStrong.copyWith(color: ShopColors.textSecondary),
            ),
          ),
          TextField(
            controller: controller,
            style: ShopText.input,
            keyboardType: keyboardType,
            textCapitalization: keyboardType == TextInputType.phone
                ? TextCapitalization.none
                : TextCapitalization.words,
            decoration: ShopDecor.input(
              hint: hint,
              errorText: errorText,
              fill: ShopColors.inputFill,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DetailAppBar(title: 'Store Information'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            decoration: ShopDecor.card(),
            child: Column(
              children: [
                _field(
                  label: 'Store Name',
                  controller: _name,
                  hint: 'For example: Green Mart',
                  errorText: _nameError,
                ),
                _field(
                  label: 'Pickup Address',
                  controller: _address,
                  hint: '42 Temple Road, Nugegoda',
                  errorText: _addressError,
                ),
                _field(
                  label: 'Pickup Point Note (optional)',
                  controller: _note,
                  hint: 'Front dispatch counter',
                ),
                _field(
                  label: 'Shop Phone',
                  controller: _phone,
                  hint: '+94 11 281 9400',
                  keyboardType: TextInputType.phone,
                ),
                _field(
                  label: 'Mobile (optional)',
                  controller: _mobile,
                  hint: '077 458 1290',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: ShopDecor.primaryButton(radius: 12),
              onPressed: _saving ? null : _save,
              child:
                  _saving ? const ButtonSpinner() : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
