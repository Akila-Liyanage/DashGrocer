import 'product.dart';
import 'shop_order.dart';

enum ShopAlertType { newOrder, pickupDue, lowStock }

/// One row in the notifications panel. Alerts are worked out from the live
/// orders and products, so they never go out of date.
class ShopAlert {
  const ShopAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.unread,
    this.time,
    this.order,
    this.product,
  });

  final String id;
  final ShopAlertType type;
  final String title;
  final String body;
  final bool unread;
  final DateTime? time;

  /// Set for order alerts.
  final ShopOrder? order;

  /// Set for stock alerts.
  final Product? product;
}
