import 'package:dashgrocer/models/seller_order_model.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/customer_notifications_sheet.dart';
import 'package:dashgrocer/views/customer/order_confirmation_screen.dart';
import 'package:dashgrocer/views/customer/track_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _placeOrder({String slot = 'Today, 4.00 PM', String method = 'Pay at Store'}) {
  final service = GroceryService();
  service.clearCart();
  service.addToCart('carrot', 1);
  return service.placeOrder(
    customerName: 'Kasun Perera',
    customerPhone: '+94 77 123 4567',
    pickupSlot: slot,
    totalAmount: 340,
    shopName: 'GreenLeaf Fresh Mart',
    paymentMethod: method,
  );
}

List<String> _titlesFor(String id) => GroceryService()
    .customerNotifications
    .where((n) => n.orderId == id)
    .map((n) => n.title)
    .toList();

void main() {
  group('Customer notifications follow the shop', () {
    test('Accepted, Ready and Completed each notify the customer once', () {
      final service = GroceryService();
      final id = _placeOrder();
      expect(_titlesFor(id), ['Order Placed: $id']);

      service.updateOrderStatus(id, 'Preparing');
      service.updateOrderStatus(id, 'Preparing'); // same status again: nothing new
      service.updateOrderStatus(id, 'Ready for Pickup');
      service.updateOrderStatus(id, 'Completed');

      expect(_titlesFor(id).reversed.toList(), [
        'Order Placed: $id',
        'Order Accepted: $id',
        'Order Ready: $id',
        'Order Completed: $id',
      ]);
      final ready = service.customerNotifications.firstWhere((n) => n.title == 'Order Ready: $id');
      expect(ready.message, contains('Collect it at GreenLeaf Fresh Mart (Today, 4.00 PM)'));
    });

    test('When the shop rejects an order the customer gets the reason', () {
      final service = GroceryService();
      final id = _placeOrder(method: 'Paid Online (Card)');
      service.updateOrderStatus(id, 'Cancelled', cancelReason: 'Out of stock');

      final note = service.customerNotifications.firstWhere((n) => n.title == 'Order Cancelled: $id');
      expect(note.message, contains('Reason: Out of stock.'));
      expect(note.message, contains('refunded'));
      expect(service.orderById(id)!.cancelReason, 'Out of stock');
      expect(service.orderById(id)!.cancelledByCustomer, isFalse);
    });

    test('Collecting an order gives one thank-you, not two', () {
      final service = GroceryService();
      final id = _placeOrder();
      service.updateOrderStatus(id, 'Ready for Pickup');
      expect(service.confirmPickupByCustomer(id), isTrue);

      expect(_titlesFor(id).where((t) => t == 'Order Collected: $id').length, 1);
      expect(_titlesFor(id).contains('Order Completed: $id'), isFalse);
      expect(service.orderById(id)!.status, 'Completed');
      // Only an order that is ready can be collected
      expect(service.confirmPickupByCustomer(id), isFalse);
    });
  });

  testWidgets('Notification times follow the clock and tapping one marks it read', (tester) async {
    final service = GroceryService();
    final id = _placeOrder();
    service.updateOrderStatus(id, 'Ready for Pickup');
    final readyId = service.customerNotifications.first.id;
    final unreadBefore = service.unreadCustomerNotificationsCount;

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CustomerNotificationsSheet())));
    await tester.pumpAndSettle();

    expect(find.text('Order Ready: $id'), findsOneWidget);
    expect(find.text('Just now'), findsWidgets);

    await tester.tap(find.text('Order Ready: $id'));
    await tester.pumpAndSettle();

    expect(service.customerNotifications.firstWhere((n) => n.id == readyId).isRead, isTrue);
    expect(service.unreadCustomerNotificationsCount, unreadBefore - 1);
  });

  group('Pickup label shows the real day', () {
    StoreOrder order(String slot, DateTime placed) => StoreOrder(
          id: '#FP-1',
          customerName: 'A',
          customerPhone: '',
          itemsSummary: '',
          totalAmount: 1,
          pickupSlot: slot,
          shopName: 'S',
          createdAt: placed,
        );
    final today = DateTime(2026, 10, 14, 10, 0);

    test('same day, tomorrow, yesterday and further away', () {
      expect(order('Today, 4.00 PM', today).pickupLabel(now: today), 'Today, 4.00 PM');
      expect(order('Tomorrow, 9.00 AM', today).pickupLabel(now: today), 'Tomorrow, 9.00 AM');
      // Ordered yesterday for "Today": that day is now yesterday
      final yesterday = DateTime(2026, 10, 13, 18, 0);
      expect(order('Today, 4.00 PM', yesterday).pickupLabel(now: today), 'Yesterday, 4.00 PM');
      // Ordered yesterday for "Tomorrow": that is today
      expect(order('Tomorrow, 9.00 AM', yesterday).pickupLabel(now: today), 'Today, 9.00 AM');
      // A week ago: a real date
      final lastWeek = DateTime(2026, 10, 7, 9, 0);
      expect(order('Today, 4:30 PM - 5:00 PM', lastWeek).pickupLabel(now: today), 'Wed 7 Oct, 4:30 PM');
    });

    test('a slot with no time is left as it is', () {
      expect(order('Today', today).pickupLabel(now: today), 'Today');
    });
  });

  group('Track Order', () {
    testWidgets('"I collected my order" completes a ready order', (tester) async {
      final service = GroceryService();
      final id = _placeOrder();
      await tester.pumpWidget(MaterialApp(home: TrackOrderScreen(orderId: id)));
      await tester.pumpAndSettle();

      // Not ready yet: no collect button
      expect(find.text('I collected my order'), findsNothing);

      service.updateOrderStatus(id, 'Ready for Pickup');
      await tester.pump();
      expect(find.text('I collected my order'), findsOneWidget);

      // "Not yet" keeps the order as it is
      await tester.tap(find.text('I collected my order'));
      await tester.pumpAndSettle();
      expect(find.text('Did you collect your order?'), findsOneWidget);
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(service.orderById(id)!.status, 'Ready for Pickup');

      // "Yes, collected" completes it and the last step says Collected
      await tester.tap(find.text('I collected my order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, collected'));
      await tester.pumpAndSettle();
      expect(service.orderById(id)!.status, 'Completed');
      expect(find.text('Collected'), findsOneWidget);
      expect(find.text('I collected my order'), findsNothing);
      expect(service.sellerNotifications.first.title, 'Order Collected: $id');
    });

    testWidgets('An order that does not exist shows a clear message, not made-up details', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TrackOrderScreen(orderId: '#FP-DOES-NOT-EXIST')));
      await tester.pumpAndSettle();

      expect(find.text('We could not find this order'), findsOneWidget);
      expect(find.textContaining('October 15 2026'), findsNothing);
      expect(find.textContaining('Rs.1000'), findsNothing);
    });
  });

  testWidgets('Back on Order Confirmed goes home instead of back to payment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                const Text('HOME'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('PAYMENT'))),
                    );
                  },
                  child: const Text('go'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    // Payment is replaced by the confirmation, like the real flow does
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => const OrderConfirmationScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Order Confirmed'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('Order Confirmed'), findsNothing);
    expect(find.text('PAYMENT'), findsNothing);
  });
}
