import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/grocery_item_model.dart';
import '../../services/grocery_service.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'seller_chat_screen.dart';
import 'widgets/grocery_product_card.dart';

class StoreDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> shop;

  const StoreDetailsScreen({
    super.key,
    required this.shop,
  });

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStoreInfoSheet(
    BuildContext context, {
    required String name,
    required String ownerName,
    required String phone,
    required String address,
    required String hours,
    required String curbside,
    required String description,
    required String rating,
    required String reviewsCount,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.brandGreenSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.brandGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Owner: $ownerName • ⭐ $rating ($reviewsCount)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Store Address',
                  address,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.phone_outlined,
                  'Phone Number',
                  phone,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.access_time_rounded,
                  'Operating Hours',
                  hours,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.check_circle_outline_rounded,
                  'Curbside Express Pickup',
                  curbside,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.info_outline_rounded,
                  'About the Store',
                  description,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Close Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _callStore(BuildContext context, String storeName, String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Calling $storeName ($phone)...',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.brandGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groceryService = GroceryService();

    final shopName = widget.shop['name'] as String? ?? 'GreenLeaf Fresh Mart';
    final rating = widget.shop['rating'] as String? ?? '4.8';
    final reviewsCount = widget.shop['reviewsCount'] as String? ?? '120+ reviews';
    final distance = widget.shop['distance'] as String? ?? '1.2 km';
    final pickupTime = widget.shop['pickupTime'] as String? ?? 'Ready in 20m';
    final isDaily = shopName.toLowerCase().contains('daily');
    final address = widget.shop['address'] as String? ??
        (isDaily ? 'No. 18, Station Road, Maharagama' : 'No. 42, High Level Road, Maharagama');
    final phone = widget.shop['phone'] as String? ??
        (isDaily ? '+94 77 234 5678' : '+94 71 987 6543');
    final hours = widget.shop['hours'] as String? ??
        (isDaily ? 'Open Daily: 7:00 AM – 10:00 PM' : 'Open Daily: 7:30 AM – 9:30 PM (Closes at 10:00 PM on weekends)');
    final curbside = widget.shop['curbside'] as String? ??
        'Instant counter pickup with zero waiting queue';
    final ownerName = widget.shop['ownerName'] as String? ??
        (isDaily ? 'Kamal Perera' : 'Sunil Weerasinghe');
    final description = widget.shop['description'] as String? ??
        'Your trusted local neighborhood grocery store with farm-fresh produce and instant pickup.';

    return ListenableBuilder(
      listenable: groceryService,
      builder: (context, _) {
        // Fetch all products associated with this store:
        final allStoreProducts = groceryService.getItemsByShop(shopName);

        // Filter by category:
        var filteredProducts = allStoreProducts;
        if (_selectedCategory == 'Discounted') {
          filteredProducts = filteredProducts.where((e) => (e.discountPercent ?? 0) > 0).toList();
        } else if (_selectedCategory != 'All' && _selectedCategory != 'All Items') {
          filteredProducts = filteredProducts
              .where((e) => e.category.toLowerCase().contains(_selectedCategory.toLowerCase()))
              .toList();
        }

        // Filter by search query:
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.trim().toLowerCase();
          filteredProducts = filteredProducts.where((e) {
            return e.name.toLowerCase().contains(query) ||
                e.category.toLowerCase().contains(query) ||
                e.description.toLowerCase().contains(query);
          }).toList();
        }

        // Available categories in this store:
        final Set<String> storeCategories = {'All'};
        for (final p in allStoreProducts) {
          if (p.category.isNotEmpty) storeCategories.add(p.category);
        }
        if (allStoreProducts.any((p) => (p.discountPercent ?? 0) > 0)) {
          storeCategories.add('Discounted');
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF1A1A1A),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              shopName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Store Information',
                icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF475569), size: 21),
                onPressed: () => _showStoreInfoSheet(
                  context,
                  name: shopName,
                  ownerName: ownerName,
                  phone: phone,
                  address: address,
                  hours: hours,
                  curbside: curbside,
                  description: description,
                  rating: rating,
                  reviewsCount: reviewsCount,
                ),
              ),
              IconButton(
                tooltip: 'View Cart',
                icon: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 21,
                      color: Color(0xFF1A1A1A),
                    ),
                    if (groceryService.totalCartItemCount > 0)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.brandGreen,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '${groceryService.totalCartItemCount}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: groceryService.totalCartItemCount > 0 ? 90 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Details Hero Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE8F6EB), Color(0xFFD1F2D9)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.brandGreen,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            shopName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F6EB),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check_circle_rounded, color: AppColors.brandGreen, size: 12),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Verified',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.brandGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 16),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$rating ($reviewsCount)',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF475569),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF94A3B8),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '🟢 Open Now',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.brandGreenDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$distance away',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.brandGreen),
                                        const SizedBox(width: 3),
                                        Text(
                                          pickupTime,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.brandGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),

                          // Contact & Chat Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _callStore(context, shopName, phone),
                                  icon: const Icon(Icons.phone_outlined, size: 16, color: AppColors.brandGreen),
                                  label: Text(
                                    'Call Store',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppColors.brandGreen,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.brandGreen),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SellerChatScreen(
                                          shopName: shopName,
                                          sellerName: ownerName,
                                          sellerPhone: phone,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                                  label: Text(
                                    'Chat Store',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandGreen,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _showStoreInfoSheet(
                                  context,
                                  name: shopName,
                                  ownerName: ownerName,
                                  phone: phone,
                                  address: address,
                                  hours: hours,
                                  curbside: curbside,
                                  description: description,
                                  rating: rating,
                                  reviewsCount: reviewsCount,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFF475569),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Pickup Details Ribbon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.electric_bolt_rounded, color: AppColors.brandGreen, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$curbside • $address',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF166534),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // In-store Product Search Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Search items in $shopName...',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Category filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: storeCategories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.brandGreen : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.brandGreen : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Section Heading with Item Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Store Catalog',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${filteredProducts.length} items',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Products Grid or Empty State
                    if (filteredProducts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storefront_outlined,
                                size: 30,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No products found',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No items matched "$_searchQuery" in this store.'
                                  : 'Products added to $shopName will appear here in real-time.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty || _selectedCategory != 'All') ...[
                              const SizedBox(height: 14),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedCategory = 'All';
                                  });
                                },
                                child: Text(
                                  'Clear Filters',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brandGreen,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredProducts.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        itemBuilder: (context, index) {
                          final item = filteredProducts[index];
                          return GroceryProductCard(item: item);
                        },
                      ),
                  ],
                ),
              ),

              // Floating Cart Bar if cart has items
              if (groceryService.totalCartItemCount > 0)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.brandGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${groceryService.totalCartItemCount}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${groceryService.totalCartItemCount} ${groceryService.totalCartItemCount == 1 ? "item" : "items"} in cart',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Rs. ${groceryService.subtotal.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CartScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'View Cart',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
