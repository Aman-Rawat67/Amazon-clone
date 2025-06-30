import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_model.dart';
import '../../models/product_section_model.dart';
import '../../constants/app_constants.dart';
import 'product_card.dart';

/// Product section widget for displaying groups of products
class ProductSectionWidget extends ConsumerWidget {
  final ProductSection section;

  const ProductSectionWidget({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('debugging19: ${section.title}');
    if (!section.hasProducts) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            _buildSectionHeader(context),

            const SizedBox(height: 20),

            // Products grid
            _buildProductsGrid(context),

            // See more button
            if (section.seeMoreText != null) _buildSeeMoreButton(context),
          ],
        ),
      ),
    );
  }

  /// Build section header with title and subtitle
  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (section.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  section.subtitle!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),

        // Optional section banner image
        if (section.imageUrl != null)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(section.imageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }

  /// Build responsive products grid
  Widget _buildProductsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine grid layout based on screen width
        int crossAxisCount;
        double childAspectRatio;
        double crossAxisSpacing = 16;
        double mainAxisSpacing = 16;

        if (constraints.maxWidth < 600) {
          // Mobile: 1 column
          crossAxisCount = 1;
          childAspectRatio = 1.2;
        } else if (constraints.maxWidth < 900) {
          // Tablet: 2 columns
          crossAxisCount = 2;
          childAspectRatio = 0.8;
        } else if (constraints.maxWidth < 1200) {
          // Small desktop: 3 columns
          crossAxisCount = 3;
          childAspectRatio = 0.75;
        } else {
          // Large desktop: 4 columns
          crossAxisCount = 4;
          childAspectRatio = 0.7;
        }

        // Show only display count products
        final productsToShow = section.displayProducts;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: productsToShow.length,
          itemBuilder: (context, index) {
            final product = productsToShow[index];
            return _buildRecommendedProductCard(product);
          },
        );
      },
    );
  }

  /// Build see more button
  Widget _buildSeeMoreButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: TextButton(
          onPressed: () {
            String? route = section.seeMoreRoute;

            if (route == null) {
              // Default action - determine category from section or use first product's category
              String? category;

              // Try to get category from first product
              if (section.hasProducts && section.products.isNotEmpty) {
                category = section.products.first.category.toLowerCase();
              }

              // If no category from product, try to extract from section title
              if (category == null || category.isEmpty) {
                final title = section.title.toLowerCase();
                if (title.contains('electronics')) {
                  category = 'electronics';
                } else if (title.contains('fashion')) {
                  category = 'fashion';
                } else if (title.contains('home') ||
                    title.contains('kitchen')) {
                  category = 'home & kitchen';
                } else if (title.contains('books')) {
                  category = 'books';
                } else if (title.contains('sports')) {
                  category = 'sports';
                } else if (title.contains('beauty')) {
                  category = 'beauty';
                } else if (title.contains('toys')) {
                  category = 'toys';
                } else if (title.contains('automotive')) {
                  category = 'automotive';
                } else if (title.contains('health')) {
                  category = 'health';
                } else if (title.contains('grocery')) {
                  category = 'grocery';
                }
              }

              // Create route with encoded category
              if (category != null && category.isNotEmpty) {
                route = '/category/${Uri.encodeComponent(category)}';
              } else {
                route = '/category/all'; // fallback to all products
              }
            }

            context.push(route);
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(section.seeMoreText ?? 'See more'),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () => context.go('/product/${product.id}'),
      child: Container(
        // ... existing code ...
      ),
    );
  }
}
