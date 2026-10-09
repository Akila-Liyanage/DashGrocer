import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../core/formatters.dart';
import '../../../models/product.dart';
import '../widgets/product_image.dart';

/// One product in the inventory list, with the quick In Stock switch (FR-05)
/// and the Edit button.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.busy,
    required this.onStockChanged,
    required this.onEdit,
  });

  final Product product;

  /// True while a stock change for this product is being saved.
  final bool busy;

  /// Called with true for "in stock" and false for "out of stock".
  final ValueChanged<bool> onStockChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final out = product.isOutOfStock || !product.isAvailable;
    final stockNote = out
        ? (product.isAvailable ? 'None left' : 'Inactive (Hidden)')
        : '${product.stock} in stock';

    return Container(
      decoration: ShopDecor.card(radius: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      iconSize: 28,
                      dimmed: out,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: ShopText.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StockBadge(product: product),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatRs(product.price)} ${product.unitLabel}',
                        style: ShopText.bodyStrong.copyWith(
                          color: out
                              ? ShopColors.textSecondary
                              : ShopColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (product.category.isNotEmpty) product.category,
                          stockNote,
                          if (!product.isAvailable) 'Hidden from customers',
                        ].join(' • '),
                        style: ShopText.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Footer: quick stock switch and Edit.
          Container(
            color: ShopColors.surfaceLow,
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
            child: Row(
              children: [
                Switch(
                  value: !out,
                  onChanged: busy ? null : onStockChanged,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    busy ? 'Saving...' : (out ? 'Out Of Stock' : 'In Stock'),
                    style: ShopText.label.copyWith(
                      color: out
                          ? ShopColors.textSecondary
                          : ShopColors.textPrimary,
                    ),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ShopColors.surface,
                    foregroundColor: ShopColors.primary,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    textStyle: ShopText.bodyStrong,
                  ),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// AVAILABLE / LOW STOCK / OUT OF STOCK label. Each state has its own colour
/// and wording, so it never depends on colour alone.
class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color background;
    final Color foreground;
    if (product.isOutOfStock) {
      text = 'OUT OF STOCK';
      background = ShopColors.errorContainer;
      foreground = ShopColors.onErrorContainer;
    } else if (product.isLowStock) {
      text = 'LOW STOCK';
      background = ShopColors.warningContainer;
      foreground = ShopColors.onWarningContainer;
    } else {
      text = 'AVAILABLE';
      background = ShopColors.greenContainer;
      foreground = ShopColors.onGreenContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: ShopText.label.copyWith(color: foreground)),
    );
  }
}
