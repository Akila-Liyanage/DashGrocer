import 'package:flutter/material.dart';

import '../../../../core/theme/shop_owner_theme.dart';
import '../../../../core/formatters.dart';
import '../../../../models/product.dart';
import '../../shop_actions.dart';
import '../../widgets/product_image.dart';

/// The card under "Low Stock": one row per product that is running out.
class LowStockList extends StatelessWidget {
  const LowStockList({
    super.key,
    required this.products,
    required this.isBusy,
    required this.onQuickAdd,
    required this.onRestock,
  });

  final List<Product> products;

  /// Tells whether a product's stock change is being saved.
  final bool Function(String productId) isBusy;
  final ValueChanged<Product> onQuickAdd;
  final ValueChanged<Product> onRestock;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShopDecor.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < products.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: ShopColors.surfaceMid,
              ),
            _LowStockRow(
              product: products[i],
              busy: isBusy(products[i].id),
              onQuickAdd: () => onQuickAdd(products[i]),
              onRestock: () => onRestock(products[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({
    required this.product,
    required this.busy,
    required this.onQuickAdd,
    required this.onRestock,
  });

  final Product product;
  final bool busy;
  final VoidCallback onQuickAdd;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    final out = product.isOutOfStock;
    final unitsLeft = product.stock == 1
        ? 'Only 1 unit left'
        : 'Only ${product.stock} units left';

    return Container(
      color: out ? const Color(0x66EEF5F0) : null,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(imageUrl: product.imageUrl, dimmed: out),
                  if (out)
                    const ColoredBox(
                      color: Color(0x332B322F),
                      child: Center(
                        child: Icon(
                          Icons.block,
                          size: 18,
                          color: ShopColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: ShopText.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: out
                          ? const OutOfStockBadge()
                          : Text(
                              unitsLeft,
                              style: ShopText.body.copyWith(
                                color: ShopColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('•', style: ShopText.body),
                    ),
                    Text(formatMoney(product.price), style: ShopText.body),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StockButton(
            label: out ? 'Restock' : 'Add ${ShopActions.quickAddAmount}',
            icon: out ? Icons.sync : Icons.add,
            filled: out,
            busy: busy,
            onPressed: out ? onRestock : onQuickAdd,
          ),
        ],
      ),
    );
  }
}

/// Red "OUT OF STOCK" label.
class OutOfStockBadge extends StatelessWidget {
  const OutOfStockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ShopColors.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'OUT OF STOCK',
        style: ShopText.label.copyWith(
          color: ShopColors.onErrorContainer,
          letterSpacing: 0,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Compact button for stock actions: filled green for "Restock", pale for
/// "Add 10".
class StockButton extends StatelessWidget {
  const StockButton({
    super.key,
    required this.label,
    required this.icon,
    required this.filled,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: filled ? ShopColors.primary : ShopColors.surfaceMid,
        foregroundColor: filled ? Colors.white : ShopColors.primary,
        disabledBackgroundColor: ShopColors.surfaceHigh,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: ShopText.label,
      ),
      icon: busy
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ShopColors.primary,
              ),
            )
          : Icon(icon, size: 14),
      label: Text(label),
    );
  }
}
