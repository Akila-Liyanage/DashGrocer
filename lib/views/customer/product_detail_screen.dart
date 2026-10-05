import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/grocery_item_model.dart';
import '../../services/grocery_service.dart';
import '../common/app_image_view.dart';
import 'cart_screen.dart';
import 'reviews_screen.dart';
import 'seller_chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final GroceryItem item;

  const ProductDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedQuantity = 3;
  bool _isDescriptionExpanded = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final existingQty = GroceryService().getQuantity(widget.item.id);
    if (existingQty > 0) {
      _selectedQuantity = existingQty;
    }
  }

  Map<String, String> _getNutritionInfo(GroceryItem item) {
    final id = item.id.toLowerCase();
    if (id == 'pumpkin') {
      return {
        'Vitamin A': '245% DV',
        'Calories': '26 kcal',
        'Fiber': '2.7g',
        'Potassium': '340mg',
      };
    } else if (id == 'tomato') {
      return {
        'Lycopene': '3.0mg',
        'Vitamin C': '28% DV',
        'Calories': '18 kcal',
        'Water': '95%',
      };
    } else if (id == 'red_onion') {
      return {
        'Quercetin': 'High',
        'Antioxidants': '92%',
        'Calories': '40 kcal',
        'Fiber': '1.7g',
      };
    } else if (id == 'beans') {
      return {
        'Vitamin K': '43% DV',
        'Folate': '15% DV',
        'Fiber': '2.7g',
        'Protein': '1.8g',
      };
    } else if (id == 'carrot') {
      return {
        'Beta-Carotene': '8,285 mcg',
        'Vitamin A': '334% DV',
        'Fiber': '2.8g',
        'Calories': '41 kcal',
      };
    } else {
      return {
        'Fiber': '2.8g',
        'Calories': '48 kcal',
        'Vitamin C': '18%',
        'Water': '88%',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final groceryService = GroceryService();
    final currentItem =
        groceryService.getItemById(widget.item.id) ?? widget.item;
    _isFavorite = currentItem.isFavorite;

    final nutrition = _getNutritionInfo(currentItem);
    final relatedItems = groceryService.allItems
        .where((i) => i.id != currentItem.id)
        .take(6)
        .toList();

    return ListenableBuilder(
      listenable: groceryService,
      builder: (context, _) {
        final screenHeight = MediaQuery.of(context).size.height;
        final heroHeight = (screenHeight * 0.38).clamp(260.0, 340.0);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            top: false,
            bottom: true,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── TOP HERO IMAGE WITH PASTEL GREEN CIRCULAR BACKGROUND ───
                  _buildHeroSection(context, currentItem, heroHeight),

                  // ─── MAIN PRODUCT DETAILS (Exact Figma layout) ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Price and Favorite Heart
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Rs. ${currentItem.price.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2EB844),
                                letterSpacing: -0.3,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                groceryService.toggleFavorite(currentItem.id);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      !_isFavorite
                                          ? 'Added to your favorites'
                                          : 'Removed from favorites',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  _isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: _isFavorite
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF8E8E93),
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Product Title
                        Text(
                          currentItem.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: -0.4,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Unit
                        Text(
                          currentItem.unit,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8E8E93),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Rating & Reviews row
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReviewsScreen(productName: currentItem.name),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                currentItem.rating.toStringAsFixed(1),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(width: 5),
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < currentItem.rating.floor()
                                      ? Icons.star_rounded
                                      : (index < currentItem.rating
                                          ? Icons.star_half_rounded
                                          : Icons.star_border_rounded),
                                  size: 16,
                                  color: const Color(0xFFFFA000),
                                );
                              }),
                              const SizedBox(width: 6),
                              Text(
                                '(${currentItem.reviewsCount} reviews)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Description
                        _buildDescription(currentItem),

                        const SizedBox(height: 20),

                        // Quantity Selector Container
                        _buildQuantitySelector(),

                        const SizedBox(height: 16),

                        // Add to cart Button (Figma exact match)
                        _buildAddToCartButton(context, currentItem, groceryService),

                        const SizedBox(height: 28),

                        // ─── Rich Information Sections Below ───
                        _buildNutritionSection(nutrition),

                        const SizedBox(height: 20),

                        _buildFreshnessGuarantee(),

                        const SizedBox(height: 20),

                        _buildStoreInfo(context, currentItem),

                        const SizedBox(height: 24),

                        if (relatedItems.isNotEmpty)
                          _buildSimilarProducts(context, relatedItems),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  Hero Section: Circular/Arc Pastel Background
  // ─────────────────────────────────────────────
  Widget _buildHeroSection(
    BuildContext context,
    GroceryItem item,
    double height,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      height: height + topPadding,
      width: double.infinity,
      color: Colors.white,
      child: Stack(
        children: [
          // Pastel elliptical light green background
          Positioned(
            top: 0,
            left: -30,
            right: -30,
            bottom: 10,
            child: Container(
              decoration: BoxDecoration(
                color: item.circleColor.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.elliptical(380, 160),
                ),
              ),
            ),
          ),

          // Product Image (Hero animated)
          Positioned(
            top: topPadding + 36,
            left: 36,
            right: 36,
            bottom: 24,
            child: Hero(
              tag: 'product_image_${item.id}',
              child: AppImageView(
                imageUrl: item.imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Back Arrow (Clean, minimal Figma style)
          Positioned(
            top: topPadding + 8,
            left: 16,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF1A1A1A),
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Chat with Seller Quick Button (Top right)
          Positioned(
            top: topPadding + 8,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF1A1A1A),
                  size: 20,
                ),
                tooltip: 'Chat with Seller',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellerChatScreen(
                        product: item,
                        shopName: item.displaySellerShopName,
                        sellerName: item.displaySellerName,
                        sellerPhone: item.displaySellerPhone,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Description with "more" / "less"
  // ─────────────────────────────────────────────
  Widget _buildDescription(GroceryItem item) {
    final desc = item.description;
    final shouldTruncate = desc.length > 200;
    final displayText = _isDescriptionExpanded
        ? desc
        : (shouldTruncate ? '${desc.substring(0, 200)}... ' : desc);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: displayText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
            children: [
              if (shouldTruncate)
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: Text(
                      _isDescriptionExpanded ? ' less' : ' more',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Quantity Stepper (Figma Exact Layout)
  // ─────────────────────────────────────────────
  Widget _buildQuantitySelector() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // "Quantity" label
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Quantity',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
          const Spacer(),

          // Minus Button
          GestureDetector(
            onTap: () {
              if (_selectedQuantity > 1) {
                setState(() => _selectedQuantity--);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 52,
              alignment: Alignment.center,
              child: const Icon(
                Icons.remove_rounded,
                size: 20,
                color: Color(0xFF2EB844),
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 32,
            color: const Color(0xFFE5E7EB),
          ),

          // Count
          SizedBox(
            width: 46,
            child: Center(
              child: Text(
                '$_selectedQuantity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 32,
            color: const Color(0xFFE5E7EB),
          ),

          // Plus Button
          GestureDetector(
            onTap: () {
              if (_selectedQuantity < 99) {
                setState(() => _selectedQuantity++);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 52,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 20,
                color: Color(0xFF2EB844),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Add to Cart Button (Figma Exact Layout)
  // ─────────────────────────────────────────────
  Widget _buildAddToCartButton(
    BuildContext context,
    GroceryItem item,
    GroceryService groceryService,
  ) {
    return Row(
      children: [
        // Chat with Seller Quick Button
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellerChatScreen(
                      product: item,
                      shopName: item.displaySellerShopName,
                      sellerName: item.displaySellerName,
                      sellerPhone: item.displaySellerPhone,
                    ),
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF1E293B),
                    size: 22,
                  ),
                  Positioned(
                    top: 13,
                    right: 13,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Add to Cart Button (Flexible)
        Expanded(
          child: SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF76C935),
                    Color(0xFF63B826),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF63B826).withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  groceryService.addToCart(item.id, _selectedQuantity);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Added $_selectedQuantity × ${item.name} to cart!',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF1E1E1E),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      action: SnackBarAction(
                        label: 'View Cart',
                        textColor: const Color(0xFF76C935),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CartScreen(),
                            ),
                          );
                        },
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Add to cart',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Nutrition Quick Facts
  // ─────────────────────────────────────────────
  Widget _buildNutritionSection(Map<String, String> nutrition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition Facts',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: nutrition.entries.map((entry) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    Text(
                      entry.value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.key,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Freshness Guarantee
  // ─────────────────────────────────────────────
  Widget _buildFreshnessGuarantee() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD6ECCB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF2EB844).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF2EB844),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Quality & Freshness Guarantee',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E5B22),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'If you are not satisfied with freshness, get an instant replacement or refund.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF437A47),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Seller & Store Showcase Card with Chat & Call
  // ─────────────────────────────────────────────
  Widget _buildStoreInfo(BuildContext context, GroceryItem item) {
    final shopName = item.displaySellerShopName;
    final sellerName = item.displaySellerName;
    final phone = item.displaySellerPhone;
    final rating = item.displaySellerRating;
    final responseTime = item.displaySellerResponseTime;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Verified Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seller & Store Information',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Seller',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Store profile summary row
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2EB844), Color(0xFF1E8A31)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Posted by $sellerName',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Metadata row: Rating, Response time, Location
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSellerStat(Icons.star_rounded, '$rating ★', 'Store Rating', const Color(0xFFF59E0B)),
                Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                _buildSellerStat(Icons.bolt_rounded, responseTime, 'Response', const Color(0xFF3B82F6)),
                Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                _buildSellerStat(Icons.location_on_rounded, '1.2 km', 'Maharagama', const Color(0xFF10B981)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Contact & Chat Action Buttons
          Row(
            children: [
              // Chat with Seller CTA (Primary)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EB844),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: Text(
                      'Chat with Seller',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerChatScreen(
                            product: item,
                            shopName: shopName,
                            sellerName: sellerName,
                            sellerPhone: phone,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Direct Call Button
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF2EB844)),
                  label: Text(
                    'Call',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling $shopName ($sellerName) at $phone...'),
                        backgroundColor: AppColors.brandGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellerStat(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Similar Products Section
  // ─────────────────────────────────────────────
  Widget _buildSimilarProducts(
    BuildContext context,
    List<GroceryItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'You Might Also Like',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            Text(
              'See all',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2EB844),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final simItem = items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(item: simItem),
                    ),
                  );
                },
                child: Container(
                  width: 130,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEBEBEB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: AppImageView(
                            imageUrl: simItem.imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        simItem.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rs. ${simItem.price.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2EB844),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
