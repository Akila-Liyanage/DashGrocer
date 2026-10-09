enum CardBrand { visa, mastercard, other }

String cardBrandName(CardBrand brand) {
  switch (brand) {
    case CardBrand.visa:
      return 'Visa';
    case CardBrand.mastercard:
      return 'Mastercard';
    case CardBrand.other:
      return 'Card';
  }
}

CardBrand detectCardBrand(String digits) {
  if (digits.startsWith('4')) return CardBrand.visa;
  if (digits.startsWith('5') || digits.startsWith('2')) return CardBrand.mastercard;
  return CardBrand.other;
}

/// A saved payment card. Only non-sensitive data is kept: the full card
/// number and the CVV are never stored.
class SavedCard {
  final String id;
  final CardBrand brand;
  final String last4;
  final String holderName;
  final String expiry; // MM/YY
  final bool isDefault;

  const SavedCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.holderName,
    required this.expiry,
    this.isDefault = false,
  });

  String get brandLabel {
    switch (brand) {
      case CardBrand.visa:
        return 'Visa Card';
      case CardBrand.mastercard:
        return 'Master Card';
      case CardBrand.other:
        return 'Credit Card';
    }
  }

  String get maskedNumber => 'XXXX XXXX XXXX $last4';

  /// "Visa •••• 4242", used on receipts.
  String get shortLabel => '${cardBrandName(brand)} •••• $last4';

  SavedCard copyWith({String? holderName, String? expiry, bool? isDefault}) {
    return SavedCard(
      id: id,
      brand: brand,
      last4: last4,
      holderName: holderName ?? this.holderName,
      expiry: expiry ?? this.expiry,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
