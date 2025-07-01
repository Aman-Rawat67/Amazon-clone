import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/home_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../constants/app_constants.dart';
import '../../constants/filter_constants.dart';
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
            (addr) {
              final parts = addr.split('|');
              return parts.length > 8 && parts[8].toLowerCase() == 'true';
            },
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
                'assets/images/amazon_logo.png',
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
              _buildDeliverToButton(context, user, defaultAddress),
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
            
            // Filter button
            const SizedBox(width: 16),
            _buildFilterButton(context, ref),
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
          ),
          const HoverDropdownDivider(),
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

  Widget _buildDeliverToButton(BuildContext context, UserModel? user, ShippingAddress? defaultAddress) {
    if (user == null) {
      return InkWell(
        onTap: () => context.push('/login'),
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
                const Text(
                  'Hello',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const Text(
                  'Select your address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return HoverDropdownMenu(
      menuWidth: 300,
      offset: const Offset(0, 4),
      trigger: Row(
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
                'Deliver to ${user.name}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Row(
                children: [
                  Text(
                    defaultAddress != null 
                      ? '${defaultAddress.city} ${defaultAddress.zipCode}'
                      : 'Add an address',
                    style: const TextStyle(
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
        ],
      ),
      items: [
        // Add new address option
        HoverDropdownItem(
          text: 'Add a new address',
          onTap: () => context.push('/addresses'),
          icon: Icons.add_location,
        ),
        
        if (user.addresses.isNotEmpty) const HoverDropdownDivider(),
        
        // Show existing addresses (limit to first 3 for dropdown)
        ...user.addresses.take(3).map((addressString) {
          try {
            final address = ShippingAddress.fromString(addressString);
            return HoverDropdownItem(
              text: '${address.name} - ${address.city}, ${address.state} ${address.zipCode}${address.isDefault ? ' (Default)' : ''}',
              onTap: () => context.push('/addresses'),
              icon: address.isDefault ? Icons.radio_button_checked : Icons.location_on,
              isSelected: address.isDefault,
            );
          } catch (e) {
            // Skip invalid address strings
            return HoverDropdownItem(
              text: 'Invalid address',
              onTap: () {},
              icon: Icons.error,
            );
          }
        }).toList(),
        
        // Show more addresses option if there are more than 3
        if (user.addresses.length > 3) ...[
          const HoverDropdownDivider(),
          HoverDropdownItem(
            text: 'See all addresses (${user.addresses.length})',
            onTap: () => context.push('/addresses'),
            icon: Icons.list,
          ),
        ],
        
        // Manage addresses option
        if (user.addresses.isNotEmpty) ...[
          const HoverDropdownDivider(),
          HoverDropdownItem(
            text: 'Manage addresses',
            onTap: () => context.push('/addresses'),
            icon: Icons.settings,
          ),
        ],
      ],
    );
  }

  Widget _buildFilterButton(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(productFiltersProvider);
    final hasActiveFilters = filters.hasActiveFilters;

    return HoverDropdownMenu(
      menuWidth: 220,
      offset: const Offset(0, 4),
      trigger: Row(
        children: [
          Icon(
            Icons.filter_alt,
            color: hasActiveFilters ? Colors.amber : Colors.white,
            size: 24,
          ),
          const SizedBox(width: 4),
          Text(
            'Sort & Filter',
            style: TextStyle(
              color: hasActiveFilters ? Colors.amber : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
        ],
      ),
      items: [
        // Sort options header
        const HoverDropdownItem(
          text: 'Sort by',
          isHeader: true,
          icon: Icons.sort,
        ),
        
        // Newest First
        HoverDropdownItem(
          text: 'Newest First',
          icon: Icons.new_releases,
          isSelected: filters.sortBy == SortOption.newest,
          onTap: () {
            ref.read(productFiltersProvider.notifier).updateSortBy(SortOption.newest);
          },
        ),
        
        // Price: Low to High
        HoverDropdownItem(
          text: 'Price: Low to High',
          icon: Icons.arrow_upward,
          isSelected: filters.sortBy == SortOption.priceLowToHigh,
          onTap: () {
            ref.read(productFiltersProvider.notifier).updateSortBy(SortOption.priceLowToHigh);
          },
        ),
        
        // Price: High to Low
        HoverDropdownItem(
          text: 'Price: High to Low',
          icon: Icons.arrow_downward,
          isSelected: filters.sortBy == SortOption.priceHighToLow,
          onTap: () {
            ref.read(productFiltersProvider.notifier).updateSortBy(SortOption.priceHighToLow);
          },
        ),
        
        // Popularity
        HoverDropdownItem(
          text: 'Popularity',
          icon: Icons.trending_up,
          isSelected: filters.sortBy == SortOption.popularity,
          onTap: () {
            ref.read(productFiltersProvider.notifier).updateSortBy(SortOption.popularity);
          },
        ),

        const HoverDropdownDivider(),

        // Price range header
        const HoverDropdownItem(
          text: 'Price Range',
          isHeader: true,
          icon: Icons.currency_rupee,
        ),
        
        // Under ₹500
        HoverDropdownItem(
          text: 'Under ₹500',
          icon: Icons.currency_rupee,
          isSelected: filters.maxPrice == 500,
          onTap: () {
            ref.read(productFiltersProvider.notifier).updatePriceRange(0, 500);
          },
        ),
        
        // ₹500 - ₹2000
        HoverDropdownItem(
          text: '₹500 - ₹2000',
          icon: Icons.currency_rupee,
          isSelected: filters.minPrice == 500 && filters.maxPrice == 2000,
          onTap: () {
            ref.read(productFiltersProvider.notifier).updatePriceRange(500, 2000);
          },
        ),
        
        // Above ₹2000
        HoverDropdownItem(
          text: 'Above ₹2000',
          icon: Icons.currency_rupee,
          isSelected: filters.minPrice == 2000 && filters.maxPrice == null,
          onTap: () {
            ref.read(productFiltersProvider.notifier).updatePriceRange(2000, null);
          },
        ),

        const HoverDropdownDivider(),

        // Rating header
        const HoverDropdownItem(
          text: 'Rating',
          isHeader: true,
          icon: Icons.star,
        ),
        
        // 4★ & above
        HoverDropdownItem(
          text: '4★ & above',
          icon: Icons.star,
          isSelected: filters.minRating == 4,
          onTap: () {
            ref.read(productFiltersProvider.notifier).updateRating(4);
          },
        ),
        
        // 3★ & above
        HoverDropdownItem(
          text: '3★ & above',
          icon: Icons.star,
          isSelected: filters.minRating == 3,
          onTap: () {
            ref.read(productFiltersProvider.notifier).updateRating(3);
          },
        ),

        if (hasActiveFilters) ...[
          const HoverDropdownDivider(),
          
          // Reset filters
          HoverDropdownItem(
            text: 'Reset All Filters',
            icon: Icons.refresh,
            onTap: () {
              ref.read(productFiltersProvider.notifier).resetFilters();
            },
          ),
        ],
      ],
    );
  }
} 