import 'firestore_dates.dart';

/// Categories offered on the Product Details screen and as inventory filters.
const List<String> kProductCategories = [
  'Rice & Grains',
  'Dairy & Eggs',
  'Bakery',
  'Produce',
  'Beverages',
  'Snacks',
  'Household',
];

/// Selling units offered on the Product Details screen.
const List<String> kSellingUnits = [
  'kg', 'g', 'L', 'Pack', 'Bottle', 'Pcs', 'Box', 'Bundle',
];

class Product {
  const Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.stock,
    this.code = '',
    this.barcode = '',
    this.lowStockThreshold = 10,
    this.isAvailable = true,
    this.imageUrl,
    this.updatedAt,
  });

  /// Firestore document id. Empty for a product that is not saved yet.
  final String id;
  final String shopId;
  final String name;
  final String category;

  /// Selling unit, one of [kSellingUnits].
  final String unit;
  final double price;

  /// How many units are on the shelf. 0 means out of stock.
  final int stock;

  /// The shop's own product code.
  final String code;
  final String barcode;

  /// The "Low Stock Alert" value from the Product Details screen.
  final int lowStockThreshold;

  /// The "Online Availability" switch: listed in the customer catalog or not.
  final bool isAvailable;

  /// Either a web link, or a small photo stored as a `data:` URI.
  final String? imageUrl;
  final DateTime? updatedAt;

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock <= lowStockThreshold;

  /// "Rs. 245 / kg" style unit label.
  String get unitLabel => unit.isEmpty ? '' : '/ $unit';

  Product copyWith({
    String? id,
    int? stock,
    bool? isAvailable,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      shopId: shopId,
      name: name,
      category: category,
      unit: unit,
      price: price,
      stock: stock ?? this.stock,
      code: code,
      barcode: barcode,
      lowStockThreshold: lowStockThreshold,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      shopId: (map['shopId'] as String?) ?? (map['sellerId'] as String? ?? ''),
      name: map['name'] as String? ?? 'Product',
      category: map['category'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? ((map['stockQuantity'] as num?)?.toInt() ?? 0),
      code: map['code'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toInt() ?? 10,
      isAvailable: (map['isAvailable'] as bool?) ?? ((map['isActive'] as bool?) ?? true),
      imageUrl: map['imageUrl'] as String?,
      updatedAt: readDate(map['updatedAt']),
    );
  }

  /// `updatedAt` is left out on purpose: the repository sets it when saving.
  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'sellerId': shopId,
      'name': name,
      'category': category,
      'unit': unit,
      'price': price,
      'stock': stock,
      'stockQuantity': stock,
      'code': code,
      'barcode': barcode,
      'lowStockThreshold': lowStockThreshold,
      'isAvailable': isAvailable,
      'isActive': isAvailable,
      'imageUrl': imageUrl,
    };
  }
}
