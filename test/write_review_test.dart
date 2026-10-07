import 'package:dashgrocer/views/customer/reviews_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Write a review: rating is required, then review is added to the list', (tester) async {
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

    await tester.tap(find.text('Write a review'));
    await tester.pumpAndSettle();
    expect(find.text('Write Reviews'), findsOneWidget);

    // No rating selected -> rejected
    await tester.tap(find.text('Submit review'));
    await tester.pump();
    expect(find.text('Please select a star rating first.'), findsOneWidget);
    expect(find.text('Write Reviews'), findsOneWidget);

    // Select 4 stars, write a comment, submit
    await tester.tap(find.byIcon(Icons.star_rounded).at(3));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Very fresh vegetables!');
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    expect(find.text('Write Reviews'), findsNothing);
    expect(find.text('Very fresh vegetables!'), findsOneWidget);
    expect(find.text('Just now'), findsOneWidget);
  });
}
