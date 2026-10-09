import 'package:flutter/material.dart';

class GroceryItem {
  final String id;
  final String name;
  final String unit;
  final double price;
  final double? originalPrice;
  final int? discountPercent;
  final bool isNew;
  final bool isFavorite;
  final double rating;
  final int reviewsCount;
  final String description;
  final String category;
  final String imageUrl;
  final Color circleColor;
  final int inCartQuantity;
  final String? sellerId;
  final String? sellerName;
  final String? sellerShopName;
  final String? sellerPhone;
  final String? sellerAddress;
  final double? sellerRating;
  final String? sellerResponseTime;
  final int stockQuantity;
  final bool isAvailable;
  final DateTime? createdAt;

  const GroceryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    this.isNew = false,
    this.isFavorite = false,
    this.rating = 4.5,
    this.reviewsCount = 42,
    this.description = '',
    required this.category,
    required this.imageUrl,
    this.circleColor = const Color(0xFFF3FBF0),
    this.inCartQuantity = 0,
    this.sellerId,
    this.sellerName,
    this.sellerShopName,
    this.sellerPhone,
    this.sellerAddress,
    this.sellerRating,
    this.sellerResponseTime,
    this.stockQuantity = 50,
    this.isAvailable = true,
    this.createdAt,
  });

  bool get isOutOfStock => stockQuantity <= 0;
  bool get isActive => isAvailable && stockQuantity > 0;

  String get displaySellerShopName {
    if (sellerShopName != null && sellerShopName!.trim().isNotEmpty) {
      return sellerShopName!;
    }
    if (sellerName != null && sellerName!.trim().isNotEmpty) {
      return sellerName!;
    }
    return 'GreenLeaf Fresh Mart';
  }

  String get displaySellerName =>
      (sellerName != null && sellerName!.trim().isNotEmpty)
          ? sellerName!
          : 'Sunil Weerasinghe';

  String get displaySellerPhone =>
      (sellerPhone != null && sellerPhone!.trim().isNotEmpty)
          ? sellerPhone!
          : '+94 71 987 6543';

  String get displaySellerAddress =>
      (sellerAddress != null && sellerAddress!.trim().isNotEmpty)
          ? sellerAddress!
          : 'No. 42, High Level Road, Maharagama';

  double get displaySellerRating => sellerRating ?? 4.9;

  String get displaySellerResponseTime => sellerResponseTime ?? 'Within 5 mins';

  GroceryItem copyWith({
    String? id,
    String? name,
    String? unit,
    double? price,
    double? originalPrice,
    int? discountPercent,
    bool? isNew,
    bool? isFavorite,
    double? rating,
    int? reviewsCount,
    String? description,
    String? category,
    String? imageUrl,
    Color? circleColor,
    int? inCartQuantity,
    String? sellerId,
    String? sellerName,
    String? sellerShopName,
    String? sellerPhone,
    String? sellerAddress,
    double? sellerRating,
    String? sellerResponseTime,
    int? stockQuantity,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      isNew: isNew ?? this.isNew,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      circleColor: circleColor ?? this.circleColor,
      inCartQuantity: inCartQuantity ?? this.inCartQuantity,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerShopName: sellerShopName ?? this.sellerShopName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerResponseTime: sellerResponseTime ?? this.sellerResponseTime,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': name,
      'unit': unit,
      'price': price,
      'originalPrice': originalPrice,
      'discountPercent': discountPercent,
      'isNew': isNew,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'shopId': sellerId,
      'sellerName': sellerName,
      'sellerShopName': sellerShopName,
      'sellerPhone': sellerPhone,
      'sellerAddress': sellerAddress,
      'sellerRating': sellerRating,
      'sellerResponseTime': sellerResponseTime,
      'stockQuantity': stockQuantity,
      'stock': stockQuantity,
      'isAvailable': isAvailable,
      'isActive': isAvailable,
      'status': isAvailable ? 'active' : 'inactive',
      'productStatus': isAvailable ? 'active' : 'inactive',
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory GroceryItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    final effectiveId = docId ?? (map['id'] as String? ?? 'item_${DateTime.now().millisecondsSinceEpoch}');

    final name = (map['name'] ?? map['title'] ?? map['productName'] ?? map['itemName'] ?? '')
        .toString()
        .trim();

    final cat = (map['category'] ?? map['cat'] ?? map['categoryName'] ?? 'Vegetables')
        .toString()
        .trim();

    final sId = (map['sellerId'] ?? map['shopId'] ?? map['ownerId'])?.toString();
    final sName = (map['sellerName'] ?? map['ownerName'])?.toString();
    final sShop = (map['sellerShopName'] ?? map['shopName'] ?? map['storeName'])?.toString();

    double parseDouble(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    int parseInt(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    bool parseBool(dynamic v, bool fallback) {
      if (v == null) return fallback;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.trim().toLowerCase();
        if (s == 'true' || s == '1' || s == 'active' || s == 'available' || s == 'yes') return true;
        if (s == 'false' || s == '0' || s == 'inactive' || s == 'disabled' || s == 'no' || s == 'hidden') return false;
      }
      return fallback;
    }

    DateTime? parseDate(dynamic v, String id) {
      if (v != null) {
        if (v is DateTime) return v;
        if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
        if (v is String) {
          final parsed = DateTime.tryParse(v);
          if (parsed != null) return parsed;
        }
        try {
          final toDate = (v as dynamic).toDate();
          if (toDate is DateTime) return toDate;
        } catch (_) {}
      }
      // If docId is like prod_1775715900000 or item_1775715900000
      final match = RegExp(r'\d{12,14}').firstMatch(id);
      if (match != null) {
        final ms = int.tryParse(match.group(0)!);
        if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
      }
      return null;
    }

    final price = parseDouble(map['price'], 0.0);
    final origPrice = map['originalPrice'] != null ? parseDouble(map['originalPrice'], price) : null;
    final discount = map['discountPercent'] != null ? parseInt(map['discountPercent'], 0) : null;
    int parseStock() {
      final s = map['stock'];
      final sq = map['stockQuantity'];
      if (s != null && sq != null) {
        final parsedS = parseInt(s, -1);
        final parsedSq = parseInt(sq, -1);
        if (parsedS == 0 || parsedSq == 0) return 0;
        if (parsedS > 0) return parsedS;
        if (parsedSq > 0) return parsedSq;
      }
      if (s != null) return parseInt(s, 0);
      if (sq != null) return parseInt(sq, 0);
      return 50;
    }

    final stock = parseStock();

    // Comprehensive check for availability/active status:
    // If ANY flag or status explicitly indicates inactive, disabled, hidden, or false,
    // the listing must be treated as inactive (isAvailable = false).
    bool determineIsAvailable() {
      const statusKeys = [
        'status',
        'visibility',
        'state',
        'productStatus',
        'catalogStatus',
        'itemStatus',
      ];
      for (final key in statusKeys) {
        final val = map[key];
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
        final val = map[key];
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

      // If positive indicators exist, it's active
      for (final key in boolKeys) {
        final val = map[key];
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
        final val = map[key];
        if (val != null) {
          final s = val.toString().trim().toLowerCase();
          if (s == 'active' || s == 'available' || s == 'published' || s == 'live' || s == 'enabled') {
            return true;
          }
        }
      }

      return true;
    }

    final isAvail = determineIsAvailable();

    final isNewVal = parseBool(map['isNew'], false);
    final isFavVal = parseBool(map['isFavorite'], false);

    final img = (map['imageUrl'] ?? map['image'] ?? map['photoUrl'])?.toString().trim();
    // A product without a photo stays without one (the image widgets show a
    // placeholder icon), instead of borrowing another product's picture.
    final effectiveImg = img ?? '';

    final created = parseDate(map['createdAt'] ?? map['timestamp'], effectiveId);

    return GroceryItem(
      id: effectiveId,
      name: name.isNotEmpty ? name : 'Grocery Item',
      unit: (map['unit']?.toString() ?? '1 kg'),
      price: price,
      originalPrice: origPrice,
      discountPercent: discount,
      isNew: isNewVal,
      isFavorite: isFavVal,
      rating: parseDouble(map['rating'], 4.5),
      reviewsCount: parseInt(map['reviewsCount'], 24),
      description: (map['description']?.toString() ?? ''),
      category: cat.isNotEmpty ? cat : 'Vegetables',
      imageUrl: effectiveImg,
      circleColor: _getCircleColorForCategory(cat),
      sellerId: sId,
      sellerName: sName,
      sellerShopName: sShop,
      sellerPhone: map['sellerPhone']?.toString(),
      sellerAddress: map['sellerAddress']?.toString(),
      sellerRating: map['sellerRating'] != null ? parseDouble(map['sellerRating'], 4.9) : null,
      sellerResponseTime: map['sellerResponseTime']?.toString(),
      stockQuantity: stock,
      isAvailable: isAvail,
      createdAt: created,
    );
  }

  static Color _getCircleColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return const Color(0xFFE8F6EB);
      case 'fruits':
        return const Color(0xFFFFF2E6);
      case 'beverages':
        return const Color(0xFFFFF0E5);
      case 'grocery':
        return const Color(0xFFF3EBFA);
      case 'edible oil':
        return const Color(0xFFE6F8FA);
      case 'household':
        return const Color(0xFFEBF3FA);
      default:
        return const Color(0xFFE8F6EB);
    }
  }

  String get formattedPrice => 'Rs. ${price.toStringAsFixed(price.truncateToDouble() == price ? 2 : 2)}';
  String get formattedPriceWithoutDecimals => 'Rs. ${price.toStringAsFixed(0)}';
}
