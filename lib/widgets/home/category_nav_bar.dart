import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                            child: _buildCategoryItem(
                              context,
                              category,
                              hoveredCategory == category,
                            ),
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

  /// Build individual category item
  Widget _buildCategoryItem(BuildContext context, String category, bool isHovered) {
    return MouseRegion(
      onEnter: (_) {
        ref.read(hoveredCategoryProvider.notifier).state = category;
      },
      onExit: (_) {
        // Add small delay to prevent flickering
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ref.read(hoveredCategoryProvider.notifier).state = null;
          }
        });
      },
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isHovered 
              ? Border.all(color: Colors.white.withOpacity(0.3))
              : null,
        ),
        child: Text(
          category,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isHovered ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// Build mobile category bar (collapsible)
  Widget _buildMobileNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232F3E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      height: 40,
      child: Row(
        children: [
          // Hamburger menu for mobile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () {
                _showMobileCategoryMenu(context);
              },
              child: const Row(
                children: [
                  Icon(Icons.menu, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Featured categories
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: ['Electronics', 'Clothing', 'Home'].map((category) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Show mobile category menu
  void _showMobileCategoryMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Shop by Category',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Categories list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories.keys.elementAt(index);
                                         final subcategories = categories[category] ?? [];
                    
                    return ExpansionTile(
                      title: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                      children: subcategories.map((subcategory) {
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 32, right: 16),
                          title: Text(
                            subcategory,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF111111),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Navigate to subcategory
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 