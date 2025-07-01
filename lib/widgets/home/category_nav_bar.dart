import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
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
  bool _isNavigating = false;

  final Map<String, List<String>> categories = {
    'Clothing': [
      'Men',
      'Women',
      'Unisex',
      'Boy',
      'Girl',
    ],
    'Electronics': [
      'Mobile Phones',
      'Computers & Laptops',
      'Audio Devices',
      'Home Appliances',
    ],
    'Handloom': [
      'Bedsheets',
      'Curtains',
      'Mattress',
      'Pillow',
    ],
    'Automotive': [
      'Car Perfume',
      'Stereo',
      'Dash Cam',
      'Cameras',
    ],
    'Home': [
      'Kitchen',
      'Gardening',
      'Interior',
      'Furniture',
    ],
  };

  void _navigateToCategory(BuildContext context, String category) {
    if (_isNavigating) return;
    _isNavigating = true;

    // First update the filters
    ref.read(productFiltersProvider.notifier).updateFilters(
      category: category,
      subcategory: null,
    );

    // Then navigate after a short delay to ensure state is updated
    Future.microtask(() {
      final encodedCategory = Uri.encodeComponent(category);
      context.go('/category/$encodedCategory');
      _isNavigating = false;
    });
  }

  void _navigateToSubcategory(BuildContext context, String category, String subcategory) {
    if (_isNavigating) return;
    _isNavigating = true;

    // First update the filters
    ref.read(productFiltersProvider.notifier).updateFilters(
      category: category,
      subcategory: subcategory,
    );

    // Then navigate after a short delay to ensure state is updated
    Future.microtask(() {
      final encodedCategory = Uri.encodeComponent(category);
      final encodedSubcategory = Uri.encodeComponent(subcategory);
      context.go('/category/$encodedCategory/subcategory/$encodedSubcategory');
      _isNavigating = false;
    });
  }

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
                width: 100,
                child: _buildAllMenuItem(),
              ),
              
              // Categories with dropdowns
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...categories.entries.take(_getCategoryCount(availableWidth)).map((entry) {
                        final category = entry.key;
                        final subcategories = entry.value;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: HoverDropdownMenu(
                            menuWidth: 220,
                            offset: const Offset(0, 4),
                            trigger: InkWell(
                              onTap: () => _navigateToCategory(context, category),
                              child: Container(
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
                                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            items: [
                              for (int i = 0; i < subcategories.length; i++) ...[
                                HoverDropdownItem(
                                  text: subcategories[i],
                                  onTap: () => _navigateToSubcategory(context, category, subcategories[i]),
                                ),
                                if (i < subcategories.length - 1) const HoverDropdownDivider(),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      
                      // Additional navigation items based on width
                      ..._getAdditionalItems(availableWidth).map(_buildAdditionalItem),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build mobile navigation with categories
  Widget _buildMobileNavigation(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...categories.keys.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                onPressed: () => _navigateToCategory(context, category),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: Text(category),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Get category count based on available width
  int _getCategoryCount(double width) {
    if (width > 1200) return categories.length;
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
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
} 