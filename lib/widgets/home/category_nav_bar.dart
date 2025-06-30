import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'hover_dropdown_menu.dart';

/// Provider for currently hovered category
final hoveredCategoryProvider = StateProvider<String?>((ref) => null);

/// Category navigation bar with dropdown subcategories
class CategoryNavBar extends ConsumerStatefulWidget {
  const CategoryNavBar({super.key});

  @override
  ConsumerState<CategoryNavBar> createState() => _CategoryNavBarState();
}

class _CategoryNavBarState extends ConsumerState<CategoryNavBar> {
  final Map<String, List<String>> categories = {
    'Clothing': [
      'Men\'s Fashion',
      'Women\'s Fashion',
      'Kids\' Clothing',
      'Footwear',
      'Watches',
      'Jewelry',
      'Bags & Luggage',
    ],
    'Electronics': [
      'Mobiles',
      'Laptops',
      'Tablets',
      'Cameras',
      'Headphones',
      'Gaming',
      'Smart Watches',
    ],
    'Handloom': [
      'Sarees',
      'Kurtas',
      'Dupattas',
      'Fabrics',
      'Handicrafts',
      'Traditional Wear',
    ],
    'Automotive': [
      'Car Accessories',
      'Bike Accessories',
      'Tools & Equipment',
      'Tyres',
      'Car Care',
      'GPS & Navigation',
    ],
    'Home': [
      'Furniture',
      'Kitchen & Dining',
      'Home Decor',
      'Bedding',
      'Storage',
      'Garden & Outdoor',
    ],
    'Books': [
      'Fiction',
      'Non-Fiction',
      'Educational',
      'Children\'s Books',
      'Comics',
      'E-books',
    ],
    'Health & Personal Care': [
      'Health Care',
      'Personal Care',
      'Beauty',
      'Vitamins',
      'Medical Equipment',
      'Fitness',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final hoveredCategory = ref.watch(hoveredCategoryProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232F3E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile ? _buildMobileNavigation(context) : _buildDesktopNavigation(context, hoveredCategory),
    );
  }

  /// Build desktop navigation with categories and additional items
  Widget _buildDesktopNavigation(BuildContext context, String? hoveredCategory) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          
          return Row(
            children: [
              // All menu with hamburger icon (fixed width)
              SizedBox(
                width: 70,
                child: _buildAllMenuItem(),
              ),
              const SizedBox(width: 16),
              
              // Scrollable categories section (takes remaining space)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Main categories (responsive count)
                        ...categories.keys.take(_getCategoryCount(availableWidth)).map((category) => 
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: _buildCategoryDropdown(context, category),
                          ),
                        ),
                        
                        // Additional navigation items (responsive)
                        ..._getAdditionalItems(availableWidth).map((item) =>
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: _buildAdditionalItem(item),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build category dropdown with subcategories
  Widget _buildCategoryDropdown(BuildContext context, String category) {
    final subcategories = categories[category] ?? [];
    
    return HoverDropdownMenu(
      menuWidth: 220,
      offset: const Offset(0, 4),
      trigger: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
      menuItems: [
        for (final subcategory in subcategories)
          HoverDropdownItem(
            onTap: () {
              // Navigate to category products screen with subcategory
              context.push('/category/$category?subcategory=$subcategory');
            },
            child: _buildSubcategoryItem(subcategory),
          ),
      ],
    );
  }

  /// Build subcategory item with hover effect
  Widget _buildSubcategoryItem(String subcategory) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.arrow_right,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subcategory,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get category count based on available width
  int _getCategoryCount(double width) {
    if (width > 1200) return 7; // All categories
    if (width > 900) return 5;  // Most categories
    if (width > 768) return 3;  // Essential categories
    return 2; // Minimal categories
  }

  /// Get additional items based on available width
  List<String> _getAdditionalItems(double width) {
    if (width > 1200) {
      return ['Today\'s Deals', 'Customer Service', 'Registry', 'Gift Cards', 'Sell'];
    } else if (width > 900) {
      return ['Today\'s Deals', 'Customer Service', 'Sell'];
    } else if (width > 768) {
      return ['Today\'s Deals'];
    }
    return [];
  }

  /// Build additional navigation item
  Widget _buildAdditionalItem(String item) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          item,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// Build "All" menu item with hamburger icon
  Widget _buildAllMenuItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          const Text(
            'All',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build mobile navigation with collapsible menu
  Widget _buildMobileNavigation(BuildContext context) {
    return ExpansionTile(
      title: Row(
        children: [
          const Icon(Icons.menu, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text(
            'All Categories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      collapsedIconColor: Colors.white,
      iconColor: Colors.white,
      backgroundColor: const Color(0xFF232F3E),
      collapsedBackgroundColor: const Color(0xFF232F3E),
      children: [
        Container(
          color: Colors.white,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories.keys.elementAt(index);
              final subcategories = categories[category] ?? [];
              
              return ExpansionTile(
                title: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                children: [
                  for (final subcategory in subcategories)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 32, right: 16),
                      leading: const Icon(Icons.arrow_right, size: 16),
                      title: Text(
                        subcategory,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        // Navigate to category products screen with subcategory
                        context.push('/category/$category?subcategory=$subcategory');
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
} 