import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/owner_profile.dart';
import '../../models/product.dart';
import '../../models/shop_order.dart';
import '../../models/shop_profile.dart';
import '../../services/shop_store.dart';
import 'widgets/dialogs.dart';

/// Every change the shop owner can make, in one place.
///
/// Each action follows the same steps: ask for confirmation when a mistake
/// would be costly, show a spinner while saving, then show a message saying
/// what happened. Because all screens call these same methods, an order
/// behaves the same from the Dashboard, the Order Queue and Order Details.
class ShopActions {
  ShopActions(this.store);

  final ShopStore store;

  /// How many units the "Add 10" and "Restock +10" buttons add.
  static const int quickAddAmount = 10;

  /// Firestore keeps a write waiting while the phone is offline, so the app
  /// stops waiting after this long and tells the owner it will sync later.
  static const Duration _writeTimeout = Duration(seconds: 8);

  /// Runs one save. Returns true when it was saved (or queued offline).
  Future<bool> _run(
    BuildContext context, {
    required String busyId,
    required Future<void> Function() task,
    required String success,
    required String failure,
  }) async {
    if (store.isBusy(busyId)) return false;
    final messenger = ScaffoldMessenger.of(context);

    store.setBusy(busyId, true);
    try {
      await task().timeout(_writeTimeout);
      showAppMessage(messenger, success);
      return true;
    } on TimeoutException {
      showAppMessage(
        messenger,
        'No connection. The change will sync when you are back online.',
      );
      return true;
    } catch (error) {
      debugPrint('Action "$busyId" failed: $error');
      showAppMessage(messenger, failure, isError: true);
      return false;
    } finally {
      store.setBusy(busyId, false);
    }
  }

  // ----------------------------------------------------------------- orders

  /// Accepts a new order and moves it to Preparing (FR-06).
  Future<void> startPreparing(BuildContext context, ShopOrder order) async {
    await _run(
      context,
      busyId: order.id,
      task: () => store.repository.updateOrderStatus(
        order,
        OrderStatus.preparing,
      ),
      success: 'Order #${order.orderNumber} accepted and moved to Preparing.',
      failure: 'Could not update order #${order.orderNumber}. Try again.',
    );
  }

  /// Marks an order ready, which notifies the customer (FR-06, FR-07).
  Future<void> markReady(BuildContext context, ShopOrder order) async {
    final confirmed = await confirmMarkReady(
      context,
      order,
      unpackedCount:
          order.hasItemList ? order.itemCount - order.packedCount : 0,
    );
    if (!confirmed || !context.mounted) return;

    await _run(
      context,
      busyId: order.id,
      task: () => store.repository.updateOrderStatus(order, OrderStatus.ready),
      success: 'Order #${order.orderNumber} is ready. '
          '${order.customerName} has been notified.',
      failure: 'Could not update order #${order.orderNumber}. Try again.',
    );
  }

