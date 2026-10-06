import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../models/owner_profile.dart';
import '../../../services/shop_store.dart';
import '../shop_actions.dart';
import '../widgets/button_spinner.dart';
import '../widgets/dialogs.dart';
import '../widgets/owner_avatar.dart';
import '../widgets/photo_picker.dart';
import '../widgets/shop_owner_app_bar.dart';

/// My Profile: the logged-in shop owner's own details.
///
/// Opened by the profile icon in the header of every tab. The owner can
/// change their photo, name, email and phone number, jump to their shop's
/// profile, and log out. (The shop's details are on the Profile tab.)
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.store,
    required this.actions,
    required this.onOpenShopProfile,
    required this.onLogout,
  });

  final ShopStore store;
  final ShopActions actions;

  /// Switch to the Profile tab, which shows the shop's details.
  final VoidCallback onOpenShopProfile;

  /// Called after the owner confirms logging out.
  final VoidCallback onLogout;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  String? _nameError;
  String? _emailError;

  /// True once a text field has been edited and not saved yet.
  bool _dirty = false;
  bool _saving = false;

  ShopStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _fillFields(_store.owner);
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _fillFields(OwnerProfile owner) {
    _name.text = owner.fullName;
    _email.text = owner.email;
    _phone.text = owner.phoneNumber;
  }

  /// The profile can arrive from Firestore a moment after the screen opens.
  /// Show it then, unless the owner has already started typing.
  void _onStoreChanged() {
    if (_dirty || _saving) return;
    final owner = _store.owner;
    final changed = _name.text != owner.fullName ||
        _email.text != owner.email ||
        _phone.text != owner.phoneNumber;
    if (changed) _fillFields(owner);
  }

  void _markDirty() {
    if (_dirty && _nameError == null && _emailError == null) return;
    setState(() {
      _dirty = true;
      _nameError = null;
      _emailError = null;
    });
  }

  Future<void> _changePhoto() async {
    final owner = _store.owner;
    final choice = await choosePhoto(context, canRemove: owner.hasPhoto);
    if (choice == null || !mounted) return;

    // The photo is saved straight away, on top of the saved details, so it
    // does not depend on the Save button.
    await widget.actions.saveOwner(
      context,
      choice.removed
          ? _store.owner.copyWith(removePhoto: true)
          : _store.owner.copyWith(photoUrl: choice.dataUri),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final email = _email.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'Enter your name' : null;
      _emailError = (email.isNotEmpty && !_emailPattern.hasMatch(email))
          ? 'Enter a valid email address'
          : null;
    });
    if (_nameError != null || _emailError != null) return;

    setState(() => _saving = true);
    final saved = await widget.actions.saveOwner(
      context,
      _store.owner.copyWith(
        fullName: name,
        email: email,
        phoneNumber: _phone.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) _dirty = false;
    });
  }

  void _openShopProfile() {
    Navigator.of(context).pop();
    widget.onOpenShopProfile();
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You will stop receiving new order alerts on this phone '
          'until you log in again.',
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    Navigator.of(context).pop();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DetailAppBar(title: 'My Profile'),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, child) {
          final owner = _store.owner;
          final shop = _store.shop;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _HeaderCard(
                owner: owner,
                photoBusy: _store.isBusy('owner') && !_saving,
                onChangePhoto: _changePhoto,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                decoration: ShopDecor.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 20,
                          color: ShopColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text('Personal Details', style: ShopText.title),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field(
                      label: 'Full Name',
                      controller: _name,
                      hint: 'For example: Kamal Perera',
                      errorText: _nameError,
                      capitalization: TextCapitalization.words,
                    ),
                    _field(
                      label: _store.repository.canEditEmail
                          ? 'Email Address'
                          : 'Email Address (your login email)',
                      controller: _email,
                      hint: 'name@example.com',
                      errorText: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: !_store.repository.canEditEmail,
                    ),
                    _field(
                      label: 'Phone Number',
                      controller: _phone,
                      hint: '071 234 5678',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: ShopDecor.primaryButton(radius: 12),
                  // Enabled only when there is something new to save.
                  onPressed: (_dirty && !_saving) ? _save : null,
                  child: _saving
                      ? const ButtonSpinner()
                      : const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 16),
              _ShopTile(
                name: shop.name,
                address: shop.address,
                onTap: _openShopProfile,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ShopColors.errorContainer,
                    foregroundColor: ShopColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: ShopText.subtitle,
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Log Out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? errorText,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    bool readOnly = false,
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
            readOnly: readOnly,
            style: readOnly
                ? ShopText.input.copyWith(color: ShopColors.textSecondary)
                : ShopText.input,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            onChanged: (_) => _markDirty(),
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
}

/// Photo (or initials), name, role and email, with the change-photo button.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.owner,
    required this.photoBusy,
    required this.onChangePhoto,
  });

  final OwnerProfile owner;

  /// True while a new photo is being saved.
  final bool photoBusy;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShopDecor.card(),
      child: Column(
        children: [
          SizedBox(
            width: 104,
            height: 96,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: OwnerAvatar(
                    owner: owner,
                    radius: 44,
                    showInitials: true,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Tooltip(
                    message: owner.hasPhoto ? 'Change photo' : 'Add photo',
                    child: Material(
                      color: ShopColors.surface,
                      shape: const CircleBorder(
                        side: BorderSide(color: ShopColors.surfaceHigh),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: photoBusy ? null : onChangePhoto,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: photoBusy
                              ? const Center(child: ButtonSpinner())
                              : const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 18,
                                  color: ShopColors.primary,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            owner.fullName.isEmpty ? 'Your name' : owner.fullName,
            style: ShopText.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ShopColors.greenContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'SHOP OWNER',
              style: ShopText.label.copyWith(color: ShopColors.onGreenContainer),
            ),
          ),
          if (owner.email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(owner.email, style: ShopText.body, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Link from the owner's profile to their shop's profile.
class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.name,
    required this.address,
    required this.onTap,
  });

  final String name;
  final String address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShopDecor.card(),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: ShopDecor.tile(color: ShopColors.surfaceMid),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 20,
                    color: ShopColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MY SHOP', style: ShopText.label),
                      Text(
                        name,
                        style: ShopText.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address.isNotEmpty)
                        Text(
                          address,
                          style: ShopText.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: ShopColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
