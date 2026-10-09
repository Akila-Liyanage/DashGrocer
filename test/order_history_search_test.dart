import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/order_history_screen.dart';
import 'package:dashgrocer/views/customer/track_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Places a real order for the demo customer (Kasun Perera) and returns its number.
String _placeOrder({String product = 'pumpkin', int quantity = 2, double total = 777}) {
  final service = GroceryService();
  service.clearCart();
  service.addToCart(product, quantity);
  return service.placeOrder(
    customerName: 'Kasun Perera',
    customerPhone: '+94 77 123 4567',
    pickupSlot: 'Today, 4.00 PM',
    totalAmount: total,
    shopName: 'GreenLeaf Fresh Mart',
  );
}

/// The order number as shown on a card (not the same text typed in the search box).
Finder _idText(String id) => find.byWidgetPredicate((w) => w is Text && w.data == id);

Future<void> _openHistory(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: OrderHistoryScreen()));
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pumpAndSettle();
}

void main() {
  productPictureTests();
  filterButtonTests();
  cancelledSectionTests();
  bannerTests();
  testWidgets('Order History shows the customer\'s real orders and search filters them', (tester) async {
    final id = _placeOrder(product: 'pumpkin', total: 777);
    await _openHistory(tester);

    // Search by order number, by product name and by price
    await _search(tester, id);
    expect(_idText(id), findsOneWidget);
    expect(find.text('Rs. 777'), findsOneWidget);

    await _search(tester, 'pumpkin');
    expect(_idText(id), findsWidgets);

    await _search(tester, 'rs. 777');
    expect(_idText(id), findsWidgets);

    // Nothing matches -> empty state, then the clear (x) icon brings orders back
    await _search(tester, 'zzz-no-match');
    expect(find.text('No orders found'), findsOneWidget);
    expect(_idText(id), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('No orders found'), findsNothing);
    expect(_idText(id), findsWidgets);
  });

  testWidgets('Order cards show product pictures', (tester) async {
    final id = _placeOrder(product: 'carrot', quantity: 1, total: 340);
    await _openHistory(tester);
    await _search(tester, id);

    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('Contact button opens the seller chat', (tester) async {
    final id = _placeOrder();
    await _openHistory(tester);
    await _search(tester, id);

    await tester.tap(find.text('Contact').first);
    await tester.pumpAndSettle();

    expect(find.text('Contact'), findsNothing);
    expect(find.textContaining('GreenLeaf'), findsWidgets);
  });

  testWidgets('Customer can cancel a new order from Order History', (tester) async {
    final service = GroceryService();
    final id = _placeOrder(total: 555);
    final sellerNotifsBefore = service.sellerNotifications.length;
    await _openHistory(tester);
    await _search(tester, id);

    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('Cancel Order'), findsOneWidget);

    // Keep order -> nothing changes
    await tester.tap(find.text('Cancel Order'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this order?'), findsOneWidget);
    await tester.tap(find.text('Keep order'));
    await tester.pumpAndSettle();
    expect(service.orderById(id)!.status, 'Pending');

    // Cancel order with a reason
    await tester.tap(find.text('Cancel Order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ordered by mistake'));
    await tester.pump();
    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();

    final order = service.orderById(id)!;
    expect(order.status, 'Cancelled');
    expect(order.cancelledByCustomer, isTrue);
    expect(order.cancelReason, 'Ordered by mistake');

    // The card now says CANCELLED and has no cancel button any more
    expect(find.text('CANCELLED'), findsOneWidget);
    expect(find.text('Cancel Order'), findsNothing);

    // The shop and the customer were both notified
    expect(service.sellerNotifications.length, sellerNotifsBefore + 1);
    expect(service.sellerNotifications.first.title, 'Order Cancelled: $id');
    expect(service.customerNotifications.first.title, 'Order Cancelled: $id');

    // It shows under the Cancel tab, not under Active
    await _search(tester, id);
    await tester.tap(find.text('Cancel').first);
    await tester.pumpAndSettle();
    expect(_idText(id), findsOneWidget);
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(_idText(id), findsNothing);
  });

  testWidgets('Orders that are ready or finished cannot be cancelled', (tester) async {
    final service = GroceryService();
    final id = _placeOrder();

    service.updateOrderStatus(id, 'Preparing');
    expect(service.canCustomerCancel(service.orderById(id)), isTrue);

    service.updateOrderStatus(id, 'Ready for Pickup');
    expect(service.canCustomerCancel(service.orderById(id)), isFalse);
    expect(service.cancelOrderByCustomer(id), isFalse);
    expect(service.orderById(id)!.status, 'Ready for Pickup');

    service.updateOrderStatus(id, 'Completed');
    expect(service.cancelOrderByCustomer(id), isFalse);

    // The card has no cancel button either
    await _openHistory(tester);
    await _search(tester, id);
    expect(find.text('Cancel Order'), findsNothing);
  });

  testWidgets('Track Order shows Cancel Order and then "You cancelled this order."', (tester) async {
    final service = GroceryService();
    final id = _placeOrder();

    await tester.pumpWidget(MaterialApp(home: TrackOrderScreen(orderId: id)));
    await tester.pumpAndSettle();
    expect(find.text('Cancel Order'), findsOneWidget);

    await tester.tap(find.text('Cancel Order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();

    expect(service.orderById(id)!.status, 'Cancelled');
    expect(find.text('You cancelled this order.'), findsOneWidget);
    expect(find.text('Cancel Order'), findsNothing);
  });

  testWidgets('Order History search works together with the filter pills', (tester) async {
    final id = _placeOrder(total: 888);
    GroceryService().updateOrderStatus(id, 'Completed');
    await _openHistory(tester);

    await tester.tap(find.text('Completed').first);
    await tester.pumpAndSettle();
    await _search(tester, id);
    expect(_idText(id), findsOneWidget);

    // Same order is not under Active
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(find.text('No orders found'), findsOneWidget);
  });
}

void bannerTests() {
  testWidgets('Tapping the "Ready for pickup" banner opens that order\'s Track Order screen', (tester) async {
    final service = GroceryService();
    final id = _placeOrder(total: 999);
    service.updateOrderStatus(id, 'Ready for Pickup');
    await _openHistory(tester);

    final banner = find.textContaining('Ready for pickup •');
    expect(banner, findsOneWidget);

    await tester.tap(banner);
    await tester.pumpAndSettle();

    expect(find.byType(TrackOrderScreen), findsOneWidget);
    expect(find.text('Track Order'), findsOneWidget);
    // The screen shows the order that was ready, with its number in the header
    expect(find.textContaining('Order #FP-'), findsWidgets);
  });
}

void cancelledSectionTests() {
  testWidgets('A cancelled order gets its own Cancelled section, and "View" opens the Cancel tab', (tester) async {
    final id = _placeOrder(total: 611);
    await _openHistory(tester);
    await _search(tester, id);

    await tester.tap(find.text('Cancel Order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ordered by mistake'));
    await tester.pump();
    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();

    // It moved out of Active into a clear "Cancelled" section (not "Past Orders")
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget); // only the filter pill
    expect(find.text('Past Orders'), findsNothing);
    expect(find.text('CANCELLED'), findsOneWidget);
    expect(find.text('You cancelled this order'), findsOneWidget);
    expect(find.text('Reason: Ordered by mistake'), findsOneWidget);
    expect(find.text('Nothing was charged.'), findsOneWidget);

    // The message says where to find it, with a View button for the Cancel tab
    expect(find.textContaining('You can find it under Cancelled'), findsOneWidget);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(_idText(id), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty); // the search was cleared so nothing is hidden
    expect(find.text('Active'), findsOneWidget); // no Active section, only the pill
  });

  testWidgets('A card-paid order that is cancelled says the payment will be refunded', (tester) async {
    final service = GroceryService();
    service.clearCart();
    service.addToCart('tomato', 1);
    final id = service.placeOrder(
      customerName: 'Kasun Perera',
      customerPhone: '+94 77 123 4567',
      pickupSlot: 'Today, 5.00 PM',
      totalAmount: 280,
      shopName: 'GreenLeaf Fresh Mart',
      paymentMethod: 'Paid Online (Card)',
    );
    service.cancelOrderByCustomer(id, reason: 'Changed my mind');

    await _openHistory(tester);
    await _search(tester, id);
    expect(find.text('Your card payment will be refunded.'), findsOneWidget);
    expect(find.text('Reason: Changed my mind'), findsOneWidget);
  });
}

void filterButtonTests() {
  /// Places an order and returns its number (the total tells orders apart).
  String place({required double total, String method = 'Pay at Store'}) {
    final service = GroceryService();
    service.clearCart();
    service.addToCart('carrot', 1);
    return service.placeOrder(
      customerName: 'Kasun Perera',
      customerPhone: '+94 77 123 4567',
      pickupSlot: 'Today, 4.00 PM',
      totalAmount: total,
      shopName: 'GreenLeaf Fresh Mart',
      paymentMethod: method,
    );
  }

  testWidgets('The filter button opens the filter sheet and Payment filter works', (tester) async {
    final storeId = place(total: 4111);
    final cardId = place(total: 4222, method: 'Paid Online (Card)');
    await _openHistory(tester);

    // Both orders show at first
    await _search(tester, '41');
    await _search(tester, 'Rs. 4');
    expect(_idText(storeId), findsOneWidget);
    expect(_idText(cardId), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Filter orders'), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Placed'), findsOneWidget);

    await tester.tap(find.text('Paid online'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    // Only the card order is left, and the icon shows that 1 filter is on
    expect(_idText(cardId), findsOneWidget);
    expect(_idText(storeId), findsNothing);
    expect(find.text('1'), findsOneWidget);

    // Reset brings the other order back
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(_idText(storeId), findsOneWidget);
    expect(_idText(cardId), findsOneWidget);
  });

  testWidgets('Sort by Highest total puts the biggest order first', (tester) async {
    final small = place(total: 5001);
    final big = place(total: 5999);
    await _openHistory(tester);
    await _search(tester, 'Rs. 5');

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Highest total'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(_idText(big)).dy, lessThan(tester.getTopLeft(_idText(small)).dy));

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lowest total'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(_idText(small)).dy, lessThan(tester.getTopLeft(_idText(big)).dy));
  });

  testWidgets('Date filter: old orders are hidden by Today and Reset filters shows them again', (tester) async {
    // An order placed 3 days ago is only matched by "Last 7 days", not by "Today"
    final service = GroceryService();
    final id = place(total: 6123);
    final order = service.orderById(id)!;
    expect(order.createdAt.isAfter(DateTime.now().subtract(const Duration(minutes: 1))), isTrue);

    await _openHistory(tester);
    await _search(tester, id);
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(_idText(id), findsOneWidget); // placed just now, so it is "Today"

    // A payment filter that excludes it leaves nothing, with a Reset filters link
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paid online'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(find.text('No orders found'), findsOneWidget);
    expect(find.text('Reset filters'), findsOneWidget);

    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    expect(_idText(id), findsOneWidget);
  });
}

void productPictureTests() {
  testWidgets('An order shows its product pictures (found by product id) and the product names', (tester) async {
    final service = GroceryService();
    service.clearCart();
    service.addToCart('carrot', 1);
    service.addToCart('tomato', 1);
    final id = service.placeOrder(
      customerName: 'Kasun Perera',
      customerPhone: '+94 77 123 4567',
      pickupSlot: 'Today, 4.00 PM',
      totalAmount: 620,
      shopName: 'GreenLeaf Fresh Mart',
    );
    service.updateOrderStatus(id, 'Completed');

    await _openHistory(tester);
    await _search(tester, id);

    // One picture for each product, and the names in words
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.textContaining('Highland Carrots'), findsOneWidget);
    expect(find.textContaining('Ripe Tomatoes'), findsOneWidget);
  });

  testWidgets('A product that is no longer sold still shows by name, with a plain placeholder', (tester) async {
    final service = GroceryService();
    service.clearCart();
    service.addToCart('beans', 1);
    final id = service.placeOrder(
      customerName: 'Kasun Perera',
      customerPhone: '+94 77 123 4567',
      pickupSlot: 'Today, 5.00 PM',
      totalAmount: 240,
      shopName: 'GreenLeaf Fresh Mart',
    );
    service.updateOrderStatus(id, 'Completed');
    service.deleteProduct('beans'); // the shop stops selling it

    await _openHistory(tester);
    await _search(tester, id);

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    expect(find.textContaining('Fresh Green Beans'), findsOneWidget);
  });
}
