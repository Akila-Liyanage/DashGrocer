import 'package:dashgrocer/views/customer/order_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OrderHistoryScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('Order History search filters orders by keyword', (tester) async {
    await openScreen(tester);

    // Both orders are visible before searching
    expect(find.text('#FP-2028-0142'), findsWidgets);
    expect(find.text('#FP-2025-8341'), findsOneWidget);

    // Search by order id
    await tester.enterText(find.byType(TextField), '8341');
    await tester.pumpAndSettle();
    expect(find.text('#FP-2025-8341'), findsOneWidget);
    expect(find.text('Active'), findsNWidgets(1)); // only the filter pill, no Active section
    expect(find.text('PREPARING'), findsNothing);

    // Search by status (case-insensitive)
    await tester.enterText(find.byType(TextField), 'preparing');
    await tester.pumpAndSettle();
    expect(find.text('PREPARING'), findsOneWidget);
    expect(find.text('COMPLETED'), findsNothing);
    expect(find.text('1 order'), findsOneWidget);

    // Search by price
    await tester.enterText(find.byType(TextField), 'rs. 500');
    await tester.pumpAndSettle();
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('PREPARING'), findsNothing);
  });

  testWidgets('Order History search shows empty state and can be cleared', (tester) async {
    await openScreen(tester);

    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    await tester.pumpAndSettle();
    expect(find.text('No orders found'), findsOneWidget);
    expect(find.text('PREPARING'), findsNothing);
    expect(find.text('COMPLETED'), findsNothing);

    // Clear (x) brings everything back
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('No orders found'), findsNothing);
    expect(find.text('PREPARING'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
  });

  testWidgets('Order History search works together with the filter pills', (tester) async {
    await openScreen(tester);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('PREPARING'), findsNothing);

    // Searching for an active order inside the Completed tab finds nothing
    await tester.enterText(find.byType(TextField), '0142');
    await tester.pumpAndSettle();
    expect(find.text('No orders found'), findsOneWidget);
  });
}
