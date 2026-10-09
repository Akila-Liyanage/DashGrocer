import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/services/review_service.dart';
import 'package:dashgrocer/views/customer/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Product page rating comes from the real reviews and updates live', (tester) async {
    final item = GroceryService().getItemById('carrot')!;
    await tester.pumpWidget(MaterialApp(home: ProductDetailScreen(item: item)));
    await tester.pumpAndSettle();

    // Not the old fixed "4.9 (110 reviews)": only the 3 starter reviews exist (5, 4, 5)
    expect(find.text('4.7'), findsOneWidget);
    expect(find.text('(3 reviews)'), findsOneWidget);
    expect(find.textContaining('110'), findsNothing);

    // Same numbers as the Reviews screen
    final stats = ReviewService().statsFor(item.name);
    expect(stats.count, 3);

    // A 1-star review arrives while the page is open
    ReviewService().addReview(productName: item.name, name: 'Nimali', rating: 1, comment: 'Not fresh');
    await tester.pump();
    expect(find.text('(4 reviews)'), findsOneWidget);
    expect(find.text('3.8'), findsOneWidget); // (5 + 4 + 5 + 1) / 4 = 3.75
  });

  test('Review stats: count, average and star counts', () {
    final stats = ReviewStats.from([
      {'rating': 5},
      {'rating': 5},
      {'rating': 3},
    ]);
    expect(stats.count, 3);
    expect(stats.average, closeTo(4.333, 0.001));
    expect(stats.starCounts, {5: 2, 4: 0, 3: 1, 2: 0, 1: 0});
    expect(stats.countLabel, '3 reviews');
    expect(ReviewStats.from([{'rating': 4}]).countLabel, '1 review');
    expect(ReviewStats.from(const []).average, 0);
  });
}
