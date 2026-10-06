import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/grocery_item_model.dart';
import '../../../services/grocery_service.dart';
import '../../common/app_image_view.dart';
import '../product_detail_screen.dart';

class GroceryProductCard extends StatelessWidget {
  final GroceryItem item;
  final VoidCallback? onTap;

  const GroceryProductCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final groceryService = GroceryService();
    final cartQty = groceryService.getQuantity(item.id);

    final tapHandler = onTap ??
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(item: item),
            ),
          );
        };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F2F4),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: tapHandler,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            // Top Row: Badges (NEW / -16%) and Heart Icon
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge (NEW or Discount)
                  if (item.isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECE5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF8142),
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else if (item.discountPercent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${item.discountPercent}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                          letterSpacing: 0.3,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 24, height: 16),

                  // Favorite Heart
                  GestureDetector(
                    onTap: () {
                      groceryService.toggleFavorite(item.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        item.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: item.isFavorite ? const Color(0xFFFE5858) : const Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center Circular Product Image Background
            Expanded(
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: item.circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: AppImageView(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Product Details: Price, Name, Unit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Text(
                    'Rs ${item.price.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.unit,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF868889),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Bottom Divider
            const Divider(
              height: 1,
              thickness: 0.8,
              color: Color(0xFFF0F1F2),
            ),

            // Bottom Action: Add to Cart or Stepper
            Container(
              height: 40,
              alignment: Alignment.center,
              child: cartQty == 0
                  ? InkWell(
                      onTap: () {
                        groceryService.addToCart(item.id, 1);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${item.name} added to cart',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12),
                            ),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 15,
                            color: AppColors.brandGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add to cart',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: const Icon(
                            Icons.remove,
                            size: 18,
                            color: AppColors.brandGreen,
                          ),
                          onPressed: () => groceryService.decrementQuantity(item.id),
                        ),
                        Text(
                          '$cartQty',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                            color: AppColors.brandGreen,
                          ),
                          onPressed: () => groceryService.incrementQuantity(item.id),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
