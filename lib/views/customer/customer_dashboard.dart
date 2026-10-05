import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/grocery_service.dart';
import 'cart_screen.dart';
import 'customer_home_tab.dart';
import 'favorites_tab.dart';
import 'profile_tab.dart';

class CustomerDashboard extends StatefulWidget {
  final UserModel user;

  const CustomerDashboard({
    super.key,
    required this.user,
  });

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final groceryService = GroceryService();

    final List<Widget> tabs = [
      CustomerHomeTab(user: widget.user),
      ProfileTab(user: widget.user),
      const FavoritesTab(),
    ];

    return ListenableBuilder(
      listenable: groceryService,
      builder: (context, _) {
        final cartCount = groceryService.totalCartItemCount;

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFB),
          body: IndexedStack(
            index: _currentTabIndex,
            children: tabs,
          ),
          bottomNavigationBar: Container(
            height: 68,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFF0F1F2), width: 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Home Tab Icon
                    _buildNavItem(
                      index: 0,
                      activeIcon: Icons.home_rounded,
                      inactiveIcon: Icons.home_outlined,
                      activeColor: const Color(0xFF2EB844),
                      onTap: () => setState(() => _currentTabIndex = 0),
                    ),

                    // Profile Tab Icon
                    _buildNavItem(
                      index: 1,
                      activeIcon: Icons.person_rounded,
                      inactiveIcon: Icons.person_outline_rounded,
                      activeColor: const Color(0xFF2EB844),
                      onTap: () => setState(() => _currentTabIndex = 1),
                    ),

                    // Favorites Tab Icon
                    _buildNavItem(
                      index: 2,
                      activeIcon: Icons.favorite_rounded,
                      inactiveIcon: Icons.favorite_border_rounded,
                      activeColor: const Color(0xFFFE5858),
                      onTap: () => setState(() => _currentTabIndex = 2),
                    ),

                    // Circular Green Cart Button (Figma design floating green cart button)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CartScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.brandGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandGreen.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            if (cartCount > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                  child: Text(
                                    '$cartCount',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.brandGreen,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 24,
              color: isSelected ? activeColor : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 4 : 0,
              height: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
