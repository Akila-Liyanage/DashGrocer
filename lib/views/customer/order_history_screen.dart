import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/grocery_item_model.dart';
import '../../models/seller_order_model.dart';
import '../../services/auth_service.dart';
import '../../services/grocery_service.dart';
import '../common/app_image_view.dart';
import 'seller_chat_screen.dart';
import 'track_order_screen.dart';
import 'widgets/cancel_order_dialog.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _StatusStyle {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusStyle(this.label, this.background, this.foreground);
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _selectedFilterIndex = 0; // 0 = All, 1 = Active, 2 = Completed, 3 = Cancel

  final List<String> _filters = ['All', 'Active', 'Completed', 'Cancel'];

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Options of the filter button (the icon at the end of the search bar)
  static const List<String> _sortOptions = ['Newest first', 'Oldest first', 'Highest total', 'Lowest total'];
  static const List<String> _paymentOptions = ['Any', 'Pay at Store', 'Paid online'];
  static const List<String> _periodOptions = ['Any time', 'Today', 'Last 7 days', 'Last 30 days'];

  String _sort = _sortOptions.first;
  String _payment = _paymentOptions.first;
  String _period = _periodOptions.first;

  /// How many filter options differ from the defaults (shown on the icon).
  int get _activeFilterCount =>
      (_sort != _sortOptions.first ? 1 : 0) +
      (_payment != _paymentOptions.first ? 1 : 0) +
      (_period != _periodOptions.first ? 1 : 0);

  bool _passesFilters(StoreOrder o) {
    final online = o.paymentMethod.toLowerCase().contains('online');
    if (_payment == 'Pay at Store' && online) return false;
    if (_payment == 'Paid online' && !online) return false;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case 'Today':
        if (o.createdAt.isBefore(startOfToday)) return false;
      case 'Last 7 days':
        if (o.createdAt.isBefore(startOfToday.subtract(const Duration(days: 6)))) return false;
      case 'Last 30 days':
        if (o.createdAt.isBefore(startOfToday.subtract(const Duration(days: 29)))) return false;
    }
    return true;
  }

  void _resetFilters() {
    setState(() {
      _sort = _sortOptions.first;
      _payment = _paymentOptions.first;
      _period = _periodOptions.first;
    });
  }

  Future<void> _openFilters() async {
    var sort = _sort;
    var payment = _payment;
    var period = _period;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Widget group(String title, List<String> options, String selected, ValueChanged<String> onSelect) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in options)
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setSheetState(() => onSelect(option)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected == option ? AppColors.brandGreenSoft : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected == option ? AppColors.brandGreen : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            option,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: selected == option ? FontWeight.w700 : FontWeight.w500,
                              color: selected == option
                                  ? AppColors.brandGreenDark
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter orders',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setSheetState(() {
                          sort = _sortOptions.first;
                          payment = _paymentOptions.first;
                          period = _periodOptions.first;
                        }),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandGreenDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  group('Sort by', _sortOptions, sort, (v) => sort = v),
                  const SizedBox(height: 16),
                  group('Payment', _paymentOptions, payment, (v) => payment = v),
                  const SizedBox(height: 16),
                  group('Placed', _periodOptions, period, (v) => period = v),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: Text(
                        'Apply filters',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (applied == true && mounted) {
      setState(() {
        _sort = sort;
        _payment = payment;
        _period = period;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---- order helpers -------------------------------------------------------

  static bool _isActive(StoreOrder o) => o.status != 'Completed' && o.status != 'Cancelled';

  static _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'Preparing':
        return const _StatusStyle('PREPARING', Color(0xFFE0F2FE), Color(0xFF0284C7));
      case 'Ready for Pickup':
        return const _StatusStyle('READY', Color(0xFFE8F6EB), AppColors.brandGreenDark);
      case 'Completed':
        return const _StatusStyle('COMPLETED', Color(0xFFF1F5F9), Color(0xFF475569));
      case 'Cancelled':
        return const _StatusStyle('CANCELLED', Color(0xFFFEE2E2), Color(0xFFB91C1C));
      default:
        return const _StatusStyle('PENDING', Color(0xFFFEF3C7), Color(0xFFB45309));
    }
  }

  static String _timeLabel(DateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minutes = t.minute.toString().padLeft(2, '0');
    return '$hour12:$minutes ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "Today , 2:30 PM", "Yesterday , 4:30 PM" or "12 Oct , 4:30 PM".
  static String _dateLabel(DateTime placed) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(placed.year, placed.month, placed.day);
    final diff = today.difference(day).inDays;
    final dayText = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Yesterday'
            : '${placed.day} ${months[placed.month - 1]}';
    return '$dayText , ${_timeLabel(placed)}';
  }

  /// "4 Items , Paid" / "2 Items , Pay at Store".
  static String _itemCountLabel(StoreOrder o) {
    final match = RegExp(r'^\s*(\d+)\s+item').firstMatch(o.itemsSummary);
    final count = match == null ? null : int.tryParse(match.group(1)!);
    final pay = o.paymentMethod.toLowerCase().contains('online') ? 'Paid' : 'Pay at Store';
    if (count == null) return pay;
    return '$count ${count == 1 ? 'Item' : 'Items'} , $pay';
  }

  static int? _itemCount(StoreOrder o) {
    final match = RegExp(r'^\s*(\d+)\s+item').firstMatch(o.itemsSummary);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// Catalog products named in "3 items (Carrots, Milk, Bread)", for the pictures.
  static List<GroceryItem> _productsOf(StoreOrder o) {
    final match = RegExp(r'\(([^)]*)\)').firstMatch(o.itemsSummary);
    if (match == null) return const [];
    final names = match
        .group(1)!
        .split(',')
        .map((s) => s.replaceAll('...', '').trim().toLowerCase())
        .where((s) => s.isNotEmpty);
    final catalog = GroceryService().allItems;
    final found = <GroceryItem>[];
    for (final name in names) {
      for (final item in catalog) {
        final itemName = item.name.toLowerCase();
        if (itemName == name || itemName.contains(name) || name.contains(itemName)) {
          if (!found.any((f) => f.id == item.id)) found.add(item);
          break;
        }
      }
    }
    return found;
  }

  bool _matches(StoreOrder o) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = '${o.id} ${o.status} ${_statusStyle(o.status).label} ${_dateLabel(o.createdAt)} '
            '${_itemCountLabel(o)} ${o.formattedTotal} ${o.itemsSummary} ${o.shopName}'
        .toLowerCase();
    return q.split(RegExp(r'\s+')).every(haystack.contains);
  }

  List<StoreOrder> _myOrders() {
    final user = AuthService().currentUser;
    final name = (user?.fullName.isNotEmpty == true) ? user!.fullName : 'Kasun Perera';
    final phone = (user?.phoneNumber.isNotEmpty == true) ? user!.phoneNumber : '+94 77 123 4567';
    final orders = GroceryService().ordersForCustomer(name: name, phone: phone).where(_passesFilters).toList();
    switch (_sort) {
      case 'Oldest first':
        orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'Highest total':
        orders.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      case 'Lowest total':
        orders.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
      default:
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return orders;
  }

  // ---- screen --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GroceryService(),
      builder: (context, _) => _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final myOrders = _myOrders();
    final searched = myOrders.where(_matches).toList();
    final showActive = _selectedFilterIndex == 0 || _selectedFilterIndex == 1;
    final activeOrders = showActive ? searched.where(_isActive).toList() : <StoreOrder>[];
    // Collected orders ("Past Orders") and cancelled orders have their own sections.
    final showPast = _selectedFilterIndex == 0 || _selectedFilterIndex == 2;
    final showCancelled = _selectedFilterIndex == 0 || _selectedFilterIndex == 3;
    final pastOrders =
        showPast ? searched.where((o) => o.status == 'Completed').toList() : <StoreOrder>[];
    final cancelledOrders =
        showCancelled ? searched.where((o) => o.status == 'Cancelled').toList() : <StoreOrder>[];
    final hasResults =
        activeOrders.isNotEmpty || pastOrders.isNotEmpty || cancelledOrders.isNotEmpty;
    final readyOrder = myOrders.where((o) => o.status == 'Ready for Pickup').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        centerTitle: true,
        title: Text(
          'Order History',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ready for Pickup banner (only when an order is ready)
            if (readyOrder.isNotEmpty) ...[
              // Tapping the banner opens that order's tracking screen
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackOrderScreen(orderId: readyOrder.first.id),
                    ),
                  );
                },
                child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.errorSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order ${readyOrder.first.id}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ready for pickup • ${readyOrder.first.pickupSlot}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF868889),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF94A3B8)),
                  ],
                ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Search Bar
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search keywords...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  // Filter button: opens the sort / payment / date options
                  Tooltip(
                    message: 'Filter orders',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openFilters,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Badge(
                          isLabelVisible: _activeFilterCount > 0,
                          label: Text('$_activeFilterCount'),
                          backgroundColor: AppColors.brandGreen,
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: _activeFilterCount > 0
                                ? AppColors.brandGreenDark
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Filter Pills: [All] [Active] [Completed] [Cancel]
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilterIndex = index),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brandGreen : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.brandGreen : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          _filters[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 22),

            // No results for the current search / filter
            if (!hasResults)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        _query.trim().isEmpty ? 'No orders here yet' : 'No orders found',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _query.trim().isEmpty
                            ? 'Orders in this tab will appear here.'
                            : 'Nothing matches "${_query.trim()}". Try another keyword.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (_activeFilterCount > 0)
                        TextButton(
                          onPressed: _resetFilters,
                          child: Text(
                            'Reset filters',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandGreenDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Active Section
            if (activeOrders.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreenSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${activeOrders.length} ${activeOrders.length == 1 ? 'order' : 'orders'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final order in activeOrders) _buildOrderCard(order),
              const SizedBox(height: 22),
            ],

            // Cancelled Section (orders the customer or the shop cancelled)
            if (cancelledOrders.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cancelled',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cancelledOrders.length} ${cancelledOrders.length == 1 ? 'order' : 'orders'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final order in cancelledOrders) _buildOrderCard(order),
              const SizedBox(height: 22),
            ],

            // Past Orders Section
            if (pastOrders.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Past Orders',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Most recent',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF868889),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final order in pastOrders) _buildOrderCard(order),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(StoreOrder order) {
    final style = _statusStyle(order.status);
    final products = _productsOf(order);
    final shownProducts = products.take(3).toList();
    final count = _itemCount(order);
    final extraCount = (count ?? 0) - shownProducts.length;
    final orderId = order.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderId,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  style.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: style.foreground,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Date & Time
          Text(
            _dateLabel(order.createdAt),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF868889),
            ),
          ),

          // Who cancelled it, why, and what happens to the payment
          if (order.status == 'Cancelled') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFDC2626)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.cancelledByCustomer
                              ? 'You cancelled this order'
                              : 'The shop cancelled this order',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                        if ((order.cancelReason ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Reason: ${order.cancelReason}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF7F1D1D),
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          order.paymentMethod.toLowerCase().contains('online')
                              ? 'Your card payment will be refunded.'
                              : 'Nothing was charged.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF7F1D1D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Product pictures row
          Row(
            children: [
              if (shownProducts.isEmpty)
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 20, color: AppColors.brandGreen),
                ),
              ...shownProducts.map(
                (item) => Tooltip(
                  message: item.name,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: item.circleColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: AppImageView(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.contain,
                      width: 36,
                      height: 36,
                    ),
                  ),
                ),
              ),
              if (shownProducts.isNotEmpty && extraCount > 0)
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      '+$extraCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _itemCountLabel(order),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF868889),
                    ),
                  ),
                  Text(
                    order.formattedTotal,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: order.status == 'Cancelled'
                          ? const Color(0xFF94A3B8)
                          : AppColors.brandGreenDark,
                      decoration: order.status == 'Cancelled' ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),

          // Action Buttons: Track Order & Contact
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandGreenDark,
                    side: const BorderSide(color: AppColors.brandGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrackOrderScreen(orderId: orderId),
                      ),
                    );
                  },
                  child: Text(
                    'Track Order',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerChatScreen(
                          shopName: order.shopName,
                          sellerName: 'Sunil Weerasinghe',
                          sellerPhone: '+94 71 987 6543',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Contact',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // The customer can cancel until the shop has finished packing
          if (GroceryService().canCustomerCancel(order)) ...[
            const SizedBox(height: 10),
            CancelOrderButton(
              orderId: orderId,
              compact: true,
              // "View" in the message jumps to the Cancel tab, where the order now is
              onViewCancelled: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                  _selectedFilterIndex = 3;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