  /// Closes an order once the customer has collected it.
  Future<void> completeOrder(BuildContext context, ShopOrder order) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Order collected?',
      message: 'Confirm that ${order.customerName} has collected order '
          '#${order.orderNumber}. It will move to Completed.',
      confirmLabel: 'Mark Completed',
    );
    if (!confirmed || !context.mounted) return;

    await _run(
      context,
      busyId: order.id,
      task: () => store.repository.updateOrderStatus(
        order,
        OrderStatus.completed,
      ),
      success: 'Order #${order.orderNumber} completed.',
      failure: 'Could not update order #${order.orderNumber}. Try again.',
    );
  }

  /// Rejects a new order after asking for the reason. The customer is told.
  Future<void> rejectOrder(BuildContext context, ShopOrder order) async {
    final reason = await pickRejectReason(context, order);
    if (reason == null || !context.mounted) return;

    await _run(
      context,
      busyId: order.id,
      task: () => store.repository.updateOrderStatus(
        order,
        OrderStatus.cancelled,
        cancelReason: reason,
      ),
      success: 'Order #${order.orderNumber} rejected. '
          '${order.customerName} has been notified.',
      failure: 'Could not reject order #${order.orderNumber}. Try again.',
    );
  }

  /// Ticks or unticks one item on the packing checklist. No message is
  /// shown because the tick itself is the feedback.
  Future<void> setItemPacked(ShopOrder order, int index, bool packed) async {
    final next = order.packedIndexes.toSet();
    if (packed) {
      next.add(index);
    } else {
      next.remove(index);
    }
    final sorted = next.toList()..sort();
    try {
      await store.repository
          .setPackedItems(order, sorted)
          .timeout(_writeTimeout);
    } catch (error) {
      debugPrint('setPackedItems failed: $error');
    }
  }

  /// Opens the phone dialler. If that is not possible the number is copied.
  Future<void> callCustomer(BuildContext context, String phone) async {
    if (phone.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    var opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: digits));
    } catch (error) {
      debugPrint('Could not open the dialler: $error');
    }
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: phone));
      showAppMessage(messenger, 'Number copied: $phone');
    }
  }

  // --------------------------------------------------------------- products

  /// Adds units to a product's stock (FR-05).
  Future<void> addStock(
    BuildContext context,
    Product product,
    int quantity,
  ) async {
    await _run(
      context,
      busyId: product.id,
      task: () => store.repository.addStock(product, quantity),
      success: 'Added $quantity to ${product.name}.',
      failure: 'Could not update ${product.name}. Try again.',
    );
  }

  /// Asks how many units arrived, then adds them.
  Future<void> restock(BuildContext context, Product product) async {
    final quantity = await showQuantityDialog(
      context,
      title: 'Restock product',
      message: product.name,
      fieldLabel: 'Units to add',
      initialValue: quickAddAmount,
      confirmLabel: 'Add stock',
    );
    if (quantity == null || !context.mounted) return;
    await addStock(context, product, quantity);
  }

  /// The In Stock switch on the inventory list (FR-05).
  ///
  /// Switching off sets the stock to 0. Switching on asks how many units
  /// are now on the shelf.
  Future<void> setInStock(
    BuildContext context,
    Product product,
    bool inStock,
  ) async {
    if (inStock) {
      await restock(context, product);
      return;
    }
    await _run(
      context,
      busyId: product.id,
      task: () => store.repository.setStock(product, 0),
      success: '${product.name} marked out of stock.',
      failure: 'Could not update ${product.name}. Try again.',
    );
  }

  /// Creates or updates a product. Returns true when saved.
  Future<bool> saveProduct(BuildContext context, Product product) {
    return _run(
      context,
      busyId: product.id.isEmpty ? 'new_product' : product.id,
      task: () => store.repository.saveProduct(product),
      success: product.id.isEmpty
          ? '${product.name} added to your products.'
          : '${product.name} saved.',
      failure: 'Could not save ${product.name}. Try again.',
    );
  }

  /// Deletes a product after confirmation. Returns true when deleted.
  Future<bool> deleteProduct(BuildContext context, Product product) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete product?',
      message: '${product.name} will be removed from your shop and from the '
          'customer catalog. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return false;

    return _run(
      context,
      busyId: product.id,
      task: () => store.repository.deleteProduct(product),
      success: '${product.name} deleted.',
      failure: 'Could not delete ${product.name}. Try again.',
    );
  }

  // ------------------------------------------------------------------- shop

  /// Saves shop details or settings. Returns true when saved.
  Future<bool> saveShop(
    BuildContext context,
    ShopProfile shop, {
    required String success,
  }) {
    return _run(
      context,
      busyId: 'shop',
      task: () => store.repository.saveShop(shop),
      success: success,
      failure: 'Could not save your changes. Try again.',
    );
  }

  /// Saves the owner's personal details. Returns true when saved.
  Future<bool> saveOwner(BuildContext context, OwnerProfile owner) {
    return _run(
      context,
      busyId: 'owner',
      task: () => store.repository.saveOwner(owner),
      success: 'Your profile was saved.',
      failure: 'Could not save your profile. Try again.',
    );
  }

  /// Marks every alert in the notifications panel as read.
  Future<void> markAlertsRead() async {
    try {
      await store.repository
          .saveShop(store.shop.copyWith(notificationsReadAt: DateTime.now()))
          .timeout(_writeTimeout);
    } catch (error) {
      debugPrint('markAlertsRead failed: $error');
    }
  }
}
