import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_section_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_section_model.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
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
          SliverToBoxAdapter(child: TopNavBar()),
          
          // Unified category navigation 
          SliverToBoxAdapter(child: CategoryNavBar()),
          
          // Hero banner section
          SliverToBoxAdapter(child: _HeroBanner()),
          
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
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
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
            context.go('/orders');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
    );
  }
}

/// Widget that dynamically loads and displays product sections from Firestore
class _DynamicProductSections extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsyncValue = ref.watch(productSectionsStreamProvider);

    return sectionsAsyncValue.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, error, ref),
      data: (sections) => _buildProductSections(context, sections),
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

/// Widget for individual product section card
class _ProductSectionCard extends StatelessWidget {
  final ProductSection section;

  const _ProductSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF232F3E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (section.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    section.subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Products grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildProductsGrid(),
            ),
          ),
          // See more button
          if (section.seeMoreText != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => _handleSeeMore(context),
                child: Text(
                  section.seeMoreText!,
                  style: const TextStyle(
                    color: Color(0xFF007185),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build products grid (2x2)
  Widget _buildProductsGrid() {
    if (!section.hasProducts) {
      return _buildEmptyProductsState();
    }

    final products = section.displayProducts;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: products.asMap().entries.map((entry) {
        final product = entry.value;
        return _ProductCard(product: product);
      }).toList(),
    );
  }

  /// Build empty products state
  Widget _buildEmptyProductsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No products available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle see more button tap
  void _handleSeeMore(BuildContext context) {
    if (section.seeMoreRoute != null) {
      context.push(section.seeMoreRoute!);
    } else {
      // Default action - determine category from section title or use first product's category
      String category = '';
      if (section.hasProducts && section.products.isNotEmpty) {
        category = section.products.first.category;
      } else {
        // Fallback: try to extract category from section title
        final title = section.title.toLowerCase();
        if (title.contains('electronics')) {
          category = 'electronics';
        } else if (title.contains('fashion')) {
          category = 'fashion';
        } else if (title.contains('home') || title.contains('kitchen')) {
          category = 'home & kitchen';
        } else if (title.contains('books')) {
          category = 'books';
        } else if (title.contains('sports')) {
          category = 'sports';
        } else {
          category = 'all'; // fallback
        }
      }
      
      if (category.isNotEmpty) {
        context.push('/category/${Uri.encodeComponent(category)}');
      }
    }
  }
}

/// Widget for individual product card
class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToProduct(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _buildProductImage(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Product details
          _buildProductDetails(),
        ],
      ),
    );
  }

  /// Build product image with error handling
  Widget _buildProductImage() {
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;
    
    if (imageUrl == null) {
      return _buildPlaceholderImage();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }

  /// Build placeholder image
  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }

  /// Build product details section
  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF232F3E),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              '${AppConstants.currencySymbol}${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB12704),
              ),
            ),
            if (product.hasDiscount) ...[
              const SizedBox(width: 4),
              Text(
                '${AppConstants.currencySymbol}${product.originalPrice!.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        if (product.rating > 0) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.star,
                size: 12,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 2),
              Text(
                '${product.rating.toStringAsFixed(1)} (${product.reviewCount})',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Navigate to product detail screen
  void _navigateToProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(productId: product.id),
      ),
    );
  }
}

/// Hero banner widget
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      height: isMobile ? 180 : 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF232F3E),
            const Color(0xFF131A22),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grain" width="100" height="100" patternUnits="userSpaceOnUse"><circle cx="50" cy="50" r="1" fill="white"/></pattern></defs><rect width="100" height="100" fill="url(%23grain)"/></svg>'),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),
          ),
          
          // Main content
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome text
                  Text(
                    'Welcome to Amazon Clone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 8 : 12),
                  
                  // Subtitle
                  Text(
                    'Discover millions of products with fast delivery',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: isMobile ? 14 : 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 16 : 24),
                  
                                     // CTA Button
                   ElevatedButton(
                      onPressed: () {
                        // Scroll to products or navigate to deals
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9900),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 32,
                          vertical: isMobile ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Shop Now',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Decorative elements
          if (!isMobile) ...[
            Positioned(
              right: 40,
              top: 30,
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 80,
              color: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Icon(
                Icons.local_shipping_outlined,
                size: 60,
              color: Colors.white.withOpacity(0.08),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 