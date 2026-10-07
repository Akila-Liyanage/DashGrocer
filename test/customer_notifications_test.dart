import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/customer_notifications_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Placing an order sends the customer an "Order Placed" notification', (tester) async {
    final service = GroceryService();
    final unreadBefore = service.unreadCustomerNotificationsCount;

    final orderId = service.placeOrder(
      customerName: 'Kasun Perera',
      customerPhone: '+94 77 123 4567',
      pickupSlot: 'Today, 4.00 PM',
      totalAmount: 2630,
      shopName: 'Green mart',
    );

    expect(service.unreadCustomerNotificationsCount, unreadBefore + 1);
    expect(service.customerNotifications.first.title, 'Order Placed: $orderId');

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CustomerNotificationsSheet())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Order Placed: $orderId'), findsOneWidget);
    expect(find.textContaining('Total: Rs. 2630.'), findsOneWidget);

    // "Mark read" clears the unread badge count
    await tester.tap(find.text('Mark read'));
    await tester.pumpAndSettle();
    expect(service.unreadCustomerNotificationsCount, 0);
    expect(find.text('Mark read'), findsNothing);
  });
}
