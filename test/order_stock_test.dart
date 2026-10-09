import 'package:dashgrocer/models/grocery_item_model.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = GroceryService();
  var counter = 0;

  /// Adds a fresh product with [stock] units and returns its id.
  String addProduct(int stock) {
    final id = 'stock_test_${counter++}';
    service.addProduct(
      GroceryItem(
        id: id,
        name: 'Stock Test $id',
        unit: '1 kg',
        price: 100,
        category: 'Vegetables',
        imageUrl: '',
        circleColor: const Color(0xFFE8F6EB),
        stockQuantity: stock,
      ),
    );
    return id;
  }

  String placeOrder() {
    return service.placeOrder(
      customerName: 'Stock Tester',
      customerPhone: '+94 77 000 0000',
      pickupSlot: 'Today, 4:00 PM',
      totalAmount: service.totalOrderPrice,
      shopName: 'GreenLeaf Fresh Mart',
    );
  }

  int stockOf(String id) => service.getItemById(id)!.stockQuantity;

  setUp(service.clearCart);

  group('Stock and cart', () {
    test('1. The cart starts empty', () {
      expect(service.cartItems, isEmpty);
      expect(service.totalCartItemCount, 0);
    });

    test('2. A customer cannot add more than the shop has in stock', () {
      final id = addProduct(3);

      expect(service.addToCart(id, 2), 2);
      expect(service.addToCart(id, 5), 1);
      expect(service.getQuantity(id), 3);
      expect(service.canAddMore(id), isFalse);

      service.incrementQuantity(id);
      expect(service.getQuantity(id), 3);

      expect(service.setCartQuantity(id, 10), 3);
    });

    test('3. An out-of-stock or unknown product cannot be added', () {
      final id = addProduct(0);

      expect(service.addToCart(id), 0);
      expect(service.addToCart('no_such_product'), 0);
      expect(service.cartItems, isEmpty);
    });

    test('4. Placing an order takes the quantity out of the stock', () {
      final id = addProduct(10);
      service.addToCart(id, 4);

      placeOrder();

      expect(stockOf(id), 6);
      expect(service.cartItems, isEmpty);
    });

    test('5. A cancelled order puts the stock back, once', () {
      final id = addProduct(10);
      service.addToCart(id, 4);
      final orderId = placeOrder();
      expect(stockOf(id), 6);

      expect(service.cancelOrderByCustomer(orderId), isTrue);
      expect(stockOf(id), 10);

      // Cancelling again (from the shop side) must not add it twice.
      service.updateOrderStatus(orderId, 'Cancelled');
      expect(stockOf(id), 10);
    });

    test('6. The shop cancelling an order also puts the stock back', () {
      final id = addProduct(5);
      service.addToCart(id, 5);
      final orderId = placeOrder();
      expect(stockOf(id), 0);

      service.updateOrderStatus(orderId, 'Cancelled');
      expect(stockOf(id), 5);
    });

    test('7. Lowering the stock lowers what is already in the cart', () {
      final id = addProduct(8);
      service.addToCart(id, 6);

      service.updateProduct(service.getItemById(id)!.copyWith(stockQuantity: 2));
      expect(service.getQuantity(id), 2);

      service.deleteProduct(id);
      expect(service.cartItems, isEmpty);
    });
  });
}
