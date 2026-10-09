import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(WidgetTester tester, String id) async {
  final item = GroceryService().getItemById(id)!;
  await tester.pumpWidget(MaterialApp(home: ProductDetailScreen(key: ValueKey(id), item: item)));
  await tester.pumpAndSettle();
}

/// The number between the - and + buttons of the Quantity row.
Finder get _quantityValue => find.descendant(
      of: find.ancestor(of: find.text('Quantity'), matching: find.byType(Container)).first,
      matching: find.byWidgetPredicate((w) => w is Text && RegExp(r'^\d+$').hasMatch(w.data ?? '')),
    );

String _shownQuantity(WidgetTester tester) => tester.widget<Text>(_quantityValue.first).data!;

void main() {
  setUp(() => GroceryService().clearCart());

  testWidgets('Every product starts with a quantity of 1, not 3', (tester) async {
    for (final id in ['carrot', 'tomato', 'pumpkin']) {
      await _open(tester, id);
      expect(_shownQuantity(tester), '1', reason: '$id should start at 1');
    }
  });

  testWidgets('A product already in the cart shows the amount that is in the cart', (tester) async {
    GroceryService().addToCart('carrot', 4);
    await _open(tester, 'carrot');
    expect(_shownQuantity(tester), '4');

    // A different product still starts at 1
    await _open(tester, 'tomato');
    expect(_shownQuantity(tester), '1');
  });

  testWidgets('The + and - buttons change the quantity and it never goes below 1', (tester) async {
    await _open(tester, 'carrot');

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(_shownQuantity(tester), '2');

    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pump();
    expect(_shownQuantity(tester), '1');
  });
}
