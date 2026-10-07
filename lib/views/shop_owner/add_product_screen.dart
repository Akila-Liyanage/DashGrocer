import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/grocery_item_model.dart';
import '../../models/user_model.dart';
import '../../services/grocery_service.dart';
import '../common/app_image_view.dart';

class AddProductScreen extends StatefulWidget {
  final UserModel seller;

  const AddProductScreen({
    super.key,
    required this.seller,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController(text: '1 kg');
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController(text: '45');
  final _imageUrlController = TextEditingController();

  String _selectedCategory = 'Vegetables';
  bool _isNewItem = true;
  String _selectedPresetImage = 'assets/images/carrot.png';

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Grocery',
    'Beverages',
    'Edible oil',
    'Household',
    'Meat',
    'Dairy',
  ];

  final List<Map<String, String>> _presetImages = [
    {
      'label': 'Carrot',
      'url': 'assets/images/carrot.png',
    },
    {
      'label': 'Pumpkin',
      'url': 'assets/images/pumpkin.png',
    },
    {
      'label': 'Tomato',
      'url': 'assets/images/tomato.png',
    },
    {
      'label': 'Red Onion',
      'url': 'assets/images/red_onion.png',
    },
    {
      'label': 'Green Beans',
      'url': 'assets/images/beans.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _imageUrlController.text = _selectedPresetImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final originalPrice = double.tryParse(_originalPriceController.text.trim());
    int? discountPercent;
    if (originalPrice != null && originalPrice > price) {
      discountPercent = (((originalPrice - price) / originalPrice) * 100).round();
    }

    final stock = int.tryParse(_stockController.text.trim()) ?? 50;
    final finalImageUrl = _imageUrlController.text.trim().isNotEmpty
        ? _imageUrlController.text.trim()
        : _selectedPresetImage;

    final newProduct = GroceryItem(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      unit: _unitController.text.trim(),
      price: price,
      originalPrice: originalPrice,
      discountPercent: discountPercent,
      category: _selectedCategory,
      imageUrl: finalImageUrl,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Fresh high quality ${_nameController.text.trim()} supplied directly by ${widget.seller.shopName ?? 'our local partner shop'}.',
      isNew: _isNewItem,
      rating: 4.8,
      reviewsCount: 1,
      sellerId: widget.seller.id,
      sellerName: widget.seller.fullName.isNotEmpty ? widget.seller.fullName : (widget.seller.shopName ?? 'Sunil Weerasinghe'),
      sellerShopName: widget.seller.shopName ?? 'GreenLeaf Fresh Mart',
      sellerPhone: widget.seller.phoneNumber,
      stockQuantity: stock,
    );

    GroceryService().addProduct(newProduct);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🎉 "${newProduct.name}" published live to Customer Home!',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.brandGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Product',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProduct,
            child: Text(
              'Publish',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.brandGreen,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Direct Live Status Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.brandGreenSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct Catalog Sync Active',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandGreenDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Products added here immediately appear on the DashGrocer Home and Category pages for customers.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF475569),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section: Basic Info
            _buildSectionHeader('Basic Details'),
            const SizedBox(height: 10),

            // Product Name
            _buildInputCard(
              label: 'Product Name *',
              child: TextFormField(
                controller: _nameController,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: _inputDecoration('e.g., Organic Red Apples, Sweet Corn'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Product name is required';
                  return null;
                },
              ),
            ),

            const SizedBox(height: 12),

            // Category Selector
            _buildInputCard(
              label: 'Category *',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration('Select category'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),

            const SizedBox(height: 12),

            // Unit & Stock (Side by side)
            Row(
              children: [
                Expanded(
                  child: _buildInputCard(
                    label: 'Unit / Packaging *',
                    child: TextFormField(
                      controller: _unitController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: _inputDecoration('e.g., 500g, 1 kg, 1 pc'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputCard(
                    label: 'Stock Quantity',
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: _inputDecoration('e.g., 40'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section: Pricing
            _buildSectionHeader('Pricing & Discount'),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildInputCard(
                    label: 'Selling Price (Rs.) *',
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandGreen,
                      ),
                      decoration: _inputDecoration('e.g., 450.00'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter price';
                        if (double.tryParse(v.trim()) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputCard(
                    label: 'Original Price (Optional)',
                    child: TextFormField(
                      controller: _originalPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: _inputDecoration('e.g., 500.00'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section: Photo & Imagery
            _buildSectionHeader('Product Image'),
            const SizedBox(height: 10),

            // Preset Photo Quick Picker
            Text(
              'Choose from high-res presets or enter image URL:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _presetImages.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final preset = _presetImages[index];
                  final isSelected = _selectedPresetImage == preset['url'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPresetImage = preset['url']!;
                        _imageUrlController.text = preset['url']!;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.brandGreen : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AppImageView(
                              imageUrl: preset['url']!,
                              fit: BoxFit.contain,
                            ),
                            if (isSelected)
                              Container(
                                color: AppColors.brandGreen.withValues(alpha: 0.35),
                                child: const Center(
                                  child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Custom Image URL field
            _buildInputCard(
              label: 'Image URL',
              child: TextFormField(
                controller: _imageUrlController,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: _inputDecoration('https://...'),
                onChanged: (val) {
                  setState(() {});
                },
              ),
            ),

            const SizedBox(height: 20),

            // Description
            _buildSectionHeader('Product Description'),
            const SizedBox(height: 10),

            _buildInputCard(
              label: 'Detailed Description',
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: _inputDecoration('Highlight freshness, origin, health benefits, and usage tips...'),
              ),
            ),

            const SizedBox(height: 16),

            // Is New Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mark as "New Arrival"',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Shows a glowing "NEW" badge on product cards',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isNewItem,
                    activeTrackColor: AppColors.brandGreen,
                    onChanged: (val) => setState(() => _isNewItem = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Big Publish Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saveProduct,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Publish Product to DashGrocer Live',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1E293B),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildInputCard({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: const Color(0xFF94A3B8),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    );
  }
}
