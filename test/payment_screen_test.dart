import 'package:dashgrocer/services/card_service.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/add_card_screen.dart';
import 'package:dashgrocer/views/customer/my_cards_screen.dart';
import 'package:dashgrocer/views/customer/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildPayment() => const MaterialApp(
        home: PaymentScreen(
          shopName: 'Green mart',
          pickupSlot: 'Today, 4.00 PM',
          totalAmount: 1000,
        ),
      );

  setUp(() {
    final cards = CardService();
    for (final c in List.of(cards.cards)) {
      cards.removeCard(c.id);
    }
  });

  testWidgets('Card payment validates fields before paying', (tester) async {
    await tester.pumpWidget(buildPayment());
    expect(find.text('Payment Method'), findsOneWidget);
    expect(find.text('Make a payment'), findsOneWidget);

    final ordersBefore = GroceryService().sellerOrders.length;
    await tester.ensureVisible(find.text('Make a payment'));
    await tester.tap(find.text('Make a payment'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the name on your card'), findsOneWidget);
    expect(find.text('Enter a valid 16-digit card number'), findsOneWidget);
    expect(GroceryService().sellerOrders.length, ordersBefore);
  });

  testWidgets('Valid new card pays, saves card (last 4 only) and records method', (tester) async {
    await tester.pumpWidget(buildPayment());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Kasun Perera');
    await tester.enterText(fields.at(1), '4242424242424242');
    await tester.enterText(fields.at(2), '1299');
    await tester.enterText(fields.at(3), '123');

    await tester.ensureVisible(find.text('Make a payment'));
    await tester.tap(find.text('Make a payment'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Order Confirmed'), findsOneWidget);
    expect(GroceryService().sellerOrders.first.paymentMethod, 'Paid Online (Card)');
    expect(CardService().cards.length, 1);
    expect(CardService().cards.first.last4, '4242');
    expect(CardService().cards.first.isDefault, isTrue);
  });

  testWidgets('Add Card screen saves a card and My Cards lists it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCardScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Nimali Silva');
    await tester.enterText(fields.at(1), '5555555555554444');
    await tester.enterText(fields.at(2), '0830');
    await tester.enterText(fields.at(3), '999');
    await tester.ensureVisible(find.text('Add credit card'));
    await tester.tap(find.text('Add credit card'));
    await tester.pumpAndSettle();

    expect(CardService().cards.single.last4, '4444');

    await tester.pumpWidget(const MaterialApp(home: MyCardsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('My Cards'), findsOneWidget);
    expect(find.text('Master Card'), findsOneWidget);
    expect(find.text('XXXX XXXX XXXX 4444'), findsOneWidget);
    expect(find.text('DEFAULT'), findsOneWidget);
  });
}
