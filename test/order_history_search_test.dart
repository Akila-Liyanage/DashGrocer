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
