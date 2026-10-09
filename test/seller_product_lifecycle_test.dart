import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dashgrocer/models/grocery_item_model.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/admin/admin_dashboard.dart';
import 'package:dashgrocer/views/customer/customer_home_tab.dart';
import 'package:dashgrocer/views/customer/product_detail_screen.dart';
import 'package:dashgrocer/views/customer/widgets/grocery_product_card.dart';
import 'package:dashgrocer/views/shop_owner/shop_owner_dashboard.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const sellerUser = UserModel(
    id: 'seller_dashgrocer_01',
    email: 'seller@dashgrocer.com',
    fullName: 'DashGrocer Seller',
    phoneNumber: '+94 77 123 4567',
    role: UserRole.shopOwner,
    shopName: 'GreenLeaf Fresh Mart',
    shopAddress: 'No. 42, High Level Road, Maharagama',
  );

  const customerUser = UserModel(
    id: 'customer_01',
    email: 'customer@gmail.com',
    fullName: 'Nimal Silva',
    phoneNumber: '+94 71 234 5678',
    role: UserRole.customer,
  );

  const adminUser = UserModel(
    id: 'admin_01',
    email: 'admin@dashgrocer.com',
    fullName: 'Admin User',
    phoneNumber: '+94 70 111 2222',
    role: UserRole.admin,
  );

  group('Seller Product Full Lifecycle & Multi-View Sync Tests', () {
    test('1. Schema compatibility: GroceryItem serializes and deserializes both schema conventions', () {
      const item = GroceryItem(
        id: 'test_item_schema',
        name: 'Organic Avocados',
        unit: '500g',
        price: 750.0,
        category: 'Fruits',
        imageUrl: 'https://example.com/avocado.png',
        sellerId: 'seller_dashgrocer_01',
        sellerName: 'GreenLeaf Fresh Mart',
        stockQuantity: 25,
        isAvailable: true,
      );

      final map = item.toMap();
      // Verifies both keys written
      expect(map['isAvailable'], isTrue);
      expect(map['isActive'], isTrue);
      expect(map['stockQuantity'], 25);
      expect(map['stock'], 25);
      expect(map['sellerId'], 'seller_dashgrocer_01');
      expect(map['shopId'], 'seller_dashgrocer_01');

      // Reads map with alternative keys (from FirestoreShopRepository)
      final fromShopRepoMap = {
        'id': 'alt_item_1',
        'name': 'Red Dragonfruit',
        'unit': '1 kg',
        'price': 890.0,
        'category': 'Fruits',
        'imageUrl': 'https://example.com/dragonfruit.png',
        'shopId': 'seller_dashgrocer_01',
        'ownerName': 'GreenLeaf Fresh Mart',
        'stock': 12,
        'isAvailable': false,
      };

      final parsed = GroceryItem.fromMap(fromShopRepoMap, 'alt_item_1');
      expect(parsed.name, 'Red Dragonfruit');
      expect(parsed.sellerId, 'seller_dashgrocer_01');
      expect(parsed.stockQuantity, 12);
      expect(parsed.isAvailable, isFalse);
      expect(parsed.isActive, isFalse);
    });

    testWidgets('2. Added product appears on Customer Home; Inactivating hides it immediately', (tester) async {
      final groceryService = GroceryService();

      const newProduct = GroceryItem(
        id: 'product_watermelon_01',
        name: 'Sweet Tropical Watermelon',
        unit: '1 kg',
        price: 320.0,
        category: 'Fruits',
        imageUrl: 'assets/images/watermelon.png',
        sellerId: 'seller_dashgrocer_01',
        sellerName: 'GreenLeaf Fresh Mart',
        stockQuantity: 40,
        isAvailable: true,
      );

      // Add product
      groceryService.addProduct(newProduct);

      // Customer Home should render it
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomerHomeTab(
              user: customerUser,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sweet Tropical Watermelon'), findsOneWidget);

      // Seller toggles availability to FALSE (Inactive)
      groceryService.setProductAvailability('product_watermelon_01', false);
      await tester.pump();

      // Customer Home must no longer show this inactive product
      expect(find.text('Sweet Tropical Watermelon'), findsNothing);

      // Category and search listings must also filter out inactive products
      final fruitItems = groceryService.getCategoryItems('Fruits');
      expect(fruitItems.any((it) => it.id == 'product_watermelon_01'), isFalse);

      final searchResults = groceryService.search('Watermelon');
      expect(searchResults.any((it) => it.id == 'product_watermelon_01'), isFalse);

      // Re-activating brings it back
      groceryService.setProductAvailability('product_watermelon_01', true);
      await tester.pump();
      expect(find.text('Sweet Tropical Watermelon'), findsOneWidget);
    });

    testWidgets('3. Zero stock displays Out of Stock badge and disables Add to Cart', (tester) async {
      final groceryService = GroceryService();

      const zeroStockItem = GroceryItem(
        id: 'item_out_of_stock_test',
        name: 'Fresh Dragonfruit Premium',
        unit: '1 kg',
        price: 900.0,
        category: 'Fruits',
        imageUrl: 'assets/images/apple.png',
        stockQuantity: 0,
        isAvailable: true,
      );

      groceryService.addProduct(zeroStockItem);

      // Render product card
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroceryProductCard(item: zeroStockItem),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Out of Stock'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);

      // Render Product Detail Screen
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductDetailScreen(item: zeroStockItem),
        ),
      );
      await tester.pump();

      expect(find.text('Out of Stock'), findsWidgets);
    });

    testWidgets('4. Seller Dashboard renders Active/Inactive switch and status filter chips', (tester) async {
      final groceryService = GroceryService();

      const itemA = GroceryItem(
        id: 'seller_test_item_a',
        name: 'Organic Celery Bunch',
        unit: '1 bunch',
        price: 250.0,
        category: 'Vegetables',
        imageUrl: 'assets/images/broccoli.png',
        sellerId: 'seller_dashgrocer_01',
        stockQuantity: 15,
        isAvailable: true,
      );

      const itemB = GroceryItem(
        id: 'seller_test_item_b',
        name: 'Purple Cabbage Fresh',
        unit: '500g',
        price: 310.0,
        category: 'Vegetables',
        imageUrl: 'assets/images/cabbage.png',
        sellerId: 'seller_dashgrocer_01',
        stockQuantity: 0,
        isAvailable: false,
      );

      groceryService.addProduct(itemA);
      groceryService.addProduct(itemB);

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopOwnerDashboard(user: sellerUser),
        ),
      );
      await tester.pump();

      // Switch to Products tab
      await tester.tap(find.text('Products'));
      await tester.pump();

      // Verify status filter chips are rendered
      expect(find.text('All'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Inactive'), findsWidgets);
      expect(find.text('Out of Stock'), findsWidgets);

      // Tap Inactive filter chip
      await tester.tap(find.text('Inactive').first);
      await tester.pump();

      expect(find.text('Purple Cabbage Fresh'), findsOneWidget);

      // Delete item and verify it is removed
      groceryService.deleteProduct('seller_test_item_b');
      await tester.pump();
      expect(find.text('Purple Cabbage Fresh'), findsNothing);
    });

    testWidgets('5. Admin Panel displays catalog status and stock numbers accurately', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final groceryService = GroceryService();

      // Seller toggles pumpkin (flagship item of GreenLeaf Fresh Mart) to Inactive
      groceryService.setProductAvailability('pumpkin', false);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboard(user: adminUser),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Shops tab
      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      // Filter for GreenLeaf Fresh Mart
      await tester.enterText(
        find.widgetWithText(TextField, 'Search shops by name, owner, city...'),
        'GreenLeaf',
      );
      await tester.pumpAndSettle();

      // Find an Items button on GreenLeaf shop card and tap it
      final itemsButtons = find.textContaining('Items (');
      expect(itemsButtons, findsAtLeastNWidgets(1));
      await tester.tap(itemsButtons.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Shop Items'), findsAtLeastNWidgets(1));
      expect(find.text('Fresh Pumpkin'), findsOneWidget);
      expect(find.text('Inactive'), findsWidgets);
    });
  });
}
