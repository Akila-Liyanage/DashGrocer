import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/customer_dashboard.dart';
import 'package:dashgrocer/views/customer/store_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const testUser = UserModel(
    id: 'user_test_1',
    email: 'kasun@dashgrocer.com',
    fullName: 'Kasun Perera',
    phoneNumber: '+94 77 123 4567',
    role: UserRole.customer,
  );

  const sampleShop = {
    'id': 'shop_greenleaf',
    'name': 'GreenLeaf Fresh Mart',
    'ownerName': 'Sunil Weerasinghe',
    'distance': '1.2 km',
    'pickupTime': 'Ready in 20m',
    'rating': '4.8',
    'reviewsCount': '120+ reviews',
    'address': 'No. 42, High Level Road, Maharagama',
    'phone': '+94 71 987 6543',
    'hours': 'Open Daily: 7:30 AM – 9:30 PM (Closes at 10:00 PM on weekends)',
    'curbside': 'Instant counter pickup with zero waiting queue',
    'description': 'Specializing in fresh highland vegetables, crisp greens, and farm produce with curbside pickup.',
    'badge': 'Verified Partner',
  };

  group('Store Details & Products Tests', () {
    testWidgets('1. StoreDetailsScreen: displays store header, actions, and products catalog', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StoreDetailsScreen(shop: sampleShop),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Store details in header
      expect(find.text('GreenLeaf Fresh Mart'), findsAtLeastNWidgets(1));
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('4.8 (120+ reviews)'), findsOneWidget);
      expect(find.text('1.2 km away'), findsOneWidget);
      expect(find.text('Ready in 20m'), findsOneWidget);
      expect(find.text('Call Store'), findsOneWidget);
      expect(find.text('Chat Store'), findsOneWidget);
      expect(find.text('Store Catalog'), findsOneWidget);

      // Verify Products listed in store catalog
      expect(find.text('Fresh Pumpkin'), findsOneWidget);
      expect(find.text('Ripe Tomatoes'), findsOneWidget);
    });

    testWidgets('2. Flow: Clicking "Browse Stock" in Bottom Sheet navigates to StoreDetailsScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerDashboard(user: testUser),
        ),
      );
      await tester.pumpAndSettle();

      // Find and scroll until the GreenLeaf Fresh Mart card is visible
      final shopCardFinder = find.text('GreenLeaf Fresh Mart');
      await tester.scrollUntilVisible(shopCardFinder, 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(shopCardFinder, findsOneWidget);
      await tester.tap(shopCardFinder);
      await tester.pumpAndSettle();

      // Bottom sheet is now open
      expect(find.text('Browse Stock'), findsOneWidget);
      expect(find.text('Distance & Pickup'), findsOneWidget);
      expect(find.text('Curbside Pickup'), findsOneWidget);

      // Tap Browse Stock
      await tester.tap(find.text('Browse Stock'));
      await tester.pumpAndSettle();

      // Now on StoreDetailsScreen
      expect(find.text('Store Catalog'), findsOneWidget);
      expect(find.text('Fresh Pumpkin'), findsOneWidget);
      expect(find.text('Ripe Tomatoes'), findsOneWidget);
      expect(find.text('Chat Store'), findsOneWidget);
    });

    testWidgets('3. StoreDetailsScreen: in-store search filters products correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StoreDetailsScreen(shop: sampleShop),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state has products
      expect(find.text('Fresh Pumpkin'), findsOneWidget);

      // Enter search term
      await tester.enterText(find.byType(TextField), 'Pumpkin');
      await tester.pumpAndSettle();

      expect(find.text('Fresh Pumpkin'), findsOneWidget);
      expect(find.text('Ripe Tomatoes'), findsNothing);
    });
  });
}
