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
  });

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
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
      'sellerName': sellerName,
      'sellerShopName': sellerShopName,
      'sellerPhone': sellerPhone,
      'sellerAddress': sellerAddress,
      'sellerRating': sellerRating,
      'sellerResponseTime': sellerResponseTime,
      'stockQuantity': stockQuantity,
    };
  }

  factory GroceryItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    final cat = map['category'] as String? ?? 'Vegetables';
    return GroceryItem(
      id: docId ?? (map['id'] as String? ?? 'item_${DateTime.now().millisecondsSinceEpoch}'),
      name: map['name'] as String? ?? '',
      unit: map['unit'] as String? ?? '1 kg',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      discountPercent: (map['discountPercent'] as num?)?.toInt(),
      isNew: map['isNew'] as bool? ?? false,
      isFavorite: map['isFavorite'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: (map['reviewsCount'] as num?)?.toInt() ?? 24,
      description: map['description'] as String? ?? '',
      category: cat,
      imageUrl: map['imageUrl'] as String? ?? 'assets/images/pumpkin.png',
      circleColor: _getCircleColorForCategory(cat),
      sellerId: map['sellerId'] as String?,
      sellerName: map['sellerName'] as String?,
      sellerShopName: map['sellerShopName'] as String?,
      sellerPhone: map['sellerPhone'] as String?,
      sellerAddress: map['sellerAddress'] as String?,
      sellerRating: (map['sellerRating'] as num?)?.toDouble(),
      sellerResponseTime: map['sellerResponseTime'] as String?,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 50,
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
