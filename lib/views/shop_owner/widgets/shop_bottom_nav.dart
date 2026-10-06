import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';

/// Bottom navigation from the Figma file: Dashboard, Orders, Products, Profile.
class ShopBottomNav extends StatelessWidget {
  const ShopBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const List<IconData> _icons = [
    Icons.dashboard_outlined,
    Icons.assignment_outlined,
    Icons.inventory_2_outlined,
    Icons.storefront_outlined,
  ];

  static const List<String> _labels = [
    'Dashboard',
    'Orders',
    'Products',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ShopColors.background,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F1B5E20),
            offset: Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _labels.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _icons[i],
                      label: _labels[i],
                      selected: i == currentIndex,
                      onTap: () => onChanged(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ShopColors.primary : ShopColors.textSecondary;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(label, style: ShopText.label.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
