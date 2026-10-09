import 'package:dashgrocer/services/review_service.dart';
import 'package:dashgrocer/views/customer/reviews_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(WidgetTester tester, String product) async {
  await tester.pumpWidget(MaterialApp(home: ReviewsScreen(productName: product)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Rating summary counts only the reviews that exist and updates live', (tester) async {
    const product = 'Live Product';
    await _open(tester, product);

    // Only the 3 starter reviews exist: ratings 5, 4 and 5 -> average 4.67
    expect(find.text('4.7'), findsOneWidget);
    expect(find.text('3 Reviews'), findsOneWidget);
    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('5 ★ (2)'), findsOneWidget);
    expect(find.text('4 ★ (1)'), findsOneWidget);
    expect(find.text('3 ★ (0)'), findsOneWidget);

    // Ten 1-star reviews arrive while the screen is open (for example from another phone)
    for (var i = 0; i < 10; i++) {
      ReviewService().addReview(productName: product, name: 'Tester', rating: 1, comment: 'Bad $i');
    }
    await tester.pump();

    expect(find.text('13 Reviews'), findsOneWidget);
    expect(find.text('1.8'), findsOneWidget); // (5 + 4 + 5 + 10) / 13
    expect(find.text('All (13)'), findsOneWidget);
    expect(find.text('1 ★ (10)'), findsOneWidget);
  });

  testWidgets('Reviews belong to one product and are still there when the screen is opened again', (tester) async {
    ReviewService().addReview(productName: 'Product A', name: 'Nimali', rating: 5, comment: 'Great carrots');
    await _open(tester, 'Product A');
    expect(find.text('Great carrots'), findsOneWidget);
    expect(find.text('4 Reviews'), findsOneWidget);

    // Leave and open the same product again: nothing is lost and the counts match
    await _open(tester, 'Product B');
    expect(find.text('Great carrots'), findsNothing);
    expect(find.text('3 Reviews'), findsOneWidget);

    await _open(tester, 'Product A');
    expect(find.text('Great carrots'), findsOneWidget);
    expect(find.text('4 Reviews'), findsOneWidget);
  });

  testWidgets('The number on the All chip is the number of reviews listed', (tester) async {
    const product = 'Count Product';
    ReviewService().addReview(productName: product, name: 'A', rating: 5, comment: 'review one');
    ReviewService().addReview(productName: product, name: 'B', rating: 3, comment: 'review two');
    await _open(tester, product);

    expect(find.text('All (5)'), findsOneWidget);
    // 3 starter reviews + 2 written ones are all in the list
    for (final text in ['review one', 'review two', 'Olivia', 'Da Silva']) {
      expect(find.text(text), findsOneWidget, reason: '$text should be listed');
    }
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNWidgets(5));
  });

  testWidgets('Newest review is shown first', (tester) async {
    const product = 'Order Product';
    ReviewService().addReview(productName: product, name: 'A', rating: 5, comment: 'first review');
    // Real (not fake) time passes so the two reviews get different timestamps
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    ReviewService().addReview(productName: product, name: 'B', rating: 5, comment: 'second review');
    await _open(tester, product);

    final firstY = tester.getTopLeft(find.text('first review')).dy;
    final secondY = tester.getTopLeft(find.text('second review')).dy;
    expect(secondY, lessThan(firstY));
    expect(find.text('Just now'), findsNWidgets(2));
  });

  testWidgets('Every star rating has a filter chip with a live count', (tester) async {
    const product = 'Chip Product';
    await _open(tester, product);

    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('5 ★ (2)'), findsOneWidget);
    expect(find.text('3 ★ (0)'), findsOneWidget);
    expect(find.text('1 ★ (0)'), findsOneWidget);

    // A 3-star review comes in: the chip counts change and the review can be found
    ReviewService().addReview(productName: product, name: 'Kasun Perera', rating: 3, comment: 'Just okay');
    await tester.pump();
    expect(find.text('All (4)'), findsOneWidget);
    expect(find.text('3 ★ (1)'), findsOneWidget);

    await tester.tap(find.text('3 ★ (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Just okay'), findsOneWidget);
    expect(find.text('Olivia'), findsNothing); // her review is 5 stars

    // A star with no reviews shows a message instead of an empty page
    await tester.tap(find.text('1 ★ (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Just okay'), findsNothing);
    expect(find.text('No 1-star reviews to show yet.'), findsOneWidget);

    // All shows everything again
    await tester.tap(find.text('All (4)'));
    await tester.pumpAndSettle();
    expect(find.text('Just okay'), findsOneWidget);
    expect(find.text('Olivia'), findsOneWidget);
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
