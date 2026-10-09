import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'payment_screen.dart';

class PickupTimeScreen extends StatefulWidget {
  final String shopName;
  final String shopAddress;
  final double totalAmount;

  const PickupTimeScreen({
    super.key,
    this.shopName = 'Green mart',
    this.shopAddress = '123 Main Street • Open until 9 PM',
    this.totalAmount = 1000.0,
  });

  /// Source of "now". Tests replace this so slot availability is predictable.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  @override
  State<PickupTimeScreen> createState() => _PickupTimeScreenState();
}

class _PickupTimeScreenState extends State<PickupTimeScreen> {
  /// A slot must start at least this long from now to be bookable today.
  static const Duration _leadTime = Duration(minutes: 30);

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Pickup slots offered every day (label, hour in 24h time). The shop is open until 9 PM.
  static const List<(String, int)> _slots = [
    ('9.00 AM', 9),
    ('10.00 AM', 10),
    ('11.00 AM', 11),
    ('12.00 PM', 12),
    ('2.00 PM', 14),
    ('4.00 PM', 16),
    ('5.00 PM', 17),
    ('6.00 PM', 18),
    ('7.00 PM', 19),
  ];

  late String _selectedSlot;
  late String _selectedDay;
  Timer? _ticker;

  DateTime get _now => PickupTimeScreen.clock();

  @override
  void initState() {
    super.initState();
    _selectDefaultSlot();
    // Keep the dates and slots in step with the clock while the screen is open.
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) => _onClockTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Called every few seconds: hides slots that have started, rolls the dates
  /// over at midnight and moves the customer off a slot that is no longer free.
  void _onClockTick() {
    if (!mounted) return;
    final lostSlot = _selectedDay == 'Today' && !_todaySlots.contains(_selectedSlot);
    setState(() {
      if (lostSlot) _selectDefaultSlot();
    });
    if (lostSlot) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'That pickup time has passed. We selected ${_selectedDay.toLowerCase()} at $_selectedSlot instead.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Prefer 4.00 PM today, otherwise the first free slot today, otherwise tomorrow morning.
  void _selectDefaultSlot() {
    final free = _todaySlots;
    if (free.contains('4.00 PM')) {
      _selectedDay = 'Today';
      _selectedSlot = '4.00 PM';
    } else if (free.isNotEmpty) {
      _selectedDay = 'Today';
      _selectedSlot = free.first;
    } else {
      _selectedDay = 'Tomorrow';
      _selectedSlot = _slots.first.$1;
    }
  }

  /// Slots on today's list that have not started yet (and are not too soon).
  List<String> get _todaySlots {
    final now = _now;
    final earliest = now.add(_leadTime);
    return [
      for (final (label, hour) in _slots)
        if (DateTime(now.year, now.month, now.day, hour).isAfter(earliest)) label,
    ];
  }

  List<String> get _tomorrowSlots => [for (final (label, _) in _slots) label];

  String _dateLabel(DateTime date) =>
      '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';

  void _continueToPayment() {
    // The time may have moved on while this screen was open.
    if (_selectedDay == 'Today' && !_todaySlots.contains(_selectedSlot)) {
      setState(_selectDefaultSlot);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'That pickup time has passed. Please choose another slot.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          shopName: widget.shopName,
          pickupSlot: '$_selectedDay, $_selectedSlot',
          totalAmount: widget.totalAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Pickup Time',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Info Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.brandGreenSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: AppColors.brandGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.shopName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.shopAddress,
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

                    const SizedBox(height: 24),

                    // Section 1: Today , <weekday day month>
                    Text(
                      'Today , ${_dateLabel(_now)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_todaySlots.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'No more pickup slots today. Please choose a time tomorrow.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      )
                    else
                      _buildTimeSlotGrid(isToday: true),

                    const SizedBox(height: 24),

                    // Section 2: Tomorrow , <weekday day month>
                    Text(
                      'Tomorrow , ${_dateLabel(_now.add(const Duration(days: 1)))}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSlotGrid(isToday: false),
                  ],
                ),
              ),
            ),

            // Bottom Continue to Payment Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _continueToPayment,
                  child: Text(
                    'Continue to Payment',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotGrid({required bool isToday}) {
    final currentDay = isToday ? 'Today' : 'Tomorrow';
    final slots = isToday ? _todaySlots : _tomorrowSlots;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 10,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = _selectedDay == currentDay && _selectedSlot == slot;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDay = currentDay;
              _selectedSlot = slot;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brandGreenSoft : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.brandGreen : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Center(
              child: Text(
                slot,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.brandGreenDark : const Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
