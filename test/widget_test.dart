import 'package:flutter_test/flutter_test.dart';
import 'package:dashgrocer/main.dart';
import 'package:dashgrocer/services/auth_service.dart';
import 'package:dashgrocer/views/auth/widgets/animated_role_selector.dart';

void main() {
  setUp(() {
    AuthService.simulatedDelay = Duration.zero;
    AuthService().logout();
  });

  testWidgets('DashGrocer auth screen renders successfully with all controls', (WidgetTester tester) async {
    await tester.pumpWidget(const DashGrocerApp());
    await tester.pump(const Duration(milliseconds: 400));

    // Verify brand typography and auth components are present
    expect(find.text('Dash'), findsOneWidget);
    expect(find.text('Grocer'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    // Verify demo quick-fill buttons exist
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Shop Owner'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('Role-Based Access Control: Customer login shows Customer Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const DashGrocerApp());
    await tester.pump(const Duration(milliseconds: 400));

    // Fill customer credentials and submit
    final authService = AuthService();
    await authService.login(
      email: 'customer@dashgrocer.com',
      password: 'pass123',
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify customer dashboard is rendered
    expect(find.text('DashGrocer Customer'), findsOneWidget);
    expect(find.text('CUSTOMER ROLE'), findsOneWidget);
    expect(find.text('Active Pre-Orders'), findsOneWidget);

    // Verify logout returns to Auth Screen
    await tester.tap(find.byTooltip('Sign Out'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Sign In to DashGrocer'), findsOneWidget);
  });

  testWidgets('Role-Based Access Control: Shop Owner login shows Shop Owner Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const DashGrocerApp());
    await tester.pump(const Duration(milliseconds: 400));

    final authService = AuthService();
    await authService.login(
      email: 'owner@dashgrocer.com',
      password: 'pass123',
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify shop owner dashboard is rendered
    expect(find.text('Shop Owner Portal'), findsOneWidget);
    expect(find.text('SHOP OWNER ROLE'), findsOneWidget);
    expect(find.text('GreenLeaf Fresh Mart'), findsOneWidget);
    expect(find.text('Ready for Pickup'), findsOneWidget);
  });

  testWidgets('Dynamic Motion: Switch to Register tab and toggle Shop Owner role reveals store fields', (WidgetTester tester) async {
    await tester.pumpWidget(const DashGrocerApp());
    await tester.pump(const Duration(milliseconds: 400));

    // Tap Create Account tab
    await tester.tap(find.text('Create Account'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Register as:'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);

    // Initially Customer is selected, so store details shouldn't be visible
    expect(find.text('Grocery / Store Name'), findsNothing);

    // Tap Shop Owner in role selector
    await tester.tap(
      find.descendant(
        of: find.byType(AnimatedRoleSelector),
        matching: find.text('Shop Owner'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Store details should now dynamically expand
    expect(find.text('Store Details (Shop Owner)'), findsOneWidget);
    expect(find.text('Grocery / Store Name'), findsOneWidget);
    expect(find.text('Pickup Store Address'), findsOneWidget);
  });
}
