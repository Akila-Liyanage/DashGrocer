import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/saved_card.dart';

/// The green credit card graphic shown on the payment screens.
class CreditCardVisual extends StatelessWidget {
  final String number; // already formatted, e.g. "XXXX XXXX XXXX 8790"
  final String holder;
  final String expiry;
  final CardBrand brand;

  const CreditCardVisual({
    super.key,
    required this.number,
    required this.holder,
    required this.expiry,
    this.brand = CardBrand.mastercard,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.62,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF8FD43A), Color(0xFF4FAE16)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x336CC51D), blurRadius: 16, offset: Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -26,
                bottom: -30,
                child: _circle(110, 0.14),
              ),
              Positioned(
                right: 24,
                top: -34,
                child: _circle(70, 0.12),
              ),
              Positioned(
                right: 58,
                bottom: 10,
                child: _circle(28, 0.18),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _brandLogo(),
                    const Spacer(),
                    Text(
                      number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _labelValue('CARD HOLDER', holder.isEmpty ? 'YOUR NAME' : holder.toUpperCase())),
                        _labelValue('EXPIRES', expiry.isEmpty ? 'MM/YY' : expiry),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _brandLogo() => CardBrandLogo(brand: brand, onGreen: true);
}

/// Small Visa / Mastercard mark drawn with simple shapes (no image assets).
class CardBrandLogo extends StatelessWidget {
  final CardBrand brand;
  final bool onGreen;
  final double size;

  const CardBrandLogo({
    super.key,
    required this.brand,
    this.onGreen = false,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    switch (brand) {
      case CardBrand.visa:
        return Text(
          'VISA',
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.7,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: onGreen ? Colors.white : const Color(0xFF1A4FA0),
          ),
        );
      case CardBrand.mastercard:
        return SizedBox(
          width: size * 1.5,
          height: size,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEB001B)),
                ),
              ),
              Positioned(
                right: 0,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF79E1B).withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
        );
      case CardBrand.other:
        return Icon(
          Icons.credit_card_rounded,
          size: size,
          color: onGreen ? Colors.white : const Color(0xFF64748B),
        );
    }
  }
}
