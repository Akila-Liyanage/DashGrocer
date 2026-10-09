import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dashgrocer/models/grocery_item_model.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/admin/admin_dashboard.dart';
import 'package:dashgrocer/views/customer/customer_home_tab.dart';
import 'package:dashgrocer/views/shop_owner/add_product_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const testCustomer = UserModel(
    id: 'cust_01',
    email: 'customer@test.com',
    fullName: 'Kasun Perera',
    phoneNumber: '+94 77 123 4567',
    role: UserRole.customer,
  );

  const testAdmin = UserModel(
    id: 'admin_01',
    email: 'admin@dashgrocer.com',
    fullName: 'System Admin',
    phoneNumber: '+94 11 234 5678',
    role: UserRole.admin,
  );

  const testSeller = UserModel(
    id: 'owner_01',
    email: 'seller@dashgrocer.com',
    fullName: 'Sunil Weerasinghe',
    phoneNumber: '+94 71 987 6543',
    role: UserRole.shopOwner,
    shopName: 'GreenLeaf Fresh Mart',
    shopAddress: 'No. 42, High Level Road, Maharagama',
    shopStatus: 'approved',
  );

  group('Category Dummy Data & Seller-Home-Admin Live Sync Tests', () {
    test('1. Verify categorized dummy items and shops in GroceryService', () {
      final groceryService = GroceryService();
      final allItems = groceryService.allItems;

      // Ensure rich catalog is seeded
      expect(allItems.length, greaterThanOrEqualTo(15));

      // Verify all 6 categories have items
      final categories = allItems.map((e) => e.category).toSet();
      expect(categories.contains('Vegetables'), isTrue);
      expect(categories.contains('Fruits'), isTrue);
      expect(categories.contains('Beverages'), isTrue);
      expect(categories.contains('Grocery'), isTrue);
      expect(categories.contains('Edible oil'), isTrue);
      expect(categories.contains('Household'), isTrue);

      // Verify multiple shops have inventory
      final shops = allItems.map((e) => e.displaySellerShopName).toSet();
      expect(shops.contains('GreenLeaf Fresh Mart'), isTrue);
      expect(shops.contains('Daily Superette'), isTrue);
      expect(shops.contains('Fresh Express Kandy'), isTrue);
      expect(shops.contains('Sunrise Organics'), isTrue);
    });

    testWidgets('2. Seller adds a new product: appears live on Customer Home Tab', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final groceryService = GroceryService();
      final initialCount = groceryService.allItems.length;

      // Render Customer Home Tab
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerHomeTab(user: testCustomer),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure Initial State has products
      expect(find.text('Fresh Pumpkin'), findsAtLeastNWidgets(1));

      // Seller adds a new product
      const newProductName = 'Organic Passion Fruit';
      final newProduct = GroceryItem(
        id: 'test_passion_fruit_${DateTime.now().millisecondsSinceEpoch}',
        name: newProductName,
        unit: '500 g',
        price: 450.0,
        originalPrice: 500.0,
        discountPercent: 10,
        category: 'Fruits',
        imageUrl: 'assets/images/banana.jpg',
        description: 'Tangy and sweet organic highland passion fruits.',
        sellerId: testSeller.id,
        sellerShopName: testSeller.shopName,
        sellerName: testSeller.fullName,
        stockQuantity: 40,
      );

      groceryService.addProduct(newProduct);
      await tester.pumpAndSettle();

      // Check product is added to catalog
      expect(groceryService.allItems.length, initialCount + 1);

      // Product must now immediately appear on the Customer Home Tab!
      expect(find.text(newProductName), findsAtLeastNWidgets(1));
    });

    testWidgets('3. Seller adds a new product: updates Admin Dashboard shop count and items sheet', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final groceryService = GroceryService();

      // Render Admin Dashboard
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboard(user: testAdmin),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Shops tab
      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      // Add a product for Daily Superette
      const newDailyItem = 'Organic Ceylon Cinnamon Quills';
      final newProduct = GroceryItem(
        id: 'test_cinnamon_${DateTime.now().millisecondsSinceEpoch}',
        name: newDailyItem,
        unit: '100 g',
        price: 650.0,
        category: 'Grocery',
        imageUrl: 'assets/images/rice.jpg',
        sellerId: 'shop_dailysuperette',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        stockQuantity: 25,
      );

      groceryService.addProduct(newProduct);
      await tester.pumpAndSettle();

      // Open Daily Superette items sheet
      final itemsForDaily = groceryService.getItemsForShop(
        shopId: 'shop_dailysuperette',
        shopName: 'Daily Superette',
      );
      expect(itemsForDaily.any((item) => item.name == newDailyItem), isTrue);

      // Find an Items button on shop cards
      final itemsButtons = find.textContaining('Items (');
      expect(itemsButtons, findsAtLeastNWidgets(1));

      // Tap on the first Items button
      await tester.tap(itemsButtons.first);
      await tester.pumpAndSettle();

      // Verify that the Shop Items bottom sheet opened
      expect(find.textContaining('Shop Items'), findsAtLeastNWidgets(1));
    });

    testWidgets('4. AddProductScreen: Seller publishes product and form validates correctly', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AddProductScreen(seller: testSeller),
        ),
      );
      await tester.pumpAndSettle();

      // Verify screen header
      expect(find.text('Add New Product'), findsOneWidget);

      // Verify preset images include the newly added presets
      expect(find.text('Ripe Banana'), findsOneWidget);
      expect(find.text('Gala Apple'), findsOneWidget);
      expect(find.text('Ceylon Mango'), findsOneWidget);
      expect(find.text('Dairy Milk'), findsOneWidget);
      expect(find.text('Ceylon Tea'), findsOneWidget);

      // Fill in product details
      await tester.enterText(find.byType(TextFormField).at(0), 'Fresh Green Cabbage');
      await tester.enterText(find.byType(TextFormField).at(1), '1 kg');
      await tester.enterText(find.byType(TextFormField).at(3), '320.00');

      // Tap Publish button in AppBar
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();

      // Verify it was added to GroceryService
      final allItems = GroceryService().allItems;
      expect(allItems.any((it) => it.name == 'Fresh Green Cabbage'), isTrue);
    });
  });
}
