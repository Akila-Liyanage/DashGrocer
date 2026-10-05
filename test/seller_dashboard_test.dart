import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashgrocer/models/grocery_item_model.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/shop_owner/shop_owner_dashboard.dart';
import 'package:dashgrocer/views/shop_owner/add_product_screen.dart';
import 'package:dashgrocer/views/shop_owner/seller_notifications_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const testSeller = UserModel(
    id: 'owner_01',
    email: 'owner@dashgrocer.com',
    fullName: 'Sunil Weerasinghe',
    phoneNumber: '+94 71 987 6543',
    role: UserRole.shopOwner,
    shopName: 'GreenLeaf Fresh Mart',
    shopAddress: 'No. 42, High Level Road, Maharagama',
  );

  test('Direct Catalog Sync: Added seller product appears immediately in customer allItems', () {
    final groceryService = GroceryService();
    final initialCount = groceryService.allItems.length;

    const newProduct = GroceryItem(
      id: 'test_product_123',
      name: 'Organic Sweet Mango',
      unit: '1 kg',
      price: 650.0,
      category: 'Fruits',
      imageUrl: 'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&w=500&q=80',
      sellerId: 'owner_01',
      sellerName: 'GreenLeaf Fresh Mart',
    );

    groceryService.addProduct(newProduct);

    // Verify product count incremented
    expect(groceryService.allItems.length, initialCount + 1);

    // Verify it is the first item on customer home / allItems
    expect(groceryService.allItems.first.name, 'Organic Sweet Mango');
    expect(groceryService.allItems.first.price, 650.0);
  });

  test('Customer Order triggers live Seller Notification and adds to Store Orders', () {
    final groceryService = GroceryService();
    final initialOrdersCount = groceryService.sellerOrders.length;
    final initialNotifsCount = groceryService.sellerNotifications.length;

    final orderId = groceryService.placeOrder(
      customerName: 'Dinuka Senanayake',
      customerPhone: '+94 77 999 1122',
      pickupSlot: 'Tomorrow, 11:00 AM',
      totalAmount: 2450.0,
      shopName: 'GreenLeaf Fresh Mart',
    );

    // Verify order was created
    expect(groceryService.sellerOrders.length, initialOrdersCount + 1);
    expect(groceryService.sellerOrders.first.id, orderId);
    expect(groceryService.sellerOrders.first.customerName, 'Dinuka Senanayake');
    expect(groceryService.sellerOrders.first.totalAmount, 2450.0);

    // Verify notification was sent to seller
    expect(groceryService.sellerNotifications.length, initialNotifsCount + 1);
    expect(groceryService.sellerNotifications.first.message.contains('Dinuka Senanayake'), isTrue);
  });

  testWidgets('Seller Dashboard renders 3 tabs: Orders, Products, Analytics', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShopOwnerDashboard(user: testSeller),
      ),
    );
    await tester.pump();

    // Verify Header
    expect(find.text('GreenLeaf Fresh Mart'), findsOneWidget);
    expect(find.text('Open for Pickup'), findsOneWidget);

    // Verify Tab Bar items
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);

    // Switch to Products Tab
    await tester.tap(find.text('Products'));
    await tester.pump();
    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('Direct Sync: All products appear live on Customer DashGrocer'), findsOneWidget);

    // Switch to Analytics Tab
    await tester.tap(find.text('Analytics'));
    await tester.pump();
    expect(find.text('TOTAL GROSS REVENUE'), findsOneWidget);
    expect(find.text('Weekly Sales Velocity'), findsOneWidget);
    expect(find.text('Top Selling Products'), findsOneWidget);
  });

  testWidgets('AddProductScreen renders form and preset photo selector', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AddProductScreen(seller: testSeller),
      ),
    );
    await tester.pump();

    expect(find.text('Add New Product'), findsOneWidget);
    expect(find.text('Product Name *'), findsOneWidget);
    expect(find.text('Category *'), findsOneWidget);
    expect(find.text('Selling Price (Rs.) *'), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);
  });

  testWidgets('SellerNotificationsSheet renders incoming customer order notifications', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SellerNotificationsSheet(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Store Notifications'), findsOneWidget);
  });
}
