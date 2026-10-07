import 'package:dashgrocer/views/customer/reviews_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Write a review: rating and comment are required, then review is added', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReviewsScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Write a review'));
    await tester.tap(find.text('Write a review'));
    await tester.pumpAndSettle();
    expect(find.text('Write Reviews'), findsOneWidget);

    // No rating selected -> rejected
    await tester.tap(find.text('Submit review'));
    await tester.pump();
    expect(find.text('Please select a star rating first.'), findsOneWidget);
    expect(find.text('Write Reviews'), findsOneWidget);

    // Rating but no comment -> rejected
    await tester.tap(find.byIcon(Icons.star_rounded).at(3));
    await tester.pump();
    expect(find.text('4.0 - Very Good'), findsOneWidget);
    await tester.tap(find.text('Submit review'));
    await tester.pump();
    expect(find.text('Please write a brief review about your experience.'), findsOneWidget);

    // Rating + comment -> submitted and listed
    await tester.enterText(find.byType(TextField), 'Very fresh vegetables!');
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    expect(find.text('Write Reviews'), findsNothing);
    expect(find.text('Very fresh vegetables!'), findsOneWidget);
    expect(find.text('Just now'), findsOneWidget);
  });
}
