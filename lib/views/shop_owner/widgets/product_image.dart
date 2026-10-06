import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';

/// Shows a product photo (also used for the owner's profile photo).
///
/// `imageUrl` can be a normal web link, a picture bundled with the app
/// (`assets/...`), or a small photo saved straight in
/// Firestore as a `data:image/...;base64,` text. Photos taken in the app use
/// that last form, so no Firebase Storage (and no paid plan) is needed.
class ProductImage extends StatefulWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.iconSize = 24,
    this.dimmed = false,
    this.placeholderIcon = Icons.shopping_basket_outlined,
  });

  final String? imageUrl;

  /// Size of the basket icon shown when there is no photo.
  final double iconSize;

  /// Fades the photo, used for out-of-stock products.
  final bool dimmed;

  /// Icon shown when there is no photo or it cannot be shown.
  final IconData placeholderIcon;

  @override
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  /// Decoded photo, kept so it is not decoded again on every rebuild.
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) _decode();
  }

  void _decode() {
    _bytes = null;
    final url = widget.imageUrl;
    if (url == null || !url.startsWith('data:')) return;
    final comma = url.indexOf(',');
    if (comma < 0) return;
    try {
      _bytes = base64Decode(url.substring(comma + 1));
    } on FormatException {
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Icon(
        widget.placeholderIcon,
        size: widget.iconSize,
        color: ShopColors.textSecondary,
      ),
    );

    final url = widget.imageUrl;
    final bytes = _bytes;
    Widget image;
    if (bytes != null) {
      image = Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (url != null && url.startsWith('http')) {
      image = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (url != null && url.startsWith('assets/')) {
      // A picture bundled with the app, as used by the product catalog.
      image = Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else {
      return ColoredBox(color: ShopColors.surfaceLow, child: placeholder);
    }

    return ColoredBox(
      color: ShopColors.surfaceLow,
      child: Opacity(
        opacity: widget.dimmed ? 0.55 : 1.0,
        child: SizedBox.expand(child: image),
      ),
    );
  }
}
