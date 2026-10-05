import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/grocery_item_model.dart';
import '../../services/grocery_service.dart';
import 'cart_screen.dart';
import 'widgets/grocery_product_card.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    this.categoryName = 'Vegetables',
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  String _selectedSort = 'Popular';

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  const SizedBox(height: 18),
                  Text(
                    'Filter & Sort ${widget.categoryName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Popular',
                      'Price: Low to High',
                      'Price: High to Low',
                      'Discounted',
                      'New Arrivals'
                    ].map((sortOption) {
                      final isSelected = _selectedSort == sortOption;
                      return ChoiceChip(
                        label: Text(
                          sortOption,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.brandGreen,
                        backgroundColor: const Color(0xFFF4F5F7),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _selectedSort = sortOption;
                            });
                            setState(() {
                              _selectedSort = sortOption;
                            });
                            Navigator.pop(context);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groceryService = GroceryService();

    return ListenableBuilder(
      listenable: groceryService,
      builder: (context, _) {
        List<GroceryItem> items = groceryService.getCategoryItems(widget.categoryName);
        if (items.isEmpty) {
          items = groceryService.allItems.take(6).toList();
        }

        // Apply sort
        final sortedItems = List<GroceryItem>.from(items);
        if (_selectedSort == 'Price: Low to High') {
          sortedItems.sort((a, b) => a.price.compareTo(b.price));
        } else if (_selectedSort == 'Price: High to Low') {
          sortedItems.sort((a, b) => b.price.compareTo(a.price));
        } else if (_selectedSort == 'Discounted') {
          sortedItems.sort((a, b) => (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0));
        } else if (_selectedSort == 'New Arrivals') {
          sortedItems.sort((a, b) => (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0));
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
            centerTitle: true,
            title: Text(
              widget.categoryName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: Color(0xFF1A1A1A),
                ),
                onPressed: () => _showFilterModal(context),
              ),
              IconButton(
                icon: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 20,
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
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: sortedItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                return GroceryProductCard(item: item);
              },
            ),
          ),
        );
      },
    );
  }
}
