import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../models/product.dart';
import '../../../services/shop_store.dart';
import '../shop_actions.dart';
import '../widgets/button_spinner.dart';
import '../widgets/dialogs.dart';
import '../widgets/filter_pill.dart';
import '../widgets/photo_picker.dart';
import '../widgets/product_image.dart';
import '../widgets/shop_owner_app_bar.dart';

/// Product Details: add a new product or edit an existing one (FR-05).
///
/// Pass `product: null` to add a new product.
class ProductEditScreen extends StatefulWidget {
  const ProductEditScreen({
    super.key,
    required this.store,
    required this.actions,
    this.product,
  });

  final ShopStore store;
  final ShopActions actions;
  final Product? product;

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _code;
  late final TextEditingController _barcode;
  late final TextEditingController _price;

  String? _category;
  String _unit = kSellingUnits.first;
  int _stock = 0;
  int _threshold = 10;
  bool _isAvailable = true;
  String? _imageUrl;

  String? _titleError;
  String? _priceError;
  bool _categoryMissing = false;

  /// True once anything has been changed.
  bool _dirty = false;
  bool _saving = false;

  bool get _isNew => widget.product == null;

  /// The shop's categories, plus this product's own category if it is not
  /// one of them.
  List<String> get _categoryChoices {
    final standard = widget.store.repository.productCategories;
    final current = widget.product?.category ?? '';
    if (current.isEmpty || standard.contains(current)) return standard;
    return [...standard, current];
  }

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _title = TextEditingController(text: product?.name ?? '');
    _code = TextEditingController(text: product?.code ?? '');
    _barcode = TextEditingController(text: product?.barcode ?? '');
    _price = TextEditingController(
      text: product == null ? '' : _priceText(product.price),
    );
    if (product != null) {
      _category = product.category.isEmpty ? null : product.category;
      _unit = product.unit.isEmpty ? kSellingUnits.first : product.unit;
      _stock = product.stock;
      _threshold = product.lowStockThreshold;
      _isAvailable = product.isAvailable;
      _imageUrl = product.imageUrl;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _code.dispose();
    _barcode.dispose();
    _price.dispose();
    super.dispose();
  }

  /// 250 -> "250.00"
  static String _priceText(double price) => price.toStringAsFixed(2);

  void _change(VoidCallback update) {
    setState(() {
      update();
      _dirty = true;
    });
  }

  // ------------------------------------------------------------------ photo

  Future<void> _choosePhoto() async {
    final hasPhoto = _imageUrl != null && _imageUrl!.isNotEmpty;
    final choice = await choosePhoto(context, canRemove: hasPhoto);
    if (choice == null || !mounted) return;
    _change(() => _imageUrl = choice.removed ? null : choice.dataUri);
  }

  // ------------------------------------------------------------ save / exit

