import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/home_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../constants/app_constants.dart';
import 'hover_dropdown_menu.dart';
import 'search_bar_widget.dart';

/// Top navigation bar widget with clean light theme
class TopNavBar extends ConsumerWidget {
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).asData?.value;
    final cartCount = ref.watch(cartCountProvider).asData?.value ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1024 && screenWidth >= 768;
    final isMobile = screenWidth < 768;

    // Get default address if available
    ShippingAddress? defaultAddress;
    if (user?.addresses.isNotEmpty == true) {
      try {
        defaultAddress = ShippingAddress.fromString(
          user!.addresses.firstWhere(
            (addr) => addr.split('|')[8].toLowerCase() == 'true',
            orElse: () => user.addresses.first,
          ),
        );
      } catch (e) {
        print('Error parsing address: $e');
      }
    }

    return Container(
      color: const Color(0xFF232F3E),
      height: 60,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : isTablet ? 12 : 16,
          vertical: 8,
        ),
        child: Row(
          children: [
            // Logo
            InkWell(
              onTap: () => context.go('/'),
              child: Image.asset(
                'images/amazon_logo.png',
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'Amazon',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AmazonEmber',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),

            // Deliver to button
            if (!isMobile) ...[
              InkWell(
                onTap: () {
                  if (user == null) {
                    context.push('/login');
                  } else {
                    context.push('/addresses');
                  }
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user == null ? 'Hello' : 'Deliver to ${user.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          user == null 
                            ? 'Select your address' 
                            : defaultAddress != null 
                              ? '${defaultAddress.city} ${defaultAddress.zipCode}'
                              : 'Add an address',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],

            // Search bar
            Expanded(
              child: SearchBarWidget(
                isSmallScreen: isMobile || isTablet,
              ),
            ),

            // Account & Lists
            if (!isMobile) ...[
              const SizedBox(width: 16),
              _buildAccountButton(context, ref, user),
            ],

            // Orders
            if (!isMobile) ...[
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  if (user == null) {
                    context.push('/login');
                  } else {
                    context.push('/orders');
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Returns & Orders',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            // Cart
            const SizedBox(width: 16),
            _buildCartButton(context, cartCount),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountButton(BuildContext context, WidgetRef ref, UserModel? user) {
    return HoverDropdownMenu(
      menuWidth: 250,
      offset: const Offset(0, 4),
      trigger: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user == null ? 'Hello, sign in' : 'Hello, ${user.name}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          Row(
            children: [
              const Text(
                'Account & Lists',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
            ],
          ),
        ],
      ),
      items: [
        if (user == null) ...[
          HoverDropdownItem(
            text: 'Sign in',
            onTap: () => context.push('/login'),
            icon: Icons.login,
          ),
          const HoverDropdownItem(
            text: 'New customer? Start here',
            icon: Icons.person_add,
            showDivider: true,
          ),
        ],
        HoverDropdownItem(
          text: 'Your Account',
          onTap: () => context.push('/profile'),
          icon: Icons.person_outline,
        ),
        HoverDropdownItem(
          text: 'Your Orders',
          onTap: () => context.push('/orders'),
          icon: Icons.shopping_bag_outlined,
        ),
        if (user != null) ...[
          HoverDropdownItem(
            text: 'Sign Out',
            onTap: () => ref.read(userProvider.notifier).signOut(),
            icon: Icons.logout,
          ),
        ],
      ],
    );
  }

  Widget _buildCartButton(BuildContext context, int cartCount) {
    return InkWell(
      onTap: () => context.push('/cart'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 4),
              const Text(
                'Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (cartCount > 0)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9900),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  cartCount.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 