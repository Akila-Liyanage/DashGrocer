import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';

/// Small spinner shown inside a button while its action is being saved.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: ShopColors.primary,
      ),
    );
  }
}