  Future<void> _save() async {
    final name = _title.text.trim();
    final price = double.tryParse(_price.text.trim());

    setState(() {
      _titleError = name.isEmpty ? 'Enter the product name' : null;
      _priceError =
          (price == null || price <= 0) ? 'Enter a price above 0' : null;
      _categoryMissing = _category == null;
    });
    if (_titleError != null || _priceError != null || _categoryMissing) {
      showAppMessage(
        ScaffoldMessenger.of(context),
        'Please fix the highlighted fields.',
        isError: true,
      );
      return;
    }

    final product = Product(
      id: widget.product?.id ?? '',
      shopId: widget.store.shopId,
      name: name,
      category: _category ?? '',
      unit: _unit,
      price: price ?? 0,
      stock: _stock,
      code: _code.text.trim(),
      barcode: _barcode.text.trim(),
      lowStockThreshold: _threshold,
      isAvailable: _isAvailable,
      imageUrl: _imageUrl,
      updatedAt: widget.product?.updatedAt,
    );

    setState(() => _saving = true);
    final saved = await widget.actions.saveProduct(context, product);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) Navigator.of(context).pop();
  }

  Future<void> _discard() async {
    if (_dirty) {
      final leave = await showConfirmDialog(
        context,
        title: 'Discard changes?',
        message: 'Your changes to this product will not be saved.',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep Editing',
        destructive: true,
      );
      if (!leave || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final product = widget.product;
    if (product == null) return;
    final deleted = await widget.actions.deleteProduct(context, product);
    if (deleted && mounted) Navigator.of(context).pop();
  }

  Future<void> _editStock() async {
    final value = await showQuantityDialog(
      context,
      title: 'Stock level',
      fieldLabel: 'Units in stock',
      initialValue: _stock,
      minimum: 0,
    );
    if (value != null && mounted) _change(() => _stock = value);
  }

  Future<void> _editThreshold() async {
    final value = await showQuantityDialog(
      context,
      title: 'Low stock alert',
      message: 'You are alerted when the stock is at or below this number.',
      fieldLabel: 'Alert level',
      initialValue: _threshold,
      minimum: 0,
    );
    if (value != null && mounted) _change(() => _threshold = value);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DetailAppBar(
        title: _isNew ? 'New Product' : 'Product Details',
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Delete product',
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: ShopColors.error),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _buildPhotoCard(),
          const SizedBox(height: 12),
          _buildDetailsCard(),
          const SizedBox(height: 12),
          _buildCategoryCard(),
          const SizedBox(height: 12),
          _buildUnitCard(),
          const SizedBox(height: 12),
          _buildPriceStockCard(),
          // Shown only when the catalog can actually hide a product.
          if (widget.store.repository.supportsCatalogVisibility) ...[
            const SizedBox(height: 12),
            _buildAvailabilityCard(),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: ShopDecor.primaryButton(radius: 12),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const ButtonSpinner()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(_isNew ? 'Add Product' : 'Save Changes'),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: ShopDecor.tonalButton(
                foreground: ShopColors.textSecondary,
                radius: 12,
              ),
              onPressed: _saving ? null : _discard,
              child: Text(_isNew ? 'Cancel' : 'Discard Edits'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShopDecor.card(),
      child: child,
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: ShopText.bodyStrong.copyWith(color: ShopColors.textSecondary),
      ),
    );
  }

  Widget _buildPhotoCard() {
    final hasPhoto = _imageUrl != null && _imageUrl!.isNotEmpty;

    return _card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 208,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductImage(imageUrl: _imageUrl, iconSize: 48),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ShopColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: ShopText.subtitle,
                      ),
                      onPressed: _choosePhoto,
                      icon: const Icon(
                        Icons.photo_camera_outlined,
                        size: 18,
                        color: ShopColors.primary,
                      ),
                      label: Text(hasPhoto ? 'Replace Photo' : 'Add Photo'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Product Title'),
          TextField(
            controller: _title,
            style: ShopText.subtitle,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _change(() => _titleError = null),
            decoration: ShopDecor.input(
              hint: 'For example: Keeri Samba Rice',
              fill: ShopColors.inputFill,
              errorText: _titleError,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Product Code'),
                    TextField(
                      controller: _code,
                      style: ShopText.subtitle,
                      onChanged: (_) => _change(() {}),
                      decoration: ShopDecor.input(
                        hint: '88210',
                        prefixText: '# ',
                        fill: ShopColors.inputFill,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Barcode NO'),
                    TextField(
                      controller: _barcode,
                      style: ShopText.subtitle,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => _change(() {}),
                      decoration: ShopDecor.input(
                        hint: '79214051',
                        fill: ShopColors.inputFill,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: ShopDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: Text('Category', style: ShopText.subtitle)),
                Text(
                  _categoryMissing ? 'CHOOSE ONE' : 'REQUIRED',
                  style: ShopText.label.copyWith(
                    color:
                        _categoryMissing ? ShopColors.error : ShopColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilterPillRow(
            children: [
              for (final category in _categoryChoices)
                FilterPill(
                  label: category,
                  selected: _category == category,
                  onTap: () => _change(() {
                    _category = category;
                    _categoryMissing = false;
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard() {
    Widget unitButton(String unit) {
      final selected = unit == _unit;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: selected ? ShopColors.primaryButton : ShopColors.inputFill,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _change(() => _unit = unit),
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    unit,
                    style: ShopText.subtitle.copyWith(
                      color: selected ? Colors.white : ShopColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // The standard units, plus this product's own unit (for example
    // "500 g") when it is not one of them, shown four to a row.
    const perRow = 4;
    final current = widget.product?.unit ?? '';
    final units = <String>[
      ...kSellingUnits,
      if (current.isNotEmpty && !kSellingUnits.contains(current)) current,
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Selling Unit', style: ShopText.subtitle),
          Text('Select one', style: ShopText.body),
          const SizedBox(height: 8),
          for (var start = 0; start < units.length; start += perRow)
            Row(
              children: [
                for (var i = start; i < start + perRow; i++)
                  if (i < units.length)
                    unitButton(units[i])
                  else
                    const Expanded(child: SizedBox()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPriceStockCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Price per $_unit'),
                    TextField(
                      controller: _price,
                      style: ShopText.title,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,7}(\.\d{0,2})?'),
                        ),
                      ],
                      onChanged: (_) => _change(() => _priceError = null),
                      decoration: ShopDecor.input(
                        hint: '0.00',
                        prefixText: 'Rs. ',
                        fill: ShopColors.inputFill,
                        errorText: _priceError,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Stock Level'),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: ShopDecor.tile(color: ShopColors.inputFill),
                      child: Row(
                        children: [
                          _StepButton(
                            icon: Icons.remove,
                            tooltip: 'Decrease stock',
                            filled: false,
                            onPressed: _stock > 0
                                ? () => _change(() => _stock--)
                                : null,
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: _editStock,
                              borderRadius: BorderRadius.circular(6),
                              child: Center(
                                child: Text('$_stock', style: ShopText.title),
                              ),
                            ),
                          ),
                          _StepButton(
                            icon: Icons.add,
                            tooltip: 'Increase stock',
                            filled: true,
                            onPressed: () => _change(() => _stock++),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: ShopColors.inputFill,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _editThreshold,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notification_important_outlined,
                      size: 18,
                      color: ShopColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Low Stock Alert', style: ShopText.bodyStrong),
                          Text(
                            'Notify when stock is at or below $_threshold',
                            style: ShopText.body,
                          ),
                        ],
                      ),
                    ),
                    Text('$_threshold', style: ShopText.bodyStrong),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: ShopColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return _card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: ShopDecor.tile(color: ShopColors.greenContainer),
            child: const Icon(
              Icons.storefront_outlined,
              color: ShopColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Online Availability', style: ShopText.subtitle),
                Text(
                  _isAvailable
                      ? 'Visible in customer catalog'
                      : 'Hidden from customers',
                  style: ShopText.body,
                ),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            onChanged: (value) => _change(() => _isAvailable = value),
          ),
        ],
      ),
    );
  }
}

/// The square minus and plus buttons of the stock stepper.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.filled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? ShopColors.primary : ShopColors.surfaceHighest,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 18,
              color: filled
                  ? Colors.white
                  : (enabled
                      ? ShopColors.textPrimary
                      : ShopColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
