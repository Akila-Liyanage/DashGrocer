import 'package:dashgrocer/services/review_service.dart';
import 'package:dashgrocer/views/customer/reviews_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(WidgetTester tester, String product) async {
  await tester.pumpWidget(MaterialApp(home: ReviewsScreen(key: ValueKey(product), productName: product)));
  await tester.pumpAndSettle();
}

void _add(String product, int rating, String comment, {String name = 'Tester'}) {
  ReviewService().addReview(productName: product, name: name, rating: rating, comment: comment);
}

void main() {
  testWidgets('A product with no reviews shows an empty state, not made-up reviews', (tester) async {
    await _open(tester, 'Fresh Product');

    expect(find.text('No reviews yet'), findsOneWidget); // under the score
    expect(find.text('–'), findsOneWidget);
    expect(find.text('All (0)'), findsOneWidget);
    expect(find.text('No reviews yet. Be the first to write one!'), findsOneWidget);
    // The old starter reviews are gone from every product
    expect(find.text('Olivia'), findsNothing);
    expect(find.text('Da Silva'), findsNothing);
    expect(find.text('Kasun Perera'), findsNothing);
  });

  testWidgets('Rating summary counts only the reviews that exist and updates live', (tester) async {
    const product = 'Live Product';
    await _open(tester, product);

    // Two reviews arrive while the screen is open (for example from another phone)
    _add(product, 5, 'Great');
    _add(product, 4, 'Good');
    await tester.pump();

    expect(find.text('2 Reviews'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget); // (5 + 4) / 2
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('5 ★ (1)'), findsOneWidget);
    expect(find.text('4 ★ (1)'), findsOneWidget);

    // Ten 1-star reviews arrive
    for (var i = 0; i < 10; i++) {
      _add(product, 1, 'Bad $i');
    }
    await tester.pump();

    expect(find.text('12 Reviews'), findsOneWidget);
    expect(find.text('1.6'), findsOneWidget); // (5 + 4 + 10) / 12 = 1.58
    expect(find.text('1 ★ (10)'), findsOneWidget);
  });

  testWidgets('A single review says "1 Review"', (tester) async {
    const product = 'Single Product';
    _add(product, 2, 'Meh');
    await _open(tester, product);

    expect(find.text('1 Review'), findsOneWidget);
    expect(find.text('2.0'), findsOneWidget);
  });

  testWidgets('Reviews belong to one product and are still there when the screen is opened again', (tester) async {
    _add('Product A', 5, 'Great carrots');
    await _open(tester, 'Product A');
    expect(find.text('Great carrots'), findsOneWidget);
    expect(find.text('1 Review'), findsOneWidget);

    // Another product does not show it
    await _open(tester, 'Product B');
    expect(find.text('Great carrots'), findsNothing);
    expect(find.text('No reviews yet'), findsOneWidget);

    // Back on the first product nothing is lost
    await _open(tester, 'Product A');
    expect(find.text('Great carrots'), findsOneWidget);
    expect(find.text('1 Review'), findsOneWidget);
  });

  testWidgets('The number on the All chip is the number of reviews listed', (tester) async {
    const product = 'Count Product';
    _add(product, 5, 'review one', name: 'A');
    _add(product, 3, 'review two', name: 'B');
    await _open(tester, product);

    expect(find.text('All (2)'), findsOneWidget);
    for (final text in ['review one', 'review two']) {
      expect(find.text(text), findsOneWidget, reason: '$text should be listed');
    }
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNWidgets(2));
  });

  testWidgets('Newest review is shown first', (tester) async {
    const product = 'Order Product';
    _add(product, 5, 'first review', name: 'A');
    // Real (not fake) time passes so the two reviews get different timestamps
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    _add(product, 5, 'second review', name: 'B');
    await _open(tester, product);

    final firstY = tester.getTopLeft(find.text('first review')).dy;
    final secondY = tester.getTopLeft(find.text('second review')).dy;
    expect(secondY, lessThan(firstY));
    expect(find.text('Just now'), findsNWidgets(2));
  });

  testWidgets('Every star rating has a filter chip with a live count', (tester) async {
    const product = 'Chip Product';
    _add(product, 5, 'Excellent', name: 'Olivia');
    await _open(tester, product);

    expect(find.text('All (1)'), findsOneWidget);
    expect(find.text('5 ★ (1)'), findsOneWidget);
    expect(find.text('3 ★ (0)'), findsOneWidget);
    expect(find.text('1 ★ (0)'), findsOneWidget);

    // A 3-star review comes in: the chip counts change and the review can be found
    _add(product, 3, 'Just okay', name: 'Kasun Perera');
    await tester.pump();
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('3 ★ (1)'), findsOneWidget);

    await tester.tap(find.text('3 ★ (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Just okay'), findsOneWidget);
    expect(find.text('Excellent'), findsNothing); // that review is 5 stars

    // A star with no reviews shows a message instead of an empty page
    await tester.tap(find.text('1 ★ (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Just okay'), findsNothing);
    expect(find.text('No 1-star reviews to show yet.'), findsOneWidget);

    // All shows everything again
    await tester.tap(find.text('All (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Just okay'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
  });

  test('Review times are shown as time ago', () {
    final now = DateTime(2026, 10, 14, 12, 0);
    String ago(Duration d) => ReviewService.timeAgo(now.subtract(d), now: now);

    expect(ago(const Duration(seconds: 10)), 'Just now');
    expect(ago(const Duration(minutes: 5)), '5 min ago');
    expect(ago(const Duration(hours: 1)), '1 hour ago');
    expect(ago(const Duration(hours: 5)), '5 hours ago');
    expect(ago(const Duration(days: 1)), 'Yesterday');
    expect(ago(const Duration(days: 3)), '3 days ago');
    expect(ago(const Duration(days: 7)), '1 week ago');
    expect(ago(const Duration(days: 20)), '2 weeks ago');
    expect(ago(const Duration(days: 60)), '15 Aug 2026');
  });
}
