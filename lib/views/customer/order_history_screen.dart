import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'track_order_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _HistoryOrder {
  final String orderId;
  final String status;
  final Color statusBgColor;
  final Color statusTextColor;
  final String dateTime;
  final String itemCountLabel;
  final String price;
  final List<IconData> foodIcons;
  final bool isActive;

  const _HistoryOrder({
    required this.orderId,
    required this.status,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.dateTime,
    required this.itemCountLabel,
    required this.price,
    required this.foodIcons,
    required this.isActive,
  });

  /// True when the typed keywords match the order id, status, date, items or price.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = '$orderId $status $dateTime $itemCountLabel $price'.toLowerCase();
    return q.split(RegExp(r'\s+')).every(haystack.contains);
  }
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _selectedFilterIndex = 0; // 0 = All, 1 = Active, 2 = Completed, 3 = Cancel

  final List<String> _filters = ['All', 'Active', 'Completed', 'Cancel'];

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<_HistoryOrder> _orders = [
    _HistoryOrder(
      orderId: '#FP-2028-0142',
      status: 'PREPARING',
      statusBgColor: Color(0xFFE0F2FE),
      statusTextColor: Color(0xFF0284C7),
      dateTime: 'Today , 2:30 PM',
      itemCountLabel: '4 Items , Paid',
      price: 'Rs. 1000',
      foodIcons: [Icons.eco_rounded, Icons.apple_rounded, Icons.local_drink_rounded],
      isActive: true,
    ),
    _HistoryOrder(
      orderId: '#FP-2025-8341',
      status: 'COMPLETED',
      statusBgColor: Color(0xFFF1F5F9),
      statusTextColor: Color(0xFF475569),
      dateTime: 'Yesterday , 4:30 PM',
      itemCountLabel: '2 Items , Card',
      price: 'Rs. 500',
      foodIcons: [Icons.shopping_bag_outlined, Icons.rice_bowl_outlined],
      isActive: false,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searched = _orders.where((o) => o.matches(_query)).toList();
    final showActive = _selectedFilterIndex == 0 || _selectedFilterIndex == 1;
    final showPast = _selectedFilterIndex == 0 || _selectedFilterIndex == 2;
    final activeOrders = showActive ? searched.where((o) => o.isActive).toList() : <_HistoryOrder>[];
    final pastOrders = showPast ? searched.where((o) => !o.isActive).toList() : <_HistoryOrder>[];
    final hasResults = activeOrders.isNotEmpty || pastOrders.isNotEmpty;

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
            // Top Ready for Pickup Notification Banner
            Container(
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
                          'Order #FP-2028-0142',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ready for pickup at 4:00 PM today',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF868889),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

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
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                    )
                  else
                    const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF94A3B8)),
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

  Widget _buildOrderCard(_HistoryOrder order) {
    final orderId = order.orderId;
    final status = order.status;
    final statusBgColor = order.statusBgColor;
    final statusTextColor = order.statusTextColor;
    final dateTime = order.dateTime;
    final itemCountLabel = order.itemCountLabel;
    final price = order.price;
    final foodIcons = order.foodIcons;

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
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Date & Time
          Text(
            dateTime,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF868889),
            ),
          ),

          const SizedBox(height: 12),

          // Food items icons row
          Row(
            children: [
              ...foodIcons.map(
                (icon) => Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.brandGreen),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    itemCountLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF868889),
                    ),
                  ),
                  Text(
                    price,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandGreenDark,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contacting store regarding $orderId...'),
                        backgroundColor: const Color(0xFF1E293B),
                        behavior: SnackBarBehavior.floating,
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
        ],
      ),
    );
  }
}
