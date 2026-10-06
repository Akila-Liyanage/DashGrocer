# Shop owner side: what this branch adds

This branch adds the shop owner screens built from the shop owner Figma
(dashboard, order queue, order details, product inventory, product details,
shop profile, My Profile, notifications, sales summary) and opens them for
users whose role is shop owner.

## How it connects to the rest of the app

- **Orders and products are shared, not copied.** The shop owner screens read
  and write the same `GroceryService` the customer screens use, through
  `lib/services/grocery_shop_repository.dart`. A customer order appears on the
  shop owner dashboard, and a status change made by the owner
  (`Pending`, `Preparing`, `Ready for Pickup`, `Completed`, `Cancelled`) is
  what the customer's profile tab shows.
- **Login and log out.** `main.dart` opens `ShopOwnerHome(user: user)` for the
  shop owner role. Log Out calls `AuthService().logout()`.
- **Shop settings and My Profile** (opening hours, pickup slots, the owner's
  photo, name and phone) are saved in Firestore: `shops/{userId}` and
  `users/{userId}`. Saving My Profile only merges `fullName`, `email`,
  `phoneNumber` and `photoUrl`; it never touches `role` or the other fields.
- **Theme.** The shop owner screens use their own theme (`ShopTheme` in
  `lib/core/theme/shop_owner_theme.dart`); the rest of the app keeps
  `AppTheme`.

## Existing files changed (4)

| File | Change |
|---|---|
| `lib/main.dart` | Shop owners open `ShopOwnerHome` (one import, one line) |
| `pubspec.yaml` | Added `image_picker` and `url_launcher` |
| `lib/views/common/app_image_view.dart` | Also shows `data:image/...` photos, so product photos taken by the shop owner appear for customers |
| `test/widget_test.dart` | The shop owner login test checks the new dashboard |

Everything else is new files: `lib/views/shop_owner/` (sub-folders, the shell,
`shop_owner_home.dart`, `shop_actions.dart`), `lib/models/` (5 files),
`lib/services/` (6 files), `lib/core/formatters.dart` and
`lib/core/theme/shop_owner_theme.dart`.

## Files that are now unused

The earlier seller dashboard is no longer opened by the app. These can be
removed, together with `test/seller_dashboard_test.dart` and "Flow 2" in
`test/complete_app_flow_test.dart`, which test it:

- `lib/views/shop_owner/shop_owner_dashboard.dart`
- `lib/views/shop_owner/add_product_screen.dart`
- `lib/views/shop_owner/seller_notifications_sheet.dart`

## Known limits (these come from how orders are stored today)

1. **Orders live in memory.** `GroceryService` keeps orders in the phone's
   memory, so the customer and the shop owner must use the same phone, and
   orders are lost when the app restarts. Saving orders to Firestore would fix
   both.
2. **Every customer order gets the same number.** `pickup_time_screen.dart`
   passes `orderId: '#FP-2028-0142'` to `placeOrder`. `updateOrderStatus`
   changes the first order with that number, so only the newest order can be
   updated. The shop owner screens refuse to update an older duplicate rather
   than change the wrong order. Removing that argument lets `placeOrder`
   generate unique numbers.
3. **Orders have no item list.** An order only carries a text summary such as
   "3 items (Carrots, Milk, Bread)". Order Details shows that summary; the
   packing checklist and "Top Products" in the sales summary need real items
   (name, quantity, price) on the order.
4. **Stock is not shown to customers.** The shop owner can mark a product out
   of stock (`stockQuantity` becomes 0), but the customer screens do not read
   `stockQuantity` yet, so customers can still order it.
5. **Product code, barcode and low stock level** have no field in
   `GroceryItem`, so they are kept only while the app is open.

## How to test

1. `flutter pub get`, then `flutter run`.
2. Log in as a customer, add products to the cart, choose a pickup time and
   place the order. Log out.
3. Log in as the seller (`seller@dashgrocer.com`, the same demo password as
   the customer). The new order is on the
   Dashboard and in the Order Queue, and the bell shows an alert.
4. Tap Start Preparing, then Mark Ready. Log out, log in as the customer and
   open the profile tab: the order shows the new status.
