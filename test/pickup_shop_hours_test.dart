import 'dart:async';

import 'package:dashgrocer/models/shop_profile.dart';
import 'package:dashgrocer/views/customer/pickup_time_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Opens the pickup screen for a shop whose settings come from [shops].
  Future<void> open(
    WidgetTester tester, {
    required DateTime now,
    required Stream<ShopProfile?> shops,
  }) async {
    PickupTimeScreen.clock = () => now;
    PickupTimeScreen.shopLoader = (_) => shops;
    addTearDown(() => PickupTimeScreen.clock = DateTime.now);
    addTearDown(
      () => PickupTimeScreen.shopLoader = (_) => const Stream<ShopProfile?>.empty(),
    );
    await tester.pumpWidget(
      const MaterialApp(home: PickupTimeScreen(shopId: 'owner_01')),
    );
    await tester.pumpAndSettle();
  }

  // Monday 12 Oct 2026, 8:00 AM.
  final monday = DateTime(2026, 10, 12, 8, 0);

  testWidgets('Slots follow the hours and slot length the shop owner set', (tester) async {
    await open(
      tester,
      now: monday,
      shops: Stream.value(
        const ShopProfile(
          id: 'owner_01',
          name: 'Corner Fresh',
          address: '5 Lake Road',
          weekdayOpen: 600, // 10:00 AM
          weekdayClose: 720, // 12:00 PM
          slotMinutes: 60,
        ),
      ),
    );

    // 10:00 and 11:00 only, for today and for tomorrow.
    expect(find.text('10:00 AM'), findsNWidgets(2));
    expect(find.text('11:00 AM'), findsNWidgets(2));
    expect(find.text('12:00 PM'), findsNothing);
    // The built-in default slots are gone.
    expect(find.text('9.00 AM'), findsNothing);
    expect(find.text('4.00 PM'), findsNothing);

    expect(find.text('Corner Fresh'), findsOneWidget);
    expect(find.text('5 Lake Road • Open 10:00 AM – 12:00 PM'), findsOneWidget);
  });

  testWidgets('A shop closed on Sunday offers no Sunday slots', (tester) async {
    // Saturday 17 Oct 2026, so tomorrow is Sunday.
    await open(
      tester,
      now: DateTime(2026, 10, 17, 8, 0),
      shops: Stream.value(
        const ShopProfile(
          id: 'owner_01',
          weekdayOpen: 600,
          weekdayClose: 720,
          slotMinutes: 60,
          sundayClosed: true,
        ),
      ),
    );

    expect(find.text('10:00 AM'), findsOneWidget); // today only
    expect(find.text('The shop is closed tomorrow.'), findsOneWidget);
  });

  testWidgets('Slots update while the screen is open when the owner changes them', (tester) async {
    final shops = StreamController<ShopProfile?>();
    addTearDown(shops.close);
    await open(tester, now: monday, shops: shops.stream);

    // Nothing loaded yet: the default slots are shown.
    expect(find.text('9.00 AM'), findsNWidgets(2));

    shops.add(
      const ShopProfile(
        id: 'owner_01',
        weekdayOpen: 840, // 2:00 PM
        weekdayClose: 900, // 3:00 PM
        slotMinutes: 30,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('9.00 AM'), findsNothing);
    expect(find.text('2:00 PM'), findsNWidgets(2));
    expect(find.text('2:30 PM'), findsNWidgets(2));
  });

  testWidgets('A shop with no saved settings keeps the default slots', (tester) async {
    await open(tester, now: monday, shops: Stream.value(null));

    expect(find.text('9.00 AM'), findsNWidgets(2));
    expect(find.text('7.00 PM'), findsNWidgets(2));
  });
}
