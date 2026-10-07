import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/saved_card.dart';
import '../../services/card_service.dart';
import 'add_card_screen.dart';
import 'widgets/card_form_widgets.dart';
import 'widgets/credit_card_visual.dart';

class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  final _cardService = CardService();
  final Map<String, TextEditingController> _nameDrafts = {};
  final Map<String, TextEditingController> _expiryDrafts = {};
  final Set<String> _removed = {};
  String? _expandedId;
  String? _draftDefaultId;

  @override
  void initState() {
    super.initState();
    _draftDefaultId = _cardService.defaultCard?.id;
  }

  @override
  void dispose() {
    for (final c in [..._nameDrafts.values, ..._expiryDrafts.values]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _nameFor(SavedCard card) =>
      _nameDrafts.putIfAbsent(card.id, () => TextEditingController(text: card.holderName));

  TextEditingController _expiryFor(SavedCard card) =>
      _expiryDrafts.putIfAbsent(card.id, () => TextEditingController(text: card.expiry));

  void _saveSettings() {
    for (final id in _removed) {
      _cardService.removeCard(id);
    }
    for (final card in _cardService.cards) {
      final name = _nameDrafts[card.id]?.text.trim();
      final expiry = _expiryDrafts[card.id]?.text;
      if (expiry != null && expiry != card.expiry && CardValidators.expiry(expiry) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Check the expiry date for •••• ${card.last4}.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      _cardService.updateCard(
        card.id,
        holderName: (name != null && name.length >= 2) ? name : null,
        expiry: expiry,
      );
    }
    if (_draftDefaultId != null && !_removed.contains(_draftDefaultId)) {
      _cardService.setDefault(_draftDefaultId!);
    }
    _removed.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Card settings saved!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.brandGreenDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cardService,
      builder: (context, _) {
        final cards = _cardService.cards.where((c) => !_removed.contains(c.id)).toList();

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
              'My Cards',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Add card',
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF1E293B)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCardScreen()),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: cards.isEmpty ? _buildEmpty() : _buildList(cards),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.credit_card_off_outlined, size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 14),
          Text(
            'No saved cards yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a card to check out faster next time.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF868889)),
          ),
          const SizedBox(height: 24),
          GreenGradientButton(
            label: 'Add credit card',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCardScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<SavedCard> cards) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildCardTile(cards[index]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: GreenGradientButton(label: 'Save settings', onPressed: _saveSettings),
        ),
      ],
    );
  }

  Widget _buildCardTile(SavedCard card) {
    final isDefault = _draftDefaultId == card.id;
    final expanded = _expandedId == card.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDefault)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandGreenSoft,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'DEFAULT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.brandGreenDark,
                ),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _expandedId = expanded ? null : card.id),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Center(child: CardBrandLogo(brand: card.brand, size: 22)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.brandLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              card.maskedNumber,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF868889),
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Expiry: ${card.expiry}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isDefault
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 20,
                        color: isDefault ? AppColors.brandGreen : const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    children: [
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),
                      CardTextField(
                        controller: _nameFor(card),
                        hint: 'Name on the card',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 10),
                      CardTextField(
                        controller: _expiryFor(card),
                        hint: 'Month / Year (MM/YY)',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          ExpiryFormatter(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GreenSwitchRow(
                            label: 'Make default',
                            value: isDefault,
                            onChanged: (v) {
                              if (v) setState(() => _draftDefaultId = card.id);
                            },
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _removed.add(card.id);
                              if (_draftDefaultId == card.id) {
                                final remaining = _cardService.cards
                                    .where((c) => !_removed.contains(c.id))
                                    .toList();
                                _draftDefaultId = remaining.isNotEmpty ? remaining.first.id : null;
                              }
                              _expandedId = null;
                            }),
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                            label: Text(
                              'Remove',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
