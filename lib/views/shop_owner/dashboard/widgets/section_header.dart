import 'package:flutter/material.dart';

import '../../../../core/theme/shop_owner_theme.dart';

/// Small upper-case caption such as "OVERVIEW".
class SectionCaption extends StatelessWidget {
  const SectionCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Text(text.toUpperCase(), style: ShopText.caps),
    );
  }
}

/// Section title with an optional leading icon and a link on the right,
/// for example "Low Stock ............ view".
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.leadingIcon,
    this.leadingIconColor = ShopColors.error,
    this.linkLabel,
    this.onLinkTap,
  });

  final String title;
  final IconData? leadingIcon;
  final Color leadingIconColor;
  final String? linkLabel;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    final link = linkLabel;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 20, color: leadingIconColor),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              title,
              style: ShopText.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (link != null)
            InkWell(
              onTap: onLinkTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      link,
                      style: ShopText.label.copyWith(color: ShopColors.primary),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: ShopColors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
