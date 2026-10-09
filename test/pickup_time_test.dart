import 'package:dashgrocer/views/customer/pickup_time_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  liveClockTests();
  Future<void> openAt(WidgetTester tester, DateTime now) async {
    PickupTimeScreen.clock = () => now;
    addTearDown(() => PickupTimeScreen.clock = DateTime.now);
    await tester.pumpWidget(const MaterialApp(home: PickupTimeScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('Pickup dates follow the real calendar (including month and year end)', (tester) async {
    await openAt(tester, DateTime(2026, 12, 31, 8, 0));
    expect(find.text('Today , Thu 31 Dec'), findsOneWidget);
    expect(find.text('Tomorrow , Fri 1 Jan'), findsOneWidget);
  });

  testWidgets('Morning: all of today\'s slots are offered', (tester) async {
    await openAt(tester, DateTime(2026, 10, 12, 8, 0));
    // 9.00 AM ... 7.00 PM appear for today and for tomorrow
    expect(find.text('9.00 AM'), findsNWidgets(2));
    expect(find.text('7.00 PM'), findsNWidgets(2));
  });

  testWidgets('Afternoon: slots that already started are hidden for today only', (tester) async {
    // 1:50 PM -> 2.00 PM is less than 30 minutes away, so today starts at 4.00 PM
    await openAt(tester, DateTime(2026, 10, 12, 13, 50));
    expect(find.text('9.00 AM'), findsOneWidget); // tomorrow only
    expect(find.text('2.00 PM'), findsOneWidget); // tomorrow only
    expect(find.text('4.00 PM'), findsNWidgets(2));
    expect(find.text('7.00 PM'), findsNWidgets(2));
  });

  testWidgets('Late evening: no slots today, tomorrow is selected by default', (tester) async {
    await openAt(tester, DateTime(2026, 10, 12, 20, 30));
    expect(find.textContaining('No more pickup slots today'), findsOneWidget);
    expect(find.text('9.00 AM'), findsOneWidget);
    expect(find.text('Continue to Payment'), findsOneWidget);
  });
}

void liveClockTests() {
  testWidgets('Clock keeps running: a slot disappears when its time arrives and selection moves on', (tester) async {
    var now = DateTime(2026, 10, 12, 15, 0); // 3:00 PM -> today starts at 4.00 PM
    PickupTimeScreen.clock = () => now;
    addTearDown(() => PickupTimeScreen.clock = DateTime.now);

    await tester.pumpWidget(const MaterialApp(home: PickupTimeScreen()));
    await tester.pumpAndSettle();

    // 4.00 PM is free today (today + tomorrow lists) and is the default pick
    expect(find.text('4.00 PM'), findsNWidgets(2));
    expect(find.text('Today , Mon 12 Oct'), findsOneWidget);

    // Time moves on to 3:45 PM while the screen stays open: 4.00 PM is now < 30 min away
    now = DateTime(2026, 10, 12, 15, 45);
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();

    expect(find.text('4.00 PM'), findsNWidgets(1)); // only tomorrow's list
    expect(find.textContaining('That pickup time has passed'), findsOneWidget);
    expect(find.textContaining('5.00 PM'), findsWidgets);
  });

  testWidgets('Dates roll over to the next day at midnight while the screen is open', (tester) async {
    var now = DateTime(2026, 10, 12, 23, 50);
    PickupTimeScreen.clock = () => now;
    addTearDown(() => PickupTimeScreen.clock = DateTime.now);

    await tester.pumpWidget(const MaterialApp(home: PickupTimeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Today , Mon 12 Oct'), findsOneWidget);
    expect(find.text('Tomorrow , Tue 13 Oct'), findsOneWidget);

    now = DateTime(2026, 10, 13, 0, 5);
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();

    expect(find.text('Today , Tue 13 Oct'), findsOneWidget);
    expect(find.text('Tomorrow , Wed 14 Oct'), findsOneWidget);
  });
}
