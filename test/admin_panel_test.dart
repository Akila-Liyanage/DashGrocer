import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'package:dashgrocer/services/auth_service.dart';
import 'package:dashgrocer/views/admin/admin_dashboard.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const adminUser = UserModel(
    id: 'admin_test_01',
    email: 'admin@dashgrocer.com',
    fullName: 'System Administrator',
    phoneNumber: '+94 11 234 5678',
    role: UserRole.admin,
  );

  group('Admin Panel & Database Shop Moderation Unit Tests', () {
    test('1. New shop owner registration initializes with pending approval status', () async {
      final authService = AuthService();
      final testEmail = 'newowner_${DateTime.now().millisecondsSinceEpoch}@test.com';

      final success = await authService.register(
        fullName: 'Nimal Bandara',
        email: testEmail,
        phoneNumber: '+94 77 987 6543',
        password: 'Password123!',
        role: UserRole.shopOwner,
        shopName: 'Bandara Fresh Veggies',
        shopAddress: 'No. 55, Colombo Road, Gampaha',
      );

      expect(success, isTrue);
      expect(authService.currentUser?.role, UserRole.shopOwner);
      expect(authService.currentUser?.shopStatus, 'pending');
      expect(authService.currentUser?.isShopPending, isTrue);
    });

    test('2. Admin can approve a pending shop and update status to approved', () async {
      final authService = AuthService();
      const shopId = 'owner_kandy';

      // Initially owner_kandy is pending
      final shops = await authService.watchAllShops().first;
      final kandyShop = shops.firstWhere((s) => s.id == shopId);
      expect(kandyShop.isPending, isTrue);

      // Admin approves
      await authService.approveShop(shopId);

      final updatedShops = await authService.watchAllShops().first;
      final approvedShop = updatedShops.firstWhere((s) => s.id == shopId);
      expect(approvedShop.isApproved, isTrue);
      expect(approvedShop.status, 'approved');
    });

    test('3. Admin can reject a shop registration with reason', () async {
      final authService = AuthService();
      const shopId = 'owner_kandy';

      await authService.rejectShop(
        shopId,
        reason: 'Incomplete business registration and invalid trade permit',
      );

      final updatedShops = await authService.watchAllShops().first;
      final rejectedShop = updatedShops.firstWhere((s) => s.id == shopId);
      expect(rejectedShop.isRejected, isTrue);
      expect(rejectedShop.rejectionReason, contains('trade permit'));
    });

    test('4. Admin can suspend an approved shop back to pending review', () async {
      final authService = AuthService();
      const shopId = 'owner_01'; // GreenLeaf Fresh Mart

      await authService.suspendShop(shopId);

      final updatedShops = await authService.watchAllShops().first;
      final suspendedShop = updatedShops.firstWhere((s) => s.id == shopId);
      expect(suspendedShop.isPending, isTrue);

      // Restore it to approved
      await authService.approveShop(shopId);
    });
  });

  group('Admin Panel Dashboard Widget Tests', () {
    testWidgets('5. AdminDashboard displays live metrics and 4 navigation tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboard(user: adminUser),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('ADMIN CONSOLE'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('DashGrocer Platform'), findsOneWidget);

      // 4 Tabs
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Shops'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Owners'), findsOneWidget);

      // Live metric titles (premium gradient stat cards)
      expect(find.text('Total Users'), findsOneWidget);
      expect(find.text('Pending'), findsAtLeastNWidgets(1));
      expect(find.text('Active Shops'), findsOneWidget);
      expect(find.text('Rejected'), findsAtLeastNWidgets(1));
    });

    testWidgets('6. Checking Customers separately shows customer list and details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboard(user: adminUser),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Customers tab (index 2)
      await tester.tap(find.text('Customers'));
      await tester.pumpAndSettle();

      // Customer account should appear
      expect(find.text('Kasun Perera'), findsOneWidget);
      expect(find.text('customer@dashgrocer.com'), findsOneWidget);
      expect(find.text('+94 77 123 4567'), findsOneWidget);
      expect(find.text('Customer'), findsAtLeastNWidgets(1));
    });

    testWidgets('7. Checking Shop Owners separately shows owner details and shop names', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboard(user: adminUser),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Shop Owners tab (index 3)
      await tester.tap(find.text('Owners'));
      await tester.pumpAndSettle();

      // Shop owner account should appear
      expect(find.text('GreenLeaf Fresh Mart'), findsAtLeastNWidgets(1));
      expect(find.text('Owner: Sunil Weerasinghe'), findsAtLeastNWidgets(1));
      expect(find.text('+94 71 987 6543'), findsAtLeastNWidgets(1));
    });

    testWidgets('8. Admin can switch to Shops tab and filter by status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboard(user: adminUser),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Shops tab (index 1)
      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      // Verify filter chips exist (some labels like 'Pending'/'Rejected' also
      // appear as stat card titles in the overview tab within the TabBarView)
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsAtLeastNWidgets(1));
      expect(find.text('Approved'), findsAtLeastNWidgets(1));
      expect(find.text('Rejected'), findsAtLeastNWidgets(1));

      // Filter by Pending (use .first since label appears in stat cards too)
      await tester.tap(find.text('Pending').first);
      await tester.pumpAndSettle();

      // Verify pending shop action buttons are rendered
      expect(find.text('Details'), findsAtLeastNWidgets(1));
    });

    testWidgets('9. Admin clicking on a shop displays all shop grocery items with details', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboard(user: adminUser),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Shops tab
      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      // Find an Items button on a shop card and tap it
      final itemsButtons = find.textContaining('Items (');
      expect(itemsButtons, findsAtLeastNWidgets(1));
      await tester.tap(itemsButtons.first);
      await tester.pumpAndSettle();

      // Verify that the Shop Items bottom sheet opened
      expect(find.textContaining('Shop Items'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Products Listed'), findsOneWidget);

      // Verify search input for items is available
      expect(find.textContaining('Search items in'), findsOneWidget);

      // Verify item list or item cards are rendered
      expect(find.textContaining('Stock:'), findsAtLeastNWidgets(1));
    });

    testWidgets('10. Admin can switch to Sales tab and view live sales analytics and order records', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboard(user: adminUser),
        ),
      );
      await tester.pumpAndSettle();

      // Check Sales tab exists
      expect(find.text('Sales'), findsOneWidget);

      // Switch to Sales tab
      await tester.tap(find.text('Sales'));
      await tester.pumpAndSettle();

      // Verify time range filters
      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);

      // Verify financial stat card labels
      expect(find.text('Gross Revenue'), findsAtLeastNWidgets(1));
      expect(find.text('Completed Orders'), findsOneWidget);
      expect(find.text('Avg Order Value'), findsOneWidget);
      expect(find.text('Active Pipeline'), findsOneWidget);

      // Verify Store Revenue Breakdown leaderboard
      expect(find.text('Store Revenue Breakdown'), findsOneWidget);

      // Verify Orders Ledger and order cards
      expect(find.text('Orders Ledger'), findsOneWidget);
      expect(find.textContaining('GreenLeaf Fresh Mart'), findsAtLeastNWidgets(1));

      // Tap on an order card to open order details dialog
      final orderItem = find.textContaining('#FP-2028-').first;
      await tester.ensureVisible(orderItem);
      await tester.tap(orderItem);
      await tester.pumpAndSettle();

      // Verify Order Details modal sheet
      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('TRANSACTION INFORMATION'), findsOneWidget);
      expect(find.text('ORDER ITEMS SUMMARY'), findsOneWidget);
      expect(find.text('Copy Order ID'), findsOneWidget);
    });
  });
}

