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
                    IconButton(
                      icon: Icon(
                        _currentTabIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                        size: 26,
                        color: _currentTabIndex == 0
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFF868889),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentTabIndex = 0;
                        });
                      },
                    ),

                    // Profile Tab Icon
                    IconButton(
                      icon: Icon(
                        _currentTabIndex == 1 ? Icons.person_rounded : Icons.person_outline_rounded,
                        size: 26,
                        color: _currentTabIndex == 1
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFF868889),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentTabIndex = 1;
                        });
                      },
                    ),

                    // Favorites Tab Icon
                    IconButton(
                      icon: Icon(
                        _currentTabIndex == 2 ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 24,
                        color: _currentTabIndex == 2
                            ? const Color(0xFFFE5858)
                            : const Color(0xFF868889),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentTabIndex = 2;
                        });
                      },
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
}
