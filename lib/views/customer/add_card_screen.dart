import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/saved_card.dart';
import '../../services/card_service.dart';
import 'widgets/card_form_widgets.dart';
import 'widgets/credit_card_visual.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _makeDefault = true;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String get _previewNumber {
    final digits = _numberController.text.replaceAll(' ', '').padRight(16, 'X');
    return [for (int i = 0; i < 16; i += 4) digits.substring(i, i + 4)].join(' ');
  }

  CardBrand get _previewBrand {
    final brand = detectCardBrand(_numberController.text.replaceAll(' ', ''));
    return brand == CardBrand.other ? CardBrand.mastercard : brand;
  }

  void _addCard() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    CardService().addCard(
      cardNumber: _numberController.text,
      holderName: _nameController.text,
      expiry: _expiryController.text,
      makeDefault: _makeDefault,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Card added successfully!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF539C14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Credit Card',
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CreditCardVisual(
                        number: _previewNumber,
                        holder: _nameController.text,
                        expiry: _expiryController.text,
                        brand: _previewBrand,
                      ),
                      const SizedBox(height: 18),
                      CardTextField(
                        controller: _nameController,
                        hint: 'Name on the card',
                        icon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                        validator: CardValidators.name,
                      ),
                      const SizedBox(height: 10),
                      CardTextField(
                        controller: _numberController,
                        hint: 'Card number',
                        icon: Icons.credit_card_rounded,
                        keyboardType: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                          CardNumberFormatter(),
                        ],
                        onChanged: (_) => setState(() {}),
                        validator: CardValidators.cardNumber,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CardTextField(
                              controller: _expiryController,
                              hint: 'Month / Year',
                              icon: Icons.calendar_today_outlined,
                              keyboardType: TextInputType.number,
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
                          Expanded(
                            child: CardTextField(
                              controller: _cvvController,
                              hint: 'CVV',
                              icon: Icons.lock_outline_rounded,
                              keyboardType: TextInputType.number,
                              obscure: true,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              validator: CardValidators.cvv,
                            ),
                          ),
                        ],
                      ),
                      GreenSwitchRow(
                        label: 'Set as default card',
                        value: _makeDefault,
                        onChanged: (v) => setState(() => _makeDefault = v),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Only the last 4 digits are saved. Your full card number and CVV are never stored.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: GreenGradientButton(label: 'Add credit card', onPressed: _addCard),
            ),
          ],
        ),
      ),
    );
  }
}
