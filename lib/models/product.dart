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
    bool determineProductAvailability(Map<String, dynamic> m) {
      const statusKeys = [
        'status',
        'visibility',
        'state',
        'productStatus',
        'catalogStatus',
        'itemStatus',
      ];
      for (final key in statusKeys) {
        final val = m[key];
        if (val != null) {
          final s = val.toString().trim().toLowerCase();
          if (s == 'inactive' ||
              s == 'disabled' ||
              s == 'hidden' ||
              s == 'hide' ||
              s == 'draft' ||
              s == 'archived' ||
              s == 'off' ||
              s == 'unavailable' ||
              s == 'deleted' ||
              s == 'paused' ||
              s == 'false' ||
              s == '0') {
            return false;
          }
        }
      }

      const boolKeys = [
        'isAvailable',
        'isActive',
        'active',
        'available',
        'is_active',
        'is_available',
        'enabled',
        'visible',
        'online',
        'isOnline',
      ];
      for (final key in boolKeys) {
        final val = m[key];
        if (val != null) {
          if (val is bool && !val) return false;
          if (val is num && val == 0) return false;
          if (val is String) {
            final s = val.trim().toLowerCase();
            if (s == 'false' ||
                s == '0' ||
                s == 'inactive' ||
                s == 'disabled' ||
                s == 'hidden' ||
                s == 'no' ||
                s == 'off') {
              return false;
            }
          }
        }
      }

      for (final key in boolKeys) {
        final val = m[key];
        if (val != null) {
          if (val is bool && val) return true;
          if (val is num && val > 0) return true;
          if (val is String) {
            final s = val.trim().toLowerCase();
            if (s == 'true' || s == '1' || s == 'active' || s == 'available' || s == 'yes') {
              return true;
            }
          }
        }
      }

      for (final key in statusKeys) {
        final val = m[key];
        if (val != null) {
          final s = val.toString().trim().toLowerCase();
          if (s == 'active' || s == 'available' || s == 'published' || s == 'live' || s == 'enabled') {
            return true;
          }
        }
      }

      return true;
    }

    return Product(
      id: id,
      shopId: (map['shopId'] as String?) ?? (map['sellerId'] as String? ?? ''),
      name: map['name'] as String? ?? 'Product',
      category: map['category'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      stock: () {
        final s = (map['stock'] as num?)?.toInt();
        final sq = (map['stockQuantity'] as num?)?.toInt();
        if (s != null && sq != null) {
          if (s == 0 || sq == 0) return 0;
          if (s > 0) return s;
          if (sq > 0) return sq;
        }
        if (s != null) return s;
        if (sq != null) return sq;
        return 0;
      }(),
      code: map['code'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toInt() ?? 10,
      isAvailable: determineProductAvailability(map),
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
      'status': isAvailable ? 'active' : 'inactive',
      'productStatus': isAvailable ? 'active' : 'inactive',
      'imageUrl': imageUrl,
    };
  }
}
