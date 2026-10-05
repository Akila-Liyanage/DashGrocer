import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../models/product.dart';
import '../../../services/shop_store.dart';
import '../shop_actions.dart';
import '../widgets/filter_pill.dart';
import '../widgets/info_card.dart';
import '../widgets/shop_owner_app_bar.dart';
import 'product_card.dart';
import 'product_edit_screen.dart';

/// Product Inventory Management (FR-05): search and filter products, switch
/// them in or out of stock with one tap, and open the editor.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({
    super.key,
    required this.store,
    required this.actions,
    required this.onOpenNotifications,
    required this.onOpenUserProfile,
  });

  final ShopStore store;
  final ShopActions actions;
  final VoidCallback onOpenNotifications;

  /// Opens the owner's "My Profile" screen (the profile icon in the header).
  final VoidCallback onOpenUserProfile;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _search = TextEditingController();

  /// Selected category. Null means "All".
  String? _category;
  bool _outOfStockOnly = false;

  ShopStore get _store => widget.store;
  ShopActions get _actions => widget.actions;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openEditor(Product? product) {
    Navigator.of(context).push(
      shopRoute<void>(
        (context) => ProductEditScreen(
          store: _store,
          actions: _actions,
          product: product,
        ),
      ),
    );
  }

  /// The shop's categories plus any other category found in the data.
  List<String> _categories(List<Product> products) {
    final standard = _store.repository.productCategories;
    final extra = products
        .map((product) => product.category)
        .where((c) => c.isNotEmpty && !standard.contains(c))
        .toSet()
        .toList()
      ..sort();
    return [...standard, ...extra];
  }

  List<Product> _visibleProducts(List<Product> products) {
    final query = _search.text.trim().toLowerCase();
    final result = products.where((product) {
      if (_category != null && product.category != _category) return false;
      if (_outOfStockOnly && !product.isOutOfStock) return false;
      if (query.isEmpty) return true;
      return product.name.toLowerCase().contains(query) ||
          product.code.toLowerCase().contains(query) ||
          product.barcode.contains(query);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, child) {
        final products = _store.products;
        final all = products ?? const <Product>[];

        return Scaffold(
          appBar: ShopOwnerAppBar(
            owner: _store.owner,
            onProfile: widget.onOpenUserProfile,
            onNotifications: widget.onOpenNotifications,
            unreadCount: _store.unreadAlertCount,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Product Inventory',
                            style: ShopText.heading,
                          ),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: ShopColors.greenContainer,
                            foregroundColor: ShopColors.onGreenContainer,
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: ShopText.button,
                          ),
                          onPressed: () => _openEditor(null),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      style: ShopText.input,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      decoration: ShopDecor.input(
                        hint: 'Search product name or code',
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: ShopColors.primary,
                        ),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              FilterPillRow(
                children: [
                  FilterPill(
                    label: 'All',
                    count: products?.length,
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final category in _categories(all))
                    FilterPill(
                      label: category,
                      selected: _category == category,
                      onTap: () => setState(() => _category = category),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
                  decoration: ShopDecor.tile(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Show: Out of Stock items only',
                          style: ShopText.bodyStrong,
                        ),
                      ),
                      Switch(
                        value: _outOfStockOnly,
                        onChanged: (value) =>
                            setState(() => _outOfStockOnly = value),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: _buildList(products)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(List<Product>? products) {
    const listPadding = EdgeInsets.fromLTRB(16, 4, 16, 24);

    if (_store.productsError != null && products == null) {
      return ListView(
        padding: listPadding,
        children: [InfoCard.loadError(what: 'products')],
      );
    }
    if (products == null) {
      return ListView(padding: listPadding, children: const [LoadingCard()]);
    }

    final visible = _visibleProducts(products);
    if (visible.isEmpty) {
      final filtering = _search.text.trim().isNotEmpty ||
          _category != null ||
          _outOfStockOnly;
      return ListView(
        padding: listPadding,
        children: [
          InfoCard(
            icon: filtering ? Icons.search_off : Icons.inventory_2_outlined,
            title: filtering ? 'No matching products' : 'No products yet',
            message: filtering
                ? 'Try a different search or filter.'
                : 'Tap "New Item" to add your first product.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: listPadding,
      itemCount: visible.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = visible[index];
        return ProductCard(
          key: ValueKey(product.id),
          product: product,
          busy: _store.isBusy(product.id),
          onStockChanged: (inStock) =>
              _actions.setInStock(context, product, inStock),
          onEdit: () => _openEditor(product),
        );
      },
    );
  }
}
