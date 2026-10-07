import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/customer_dashboard.dart';
import 'package:dashgrocer/views/customer/product_detail_screen.dart';
import 'package:dashgrocer/views/customer/category_products_screen.dart';
import 'package:dashgrocer/views/customer/cart_screen.dart';
import 'package:dashgrocer/views/customer/search_screen.dart';
import 'package:dashgrocer/views/customer/pickup_time_screen.dart';
import 'package:dashgrocer/views/customer/order_confirmation_screen.dart';
import 'package:dashgrocer/views/customer/order_history_screen.dart';
import 'package:dashgrocer/views/customer/track_order_screen.dart';
import 'package:dashgrocer/views/customer/reviews_screen.dart';
import 'package:dashgrocer/services/auth_service.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GroceryService();
  });

  group('Figma 5-Screen Implementation Tests', () {
    testWidgets('1. Home Screen: renders customer dashboard with home tab and categories', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDashboard(user: AuthService.demoUsers.first),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Hi, Kasun 👋'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Vegetables'), findsOneWidget);
    });

    testWidgets('2. Product Detail Screen: renders Fresh Pumpkin with price, rating, quantity stepper & add to cart', (tester) async {
      final groceryService = GroceryService();
      final item = groceryService.getItemById('pumpkin')!;

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailScreen(item: item),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fresh Pumpkin'), findsOneWidget);
      expect(find.text('Rs. 420.00'), findsOneWidget);
      expect(find.text('1 kg'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('Add to cart'), findsOneWidget);
    });

    testWidgets('3. Products / Category Screen: renders Vegetables with filter and products grid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryProductsScreen(categoryName: 'Vegetables'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.text('Fresh Pumpkin'), findsOneWidget);
      expect(find.text('Ripe Tomatoes'), findsOneWidget);
    });

    testWidgets('4. Cart Screen: renders items, calculations and Checkout button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CartScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shopping Cart'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Shipping charges'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets('5. Search Screen: renders search input, Search History, Discover more, Image & Voice Search', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Search keywords...'), findsOneWidget);
      expect(find.text('Search History'), findsOneWidget);
      expect(find.text('Discover more'), findsOneWidget);
      expect(find.text('Image Search'), findsOneWidget);
      expect(find.text('Voice Search'), findsOneWidget);
    });

    testWidgets('6. Pickup Time Screen: renders store info, date slots and Continue to Payment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PickupTimeScreen(shopName: 'Green mart', totalAmount: 1000.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pickup Time'), findsOneWidget);
      expect(find.text('Green mart'), findsOneWidget);
      expect(find.text('Today , Mon 10 Aug'), findsOneWidget);
      expect(find.text('Tomorrow , Tue 11 Aug'), findsOneWidget);
      expect(find.text('Continue to Payment'), findsOneWidget);
    });

    testWidgets('7. Order Confirmation Screen: renders Thank You!, order summary and Track Order button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OrderConfirmationScreen(orderId: '#FP-2028-0142'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.text('Thank You!'), findsOneWidget);
      expect(find.text('#FP-2028-0142 has been placed'), findsOneWidget);
      expect(find.text('Track Order'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('8. Order History Screen: renders notification, search bar, active orders and past orders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OrderHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order History'), findsOneWidget);
      expect(find.text('Search keywords...'), findsOneWidget);
      expect(find.text('Ready for pickup at 4:00 PM today'), findsOneWidget);
      expect(find.text('#FP-2028-0142'), findsOneWidget);
      expect(find.text('Track Order'), findsWidgets);
    });

    testWidgets('9. Track Order Screen: renders header, vertical stepper timeline and Order Confirmed button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrackOrderScreen(orderId: '#FP-2028-0142'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Track Order'), findsOneWidget);
      expect(find.text('Order #FP-2028-0142'), findsOneWidget);
      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('Order Confirmed'), findsWidgets);
      expect(find.text('Ready for Pickup'), findsOneWidget);
    });

    testWidgets('10. Reviews Screen: renders rating score, distribution bars, write review, filters and review cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReviewsScreen(productName: 'Fresh Produce'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reviews'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('125 Reviews'), findsOneWidget);
      expect(find.text('Write a review'), findsOneWidget);
      expect(find.text('Olivia'), findsOneWidget);
      expect(find.text('Back To Home'), findsOneWidget);
    });

    testWidgets('11. Reviews Screen: tapping Write a review opens modal and allows submitting new review', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReviewsScreen(productName: 'Fresh Organic Apples'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Write a review card
      await tester.tap(find.text('Write a review'));
      await tester.pumpAndSettle();

      // Modal should be displayed
      expect(find.text('Write a Review'), findsOneWidget);
      expect(find.text('Overall Rating'), findsOneWidget);
      expect(find.text('Submit Review'), findsOneWidget);

      // Enter review comment in text field
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2)); // comment field and name field
      await tester.enterText(textFields.first, 'Excellent crisp apples and very quick pickup!');
      await tester.pumpAndSettle();

      // Tap Submit Review button
      await tester.tap(find.text('Submit Review'));
      await tester.pumpAndSettle();

      // Modal closes, review count updates, new review is displayed in list
      expect(find.text('126 Reviews'), findsOneWidget);
      expect(find.text('Excellent crisp apples and very quick pickup!'), findsOneWidget);
    });

    testWidgets('12. Home Screen: tapping notification bell opens Notifications sheet with items and Mark read', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDashboard(user: AuthService.demoUsers.first),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Find notification bell icon and unread badge
      expect(find.byTooltip('Notifications'), findsOneWidget);
      expect(find.byKey(const ValueKey('customer_notif_badge')), findsOneWidget);

      // Tap Notification button
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();

      // Notifications sheet displayed
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Mark read'), findsOneWidget);
      expect(find.text('Order Placed: #FP-2028-0142'), findsWidgets);

      // Tap 'Mark read'
      await tester.tap(find.text('Mark read'));
      await tester.pumpAndSettle();

      // Unread badge is cleared
      expect(find.byKey(const ValueKey('customer_notif_badge')), findsNothing);
    });
  });
}
