import 'package:dashgrocer/models/grocery_item_model.dart';
import 'package:dashgrocer/services/database_seeder.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('The demo catalog has products customers can buy', () {
    final demo = GroceryService().demoCatalog;
    expect(demo.length, greaterThan(20));
    expect(demo.every((item) => item.isAvailable && item.stockQuantity > 0), isTrue);
    expect(demo.map((i) => i.id).toSet().length, demo.length); // no duplicate ids
    // Each call gives a fresh copy, independent of the live catalog
    expect(identical(GroceryService().demoCatalog, demo), isFalse);
  });

  test('A catalog with nothing for sale is detected', () {
    const outOfStock = GroceryItem(
      id: 'item_1',
      name: 'Rice 11',
      unit: 'kg',
      price: 100,
      imageUrl: '',
      circleColor: Color(0xFFE8F6EB),
      category: 'Vegetables',
      stockQuantity: 0,
    );
    expect(DatabaseSeeder.hasProductForSale(const <GroceryItem>[]), isFalse);
    expect(DatabaseSeeder.hasProductForSale([outOfStock]), isFalse);
    expect(DatabaseSeeder.hasProductForSale([outOfStock, ...GroceryService().demoCatalog]), isTrue);
    expect(DatabaseSeeder.hasProductForSale([outOfStock.copyWith(stockQuantity: 5)]), isTrue);
    expect(DatabaseSeeder.hasProductForSale([outOfStock.copyWith(stockQuantity: 5, isAvailable: false)]), isFalse);
  });
}
