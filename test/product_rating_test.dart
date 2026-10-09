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

    // No reviews yet: not the old fixed "4.9 (110 reviews)", and no "0.0" either
    expect(find.text('No reviews yet • Be the first to review'), findsOneWidget);
    expect(find.textContaining('110'), findsNothing);
    expect(find.text('0.0'), findsNothing);
    expect(ReviewService().statsFor(item.name).count, 0);

    // A 1-star review arrives while the page is open
    ReviewService().addReview(productName: item.name, name: 'Nimali', rating: 1, comment: 'Not fresh');
    await tester.pump();
    expect(find.text('(1 review)'), findsOneWidget);
    expect(find.text('1.0'), findsOneWidget);

    // A 4-star review follows: average (1 + 4) / 2 = 2.5, same numbers as the Reviews screen
    ReviewService().addReview(productName: item.name, name: 'Kasun', rating: 4, comment: 'Fresh');
    await tester.pump();
    expect(find.text('(2 reviews)'), findsOneWidget);
    expect(find.text('2.5'), findsOneWidget);
    expect(ReviewService().statsFor(item.name).count, 2);
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
