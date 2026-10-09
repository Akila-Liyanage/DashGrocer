import 'package:dashgrocer/models/grocery_item_model.dart';
import 'package:dashgrocer/models/owner_profile.dart';
import 'package:dashgrocer/models/product.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/services/grocery_shop_repository.dart';
import 'package:dashgrocer/services/mock_shop_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product photo removal', () {
    late GroceryShopRepository repository;
    final service = GroceryService();

    setUp(() {
      repository = GroceryShopRepository(
        profiles: MockShopRepository(),
        sellerId: 'owner_01',
        sellerName: 'GreenLeaf Fresh Mart',
        fallbackOwner: const OwnerProfile(id: 'owner_01'),
      );
    });

    test('1. A product saved without a photo reads back without one', () {
      final saved = GroceryItem.fromMap({
        'name': 'Plain Flour',
        'price': 250,
        'imageUrl': '',
      }, 'item_flour');

      expect(saved.imageUrl, isEmpty);
    });

    test('2. Removing the photo updates the customer catalog item', () async {
      final product = (await repository.watchProducts('owner_01').first)
          .firstWhere((p) => p.id == 'pumpkin');
      expect(product.imageUrl, isNotNull);

      await repository.saveProduct(
        Product(
          id: product.id,
          shopId: product.shopId,
          name: 'Sweet Pumpkin',
          category: product.category,
          unit: product.unit,
          price: 199,
          stock: product.stock,
        ),
      );

      // The customer screens read this same item from GroceryService.
      final item = service.allItems.firstWhere((it) => it.id == 'pumpkin');
      expect(item.imageUrl, isEmpty);
      expect(item.name, 'Sweet Pumpkin');
      expect(item.price, 199);

      // Survives the round trip through Firestore's map form.
      expect(GroceryItem.fromMap(item.toMap(), item.id).imageUrl, isEmpty);
    });

    test('3. A new product without a photo gets no stand-in picture', () async {
      await repository.saveProduct(
        const Product(
          id: '',
          shopId: 'owner_01',
          name: 'Photo-less Lentils',
          category: 'Grocery',
          unit: 'kg',
          price: 320,
          stock: 5,
        ),
      );

      final item =
          service.allItems.firstWhere((it) => it.name == 'Photo-less Lentils');
      expect(item.imageUrl, isEmpty);
    });
  });
}
