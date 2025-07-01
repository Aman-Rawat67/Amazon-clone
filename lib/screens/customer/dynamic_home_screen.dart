import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_section_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_section_model.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../constants/filter_constants.dart';
import '../../widgets/home/top_nav_bar.dart';
import '../../widgets/home/category_nav_bar.dart';
import 'product_detail_screen.dart';

/// Dynamic Amazon-style homepage that fetches sections from Firebase
class DynamicHomeScreen extends ConsumerWidget {
  const DynamicHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: CustomScrollView(
        slivers: [
          // Main navigation with logo, search, account, cart
          const SliverToBoxAdapter(child: TopNavBar()),
          
          // Unified category navigation 
          const SliverToBoxAdapter(child: CategoryNavBar()),
          
          // Hero banner section
          const SliverToBoxAdapter(child: _HeroBanner()),
          
          // Spacing after hero
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
          
          // Dynamic product sections from Firestore
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: _DynamicProductSections(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNavigationBar(context) : null,
    );
  }

  /// Build bottom navigation bar for mobile
  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.filter_alt), label: 'Sort'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: 0, // Highlight home tab
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on home, no need to navigate
            break;
          case 1:
            context.go('/cart');
            break;
          case 2:
            _showSortFilterModal(context);
            break;
          case 3:
            context.go('/orders');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
    );
  }

  /// Show sort and filter modal for mobile
  void _showSortFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MobileSortFilterModal(),
    );
  }
}

/// Widget that dynamically loads and displays product sections from Firestore
class _DynamicProductSections extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsyncValue = ref.watch(productSectionsStreamProvider);
    final filteredProductsAsyncValue = ref.watch(filteredProductsProvider);
    final filters = ref.watch(productFiltersProvider);

    return sectionsAsyncValue.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, error, ref),
      data: (sections) {
        return filteredProductsAsyncValue.when(
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(context, error, ref),
          data: (filteredProducts) {
            // If filters are active, show all filtered products in a single section
            if (filters.hasActiveFilters) {
              if (filteredProducts.isEmpty) {
                return _buildNoResultsState();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter title and count
                    Text(
                      _getFilterTitle(filters),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${filteredProducts.length} products found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Products grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount;
                        double childAspectRatio;
                        if (constraints.maxWidth < 600) {
                          crossAxisCount = 2;
                          childAspectRatio = 0.8;
                        } else if (constraints.maxWidth < 900) {
                          crossAxisCount = 3;
                          childAspectRatio = 0.85;
                        } else if (constraints.maxWidth < 1200) {
                          crossAxisCount = 4;
                          childAspectRatio = 0.9;
                        } else {
                          crossAxisCount = 5;
                          childAspectRatio = 0.95;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: childAspectRatio,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            return _ProductCard(product: filteredProducts[index]);
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            }

            // If no filters, show regular sections with their products
            final updatedSections = sections.map((section) {
              return section.copyWith(
                products: section.products.where((product) {
                  return filteredProducts.any((p) => p.id == product.id);
                }).toList(),
              );
            }).toList();

            return _buildProductSections(context, updatedSections);
          },
        );
      },
    );
  }

  /// Get title based on active filters
  String _getFilterTitle(ProductFilters filters) {
    final List<String> filterParts = [];

    // Add sort option
    switch (filters.sortBy) {
      case SortOption.priceLowToHigh:
        filterParts.add('Price: Low to High');
        break;
      case SortOption.priceHighToLow:
        filterParts.add('Price: High to Low');
        break;
      case SortOption.popularity:
        filterParts.add('Most Popular');
        break;
      case SortOption.newest:
        filterParts.add('Newest First');
        break;
    }

    // Add price range
    if (filters.minPrice != null || filters.maxPrice != null) {
      if (filters.maxPrice == 500) {
        filterParts.add('Under ₹500');
      } else if (filters.minPrice == 500 && filters.maxPrice == 2000) {
        filterParts.add('₹500 - ₹2000');
      } else if (filters.minPrice == 2000) {
        filterParts.add('Above ₹2000');
      }
    }

    // Add rating
    if (filters.minRating != null) {
      filterParts.add('${filters.minRating}★ & above');
    }

    return filterParts.join(' • ');
  }

  /// Build no results state
  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading state with shimmer-like effect
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: List.generate(3, (index) => _buildShimmerSection()),
      ),
    );
  }

  /// Build shimmer section placeholder
  Widget _buildShimmerSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title shimmer
          Container(
            height: 20,
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // Products grid shimmer
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: List.generate(4, (index) => _buildShimmerProduct()),
          ),
        ],
      ),
    );
  }

  /// Build shimmer product placeholder
  Widget _buildShimmerProduct() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  /// Build error state with retry option
  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                  : [Colors.white, const Color(0xFFF5F5F5)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We couldn\'t load the product sections.\nThis usually means your data needs to be set up.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Auto-fix button (primary action)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final firestoreService = ref.read(firestoreServiceProvider);
                      await firestoreService.ensureDataExists();
                      
                      // Refresh the provider after auto-fix
                      ref.refresh(productSectionsStreamProvider);
                      
                      // Show success message
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Data has been automatically configured!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Auto-fix failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Auto-Fix Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Try again button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.refresh(productSectionsStreamProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF232F3E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Secondary actions
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        ref.read(productSectionProvider.notifier).createDemoProductSections();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create Demo Data'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        context.push('/debug-firestore');
                      },
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text('Debug Data'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Error details (expandable)
              ExpansionTile(
                title: Text(
                  'Error Details',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                leading: Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error.toString(),
                      style: TextStyle(
                        color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Try "Auto-Fix Data" first. It will check your database and fix common issues automatically.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build product sections grid
  Widget _buildProductSections(BuildContext context, List<ProductSection> sections) {
    if (sections.isEmpty) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
          double gridPadding = _getGridPadding(constraints.maxWidth);

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: gridPadding),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 32,
                mainAxisSpacing: 32,
                childAspectRatio: 1.1,
              ),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                return _ProductSectionCard(section: sections[index]);
              },
            ),
          );
        },
      ),
    );
  }

  /// Build empty state when no sections available
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No product sections available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Product sections will appear here once they\'re added.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Get cross axis count based on screen width
  int _getCrossAxisCount(double width) {
    if (width < 700) return 1;
    if (width < 1100) return 2;
    if (width < 1400) return 3;
    return 4;
  }

  /// Get grid padding based on screen width
  double _getGridPadding(double width) {
    if (width < 700) return 8;
    if (width < 1100) return 16;
    if (width < 1400) return 24;
    return 48;
  }
}

