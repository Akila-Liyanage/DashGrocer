import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/track_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _newOrder() {
  final service = GroceryService();
  service.clearCart();
  service.addToCart('carrot', 1);
  return service.placeOrder(
    customerName: 'Kasun Perera',
    customerPhone: '+94 77 123 4567',
    pickupSlot: 'Today, 4.00 PM',
    totalAmount: 340,
    shopName: 'GreenLeaf Fresh Mart',
  );
}

Future<void> _open(WidgetTester tester, String id) async {
  await tester.pumpWidget(MaterialApp(home: TrackOrderScreen(orderId: id)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Track Order says what is happening at every stage and follows the shop live', (tester) async {
    final service = GroceryService();
    final id = _newOrder();
    await _open(tester, id);

    // Placed, waiting for the shop
    expect(find.text('Waiting for the shop to accept'), findsOneWidget);
    expect(find.text('In progress'), findsNothing);

    // The shop starts packing
    service.updateOrderStatus(id, 'Preparing');
    await tester.pump();
    expect(find.text('The shop is packing your order'), findsOneWidget);
    expect(find.text('Waiting for the shop to accept'), findsNothing);

    // Ready: the customer has to collect it, so the last step is not "In progress"
    service.updateOrderStatus(id, 'Ready for Pickup');
    await tester.pump();
    expect(find.text('Ready now. Collect it at the shop (Today, 4.00 PM)'), findsOneWidget);
    expect(find.text('In progress'), findsNothing);

    // Collected
    service.updateOrderStatus(id, 'Completed');
    await tester.pump();
    expect(find.text('Collected'), findsOneWidget);
    expect(find.textContaining('Collect it at the shop'), findsNothing);
  });
}
