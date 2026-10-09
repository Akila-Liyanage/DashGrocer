import 'package:dashgrocer/services/card_service.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/add_card_screen.dart';
import 'package:dashgrocer/views/customer/my_cards_screen.dart';
import 'package:dashgrocer/views/customer/payment_screen.dart';
import 'package:dashgrocer/views/customer/widgets/card_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  paymentChecks();
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
    GroceryService().clearCart();
    GroceryService().addToCart('carrot', 1);
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
    // The receipt says how it was paid, and that the money was taken now
    expect(find.text('Visa •••• 4242'), findsOneWidget);
    expect(find.text('Total Paid'), findsOneWidget);
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

void paymentChecks() {
  Widget buildPayment() => const MaterialApp(
        home: PaymentScreen(
          shopName: 'Green mart',
          pickupSlot: 'Today, 4.00 PM',
          totalAmount: 1000,
        ),
      );

  Future<void> fillCard(WidgetTester tester, {String number = '4242424242424242'}) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Kasun Perera');
    await tester.enterText(fields.at(1), number);
    await tester.enterText(fields.at(2), '1299');
    await tester.enterText(fields.at(3), '123');
  }

  setUp(() {
    final cards = CardService();
    for (final c in List.of(cards.cards)) {
      cards.removeCard(c.id);
    }
    GroceryService().clearCart();
    GroceryService().addToCart('tomato', 1);
  });

  test('Luhn check accepts real card numbers and rejects made-up ones', () {
    expect(CardValidators.passesLuhn('4242424242424242'), isTrue);
    expect(CardValidators.passesLuhn('5555555555554444'), isTrue);
    expect(CardValidators.passesLuhn('1111111111111111'), isFalse);
    expect(CardValidators.passesLuhn('4242424242424241'), isFalse);
    expect(CardValidators.cardNumber('4242 4242 4242 4242'), isNull);
    expect(CardValidators.cardNumber('1111 1111 1111 1111'), isNotNull);
    expect(CardValidators.cardNumber('4242 4242'), isNotNull);
  });

  testWidgets('A made-up card number is rejected and no order is created', (tester) async {
    await tester.pumpWidget(buildPayment());
    await fillCard(tester, number: '1111111111111111');

    final ordersBefore = GroceryService().sellerOrders.length;
    await tester.ensureVisible(find.text('Make a payment'));
    await tester.tap(find.text('Make a payment'));
    await tester.pumpAndSettle();

    expect(find.text('This card number is not valid. Please check it.'), findsOneWidget);
    expect(find.text('Order Confirmed'), findsNothing);
    expect(GroceryService().sellerOrders.length, ordersBefore);
  });

  testWidgets('A mistake in a field shows as soon as the customer leaves it', (tester) async {
    await tester.pumpWidget(buildPayment());

    // Card number typed wrongly: the message shows without pressing the pay button
    await tester.enterText(find.byType(TextFormField).at(1), '1111111111111111');
    await tester.pump();
    expect(find.text('This card number is not valid. Please check it.'), findsOneWidget);
  });

  testWidgets('An empty cart cannot be paid for', (tester) async {
    GroceryService().clearCart();
    await tester.pumpWidget(buildPayment());
    await fillCard(tester);

    final ordersBefore = GroceryService().sellerOrders.length;
    await tester.ensureVisible(find.text('Make a payment'));
    await tester.tap(find.text('Make a payment'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Your cart is empty. Add items before paying.'), findsOneWidget);
    expect(find.text('Order Confirmed'), findsNothing);
    expect(GroceryService().sellerOrders.length, ordersBefore);
  });

  testWidgets('Pay at Store says the total is still to be paid at the shop', (tester) async {
    await tester.pumpWidget(buildPayment());

    await tester.tap(find.text('Pay at Store'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Order Confirmed'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Pay at Store'), findsOneWidget);
    expect(find.text('To pay at store'), findsOneWidget);
    expect(find.text('Total Paid'), findsNothing);
    expect(GroceryService().sellerOrders.first.paymentMethod, 'Pay at Store');
  });

  testWidgets('A saved card pays with only the CVV and shows on the receipt', (tester) async {
    CardService().addCard(
      cardNumber: '5555555555554444',
      holderName: 'Nimali Silva',
      expiry: '08/30',
    );
    await tester.pumpWidget(buildPayment());

    // Only the CVV is asked for
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '999');
    await tester.ensureVisible(find.text('Make a payment'));
    await tester.tap(find.text('Make a payment'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Mastercard •••• 4444'), findsOneWidget);
    expect(find.text('Total Paid'), findsOneWidget);
  });
}
