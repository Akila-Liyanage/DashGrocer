import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/saved_card.dart';
import '../../services/auth_service.dart';
import '../../services/card_service.dart';
import '../../services/grocery_service.dart';
import 'my_cards_screen.dart';
import 'order_confirmation_screen.dart';
import 'widgets/card_form_widgets.dart';
import 'widgets/credit_card_visual.dart';

enum _PayMethod { atStore, card }

class PaymentScreen extends StatefulWidget {
  final String shopName;
  final String pickupSlot;
  final double totalAmount;

  const PaymentScreen({
    super.key,
    required this.shopName,
    required this.pickupSlot,
    required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardService = CardService();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  _PayMethod _method = _PayMethod.card;
  SavedCard? _selectedSaved; // null = enter a new card
  bool _saveCard = true;
  bool _isProcessing = false;

  String get _total => 'Rs. ${widget.totalAmount.toStringAsFixed(0)}';

  @override
  void initState() {
    super.initState();
    _selectedSaved = _cardService.defaultCard;
    _cardService.addListener(_onCardsChanged);
  }

  void _onCardsChanged() {
    if (!mounted) return;
    setState(() {
      // Keep the selection valid if the card was removed in My Cards
      if (_selectedSaved != null &&
          !_cardService.cards.any((c) => c.id == _selectedSaved!.id)) {
        _selectedSaved = _cardService.defaultCard;
      }
    });
  }

  @override
  void dispose() {
    _cardService.removeListener(_onCardsChanged);
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String get _previewNumber {
    if (_selectedSaved != null) return _selectedSaved!.maskedNumber;
    final digits = _numberController.text.replaceAll(' ', '').padRight(16, 'X');
    return [for (int i = 0; i < 16; i += 4) digits.substring(i, i + 4)].join(' ');
  }

  CardBrand get _previewBrand {
    if (_selectedSaved != null) return _selectedSaved!.brand;
    final brand = detectCardBrand(_numberController.text.replaceAll(' ', ''));
    return brand == CardBrand.other ? CardBrand.mastercard : brand;
  }

  Future<void> _pay() async {
    final isCard = _method == _PayMethod.card;
    if (isCard && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isProcessing = true);
    // Simulated payment processing (no real payment gateway is connected)
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (isCard && _selectedSaved == null && _saveCard) {
      _cardService.addCard(
        cardNumber: _numberController.text,
        holderName: _nameController.text,
        expiry: _expiryController.text,
      );
    }

    final customer = AuthService().currentUser;
    final orderId = GroceryService().placeOrder(
      customerName: customer?.fullName ?? 'Kasun Perera',
      customerPhone: customer?.phoneNumber ?? '+94 77 123 4567',
      pickupSlot: widget.pickupSlot,
      totalAmount: widget.totalAmount,
      shopName: widget.shopName,
      // No order number is passed: GroceryService gives every order its own.
      paymentMethod: isCard ? 'Paid Online (Card)' : 'Pay at Store',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          orderId: orderId,
          pickupTime: widget.pickupSlot,
          shopName: widget.shopName,
          totalPaid: _total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCard = _method == _PayMethod.card;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Method',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepper(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMethodBox(
                            method: _PayMethod.atStore,
                            icon: Icons.storefront_rounded,
                            label: 'Pay at Store',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMethodBox(
                            method: _PayMethod.card,
                            icon: Icons.credit_card_rounded,
                            label: 'Credit Card',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isCard) _buildCardSection() else _buildStoreSection(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(isCard),
          ],
        ),
      ),
    );
  }

  // Step indicator: Cart ✓ — Pickup ✓ — Payment (3)
  Widget _buildStepper() {
    Widget dot({required bool done, required String label, String? number}) {
      return Column(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.brandGreen : Colors.white,
              border: Border.all(color: AppColors.brandGreen, width: 1.5),
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : Text(
                      number ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandGreen,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      );
    }

    Widget line() => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(height: 2, color: AppColors.brandGreen),
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dot(done: true, label: 'CART'),
        line(),
        dot(done: true, label: 'PICKUP'),
        line(),
        dot(done: false, label: 'PAYMENT', number: '3'),
      ],
    );
  }

  Widget _buildMethodBox({
    required _PayMethod method,
    required IconData icon,
    required String label,
  }) {
    final selected = _method == method;
    return GestureDetector(
      onTap: _isProcessing ? null : () => setState(() => _method = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.brandGreen : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.brandGreen : const Color(0xFF64748B)),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.brandGreenDark : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.storefront_rounded, size: 40, color: AppColors.brandGreen),
          const SizedBox(height: 12),
          Text(
            'Pay when you pick up',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your order will be prepared at ${widget.shopName}. Pay with cash or card at the counter on ${widget.pickupSlot}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF868889),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection() {
    final saved = _cardService.cards;
    final usingSaved = _selectedSaved != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreditCardVisual(
            number: _previewNumber,
            holder: usingSaved ? _selectedSaved!.holderName : _nameController.text,
            expiry: usingSaved ? _selectedSaved!.expiry : _expiryController.text,
            brand: _previewBrand,
          ),
          const SizedBox(height: 14),
          if (saved.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved cards',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                GestureDetector(
                  onTap: _isProcessing
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyCardsScreen()),
                          ),
                  child: Text(
                    'Manage',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandGreenDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final card in saved) ...[
                    _savedChip(
                      label: '•••• ${card.last4}',
                      leading: CardBrandLogo(brand: card.brand, size: 14),
                      selected: _selectedSaved?.id == card.id,
                      onTap: () => setState(() {
                        _selectedSaved = card;
                        _cvvController.clear();
                      }),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _savedChip(
                    label: 'New card',
                    leading: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF64748B)),
                    selected: _selectedSaved == null,
                    onTap: () => setState(() => _selectedSaved = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (!usingSaved) ...[
            CardTextField(
              controller: _nameController,
              hint: 'Name on the card',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              enabled: !_isProcessing,
              onChanged: (_) => setState(() {}),
              validator: CardValidators.name,
            ),
            const SizedBox(height: 10),
            CardTextField(
              controller: _numberController,
              hint: 'Card number',
              icon: Icons.credit_card_rounded,
              keyboardType: TextInputType.number,
              enabled: !_isProcessing,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                CardNumberFormatter(),
              ],
              onChanged: (_) => setState(() {}),
              validator: CardValidators.cardNumber,
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!usingSaved) ...[
                Expanded(
                  child: CardTextField(
                    controller: _expiryController,
                    hint: 'Month / Year',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    enabled: !_isProcessing,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      ExpiryFormatter(),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: CardValidators.expiry,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: CardTextField(
                  controller: _cvvController,
                  hint: 'CVV',
                  icon: Icons.lock_outline_rounded,
                  keyboardType: TextInputType.number,
                  obscure: true,
                  enabled: !_isProcessing,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: CardValidators.cvv,
                ),
              ),
              if (usingSaved) const Spacer(),
            ],
          ),
          if (!usingSaved)
            GreenSwitchRow(
              label: 'Save this card',
              value: _saveCard,
              onChanged: (v) => setState(() => _saveCard = v),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Demo checkout: no real payment is made. Only the last 4 digits are saved, never your CVV.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _savedChip({
    required String label,
    required Widget leading,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandGreenSoft : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.brandGreen : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.brandGreenDark : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isCard) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      color: const Color(0xFFF4F5F9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                _total,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GreenGradientButton(
            label: isCard ? 'Make a payment' : 'Place Order',
            loading: _isProcessing,
            onPressed: _isProcessing ? null : _pay,
          ),
        ],
      ),
    );
  }
}