/// Widget for displaying a product section card
class _ProductSectionCard extends StatelessWidget {
  final ProductSection section;

  const _ProductSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (section.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          section.subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (section.seeMoreText != null)
                  TextButton(
                    onPressed: () => _navigateToSeeMore(context),
                    child: Text(section.seeMoreText!),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Products grid
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: section.products.length,
                itemBuilder: (context, index) {
                  final product = section.products[index];
                  return _ProductCard(product: product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSeeMore(BuildContext context) {
    if (section.seeMoreRoute != null) {
      context.push(section.seeMoreRoute!);
    } else {
      // Extract category from section title or first product
      String category = '';
      if (section.hasProducts && section.products.isNotEmpty) {
        category = section.products.first.category;
      } else {
        // Try to extract category from section title
        final title = section.title.toLowerCase();
        if (title.contains('electronics')) {
          category = 'Electronics';
        } else if (title.contains('fashion')) {
          category = 'Fashion';
        } else if (title.contains('home') || title.contains('kitchen')) {
          category = 'Home & Kitchen';
        } else if (title.contains('books')) {
          category = 'Books';
        } else if (title.contains('sports')) {
          category = 'Sports';
        } else {
          category = 'All'; // fallback
        }
      }

      // Navigate to category products screen
      context.push('/category/${Uri.encodeComponent(category.toLowerCase())}');
    }
  }
}

/// Widget for displaying a product card within a section
class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () => context.go('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: Image.network(
                  product.imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Product info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(
                        ' ${product.rating.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero banner section at the top of the home screen
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF232F3E),
            Color(0xFF37475A),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Amazon Clone',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Shop millions of products at great prices',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/home/category/all'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Start Shopping',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile-friendly sort and filter modal for bottom sheet
class _MobileSortFilterModal extends ConsumerStatefulWidget {
  const _MobileSortFilterModal();

  @override
  ConsumerState<_MobileSortFilterModal> createState() => _MobileSortFilterModalState();
}

class _MobileSortFilterModalState extends ConsumerState<_MobileSortFilterModal> {
  late SortOption selectedSort;
  late RangeValues priceRange;
  late double minRating;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(productFiltersProvider);
    selectedSort = filters.sortBy;
    priceRange = RangeValues(
      filters.minPrice ?? 0,
      filters.maxPrice ?? 10000,
    );
    minRating = filters.minRating ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sort & Filter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Reset filters
                    setState(() {
                      selectedSort = SortOption.newest;
                      priceRange = const RangeValues(0, 10000);
                      minRating = 0;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort options
                  const Text(
                    'Sort by',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...SortOption.values.map((option) => RadioListTile<SortOption>(
                    title: Text(_getSortOptionText(option)),
                    value: option,
                    groupValue: selectedSort,
                    onChanged: (value) {
                      setState(() {
                        selectedSort = value!;
                      });
                    },
                  )),
                  
                  const SizedBox(height: 24),
                  
                  // Price range
                  const Text(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('₹${priceRange.start.round()} - ₹${priceRange.end.round()}'),
                  RangeSlider(
                    values: priceRange,
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    labels: RangeLabels(
                      '₹${priceRange.start.round()}',
                      '₹${priceRange.end.round()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        priceRange = values;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Rating filter
                  const Text(
                    'Minimum Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(5, (index) {
                    final rating = index + 1.0;
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          ...List.generate(rating.toInt(), (_) => const Icon(Icons.star, color: Colors.amber, size: 16)),
                          ...List.generate(5 - rating.toInt(), (_) => const Icon(Icons.star_border, color: Colors.grey, size: 16)),
                          Text(' & above'),
                        ],
                      ),
                      value: minRating >= rating,
                      onChanged: (value) {
                        setState(() {
                          minRating = value! ? rating : 0;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          
          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Apply filters
                  ref.read(productFiltersProvider.notifier).updateSortBy(selectedSort);
                  ref.read(productFiltersProvider.notifier).updatePriceRange(
                    priceRange.start == 0 ? null : priceRange.start,
                    priceRange.end == 10000 ? null : priceRange.end,
                  );
                  ref.read(productFiltersProvider.notifier).updateRating(
                    minRating == 0 ? null : minRating,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9900),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return 'Newest First';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.popularity:
        return 'Popularity';
    }
  }
}