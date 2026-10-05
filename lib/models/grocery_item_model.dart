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
    this.stockQuantity = 50,
  });

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
      'stockQuantity': stockQuantity,
    };
  }

  factory GroceryItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    return GroceryItem(
      id: docId ?? (map['id'] as String? ?? 'item_${DateTime.now().millisecondsSinceEpoch}'),
      name: map['name'] as String? ?? '',
      unit: map['unit'] as String? ?? '1 kg',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      discountPercent: (map['discountPercent'] as num?)?.toInt(),
      isNew: map['isNew'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: (map['reviewsCount'] as num?)?.toInt() ?? 24,
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Grocery',
      imageUrl: map['imageUrl'] as String? ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=500&q=80',
      sellerId: map['sellerId'] as String?,
      sellerName: map['sellerName'] as String?,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 50,
    );
  }

  String get formattedPrice => 'Rs. ${price.toStringAsFixed(price.truncateToDouble() == price ? 2 : 2)}';
  String get formattedPriceWithoutDecimals => 'Rs. ${price.toStringAsFixed(0)}';
}
