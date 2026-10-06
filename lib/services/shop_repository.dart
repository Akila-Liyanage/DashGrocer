import '../models/owner_profile.dart';
import '../models/product.dart';
import '../models/shop_order.dart';
import '../models/shop_profile.dart';

/// Everything the shop owner screens need from the backend.
///
/// The screens never talk to Firestore directly. They use this class, so they
/// work the same with real data (FirestoreShopRepository) and with in-memory
/// demo data (MockShopRepository).
abstract class ShopRepository {
  /// True when the data is in-memory demo data, not Firestore.
  bool get isDemo;

  /// Category names offered when filtering and editing products.
  List<String> get productCategories;

  /// Whether a product can be hidden from the customer catalog (the
  /// "Online Availability" switch). False when the catalog has no such field.
  bool get supportsCatalogVisibility;

  /// Whether the owner's email can be changed on the My Profile screen.
  /// False when the email is the login email, which is managed by sign-in.
  bool get canEditEmail;

  /// Live list of every order for this shop (FR-08).
  Stream<List<ShopOrder>> watchOrders(String shopId);

  /// Live list of every product for this shop.
  Stream<List<Product>> watchProducts(String shopId);

  /// Live shop details and settings.
  Stream<ShopProfile> watchShop(String shopId);

  /// Live personal details of the logged-in shop owner.
  Stream<OwnerProfile> watchOwner(String userId);

  /// FR-06: move an order to another status. Moving it to ready or cancelled
  /// also writes a notification for the customer (FR-07).
  Future<void> updateOrderStatus(
    ShopOrder order,
    OrderStatus status, {
    String? cancelReason,
  });

  /// Saves which checklist items are packed.
  Future<void> setPackedItems(ShopOrder order, List<int> packedIndexes);

  /// FR-05: add [quantity] units to a product's stock.
  Future<void> addStock(Product product, int quantity);

  /// FR-05: set a product's stock to an exact number (0 = out of stock).
  Future<void> setStock(Product product, int stock);

  /// Creates the product when its id is empty, otherwise updates it.
  Future<void> saveProduct(Product product);

  Future<void> deleteProduct(Product product);

  Future<void> saveShop(ShopProfile shop);

  /// Saves the owner's name, email, phone and photo.
  Future<void> saveOwner(OwnerProfile owner);

  /// Creates the shop's and the owner's documents from the details given at
  /// registration, the first time the owner opens the app. Documents that
  /// already exist are left untouched.
  Future<void> ensureProfiles({
    required ShopProfile shop,
    required OwnerProfile owner,
  });

  /// Writes sample orders and products for this shop so an empty database
  /// has something to show. Only offered in debug builds.
  Future<void> seedDemoData(String shopId);
}
