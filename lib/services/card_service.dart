import 'package:flutter/foundation.dart';
import '../models/saved_card.dart';

/// In-memory store for the customer's saved cards (no card numbers or CVVs).
class CardService extends ChangeNotifier {
  static final CardService _instance = CardService._internal();
  factory CardService() => _instance;
  CardService._internal();

  final List<SavedCard> _cards = [];

  List<SavedCard> get cards => List.unmodifiable(_cards);

  SavedCard? get defaultCard {
    for (final card in _cards) {
      if (card.isDefault) return card;
    }
    return _cards.isNotEmpty ? _cards.first : null;
  }

  /// Saves a card from the full number (only the last 4 digits are kept).
  SavedCard addCard({
    required String cardNumber,
    required String holderName,
    required String expiry,
    bool makeDefault = false,
  }) {
    final digits = cardNumber.replaceAll(' ', '');
    final last4 = digits.substring(digits.length - 4);

    // Re-saving the same card just updates it
    final existing = _cards.indexWhere((c) => c.last4 == last4 && c.expiry == expiry);
    if (existing != -1) {
      final updated = _cards[existing].copyWith(holderName: holderName);
      _cards[existing] = updated;
      if (makeDefault) setDefault(updated.id);
      notifyListeners();
      return _cards[existing];
    }

    final card = SavedCard(
      id: 'card_${DateTime.now().microsecondsSinceEpoch}',
      brand: detectCardBrand(digits),
      last4: last4,
      holderName: holderName.trim(),
      expiry: expiry,
      isDefault: makeDefault || _cards.isEmpty,
    );
    if (card.isDefault) {
      for (int i = 0; i < _cards.length; i++) {
        _cards[i] = _cards[i].copyWith(isDefault: false);
      }
    }
    _cards.add(card);
    notifyListeners();
    return card;
  }

  void updateCard(String id, {String? holderName, String? expiry}) {
    final index = _cards.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _cards[index] = _cards[index].copyWith(holderName: holderName, expiry: expiry);
    notifyListeners();
  }

  void setDefault(String id) {
    for (int i = 0; i < _cards.length; i++) {
      _cards[i] = _cards[i].copyWith(isDefault: _cards[i].id == id);
    }
    notifyListeners();
  }

  void removeCard(String id) {
    final removed = _cards.where((c) => c.id == id).toList();
    _cards.removeWhere((c) => c.id == id);
    if (removed.isNotEmpty && removed.first.isDefault && _cards.isNotEmpty) {
      _cards[0] = _cards[0].copyWith(isDefault: true);
    }
    notifyListeners();
  }
}
