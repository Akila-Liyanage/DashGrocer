import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => GroceryService().clearCart());

  test('The cart starts empty (nothing is added for the customer)', () {
    // GroceryService is created fresh in this test file
    expect(GroceryService().totalCartItemCount, 0);
    expect(GroceryService().cartItems, isEmpty);
    expect(GroceryService().subtotal, 0);
  });

  testWidgets('Cart shows only the products the customer added', (tester) async {
    final service = GroceryService();
    service.addToCart('carrot', 2);

    await tester.pumpWidget(const MaterialApp(home: CartScreen()));
    await tester.pumpAndSettle();

    final carrot = service.getItemById('carrot')!;
    expect(find.text(carrot.name), findsOneWidget); // one row, not a list of old items
    expect(service.cartItems.length, 1);
    expect(service.totalCartItemCount, 2);
    expect(service.subtotal, carrot.price * 2);
  });

  test('An id that is not in the catalog is not shown, counted or charged', () {
    final service = GroceryService();
    service.addToCart('does_not_exist', 5);

    expect(service.getItemById('does_not_exist'), isNull);
    expect(service.cartItems, isEmpty);
    expect(service.totalCartItemCount, 0);
    expect(service.subtotal, 0);
    expect(service.totalOrderPrice, 0); // no shipping fee for an empty cart either
  });
}
