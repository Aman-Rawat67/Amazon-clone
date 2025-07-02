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
  final bool isFullWidth;

  const ProductSectionWidget({
    super.key,
    required this.section,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('debugging19: ${section.title}');
    if (!section.hasProducts) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (section.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          section.subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // See all link
                if (section.seeMoreText != null)
                  TextButton(
                    onPressed: () {
                      // If it's a "See all offers" link, navigate to offers screen
                      if (section.seeMoreText?.toLowerCase().contains('offers') == true) {
                        context.push('/offers');
                      } else if (section.seeMoreRoute != null) {
                        context.push(section.seeMoreRoute!);
                      } else {
                        final category = section.products.isNotEmpty
                            ? section.products.first.category.toLowerCase()
                            : 'all';
                        context.push('/category/${Uri.encodeComponent(category)}');
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      section.seeMoreText ?? 'See all offers',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Products Grid
          SizedBox(
            height: isFullWidth ? null : 320,
            child: isFullWidth
                ? _buildProductGrid(context)
                : _buildProductRow(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: section.products.length,
      itemBuilder: (context, index) {
        return Container(
          width: 200,
          margin: EdgeInsets.only(
            right: index < section.products.length - 1 ? 16 : 0,
          ),
          child: ProductCard(
            product: section.products[index],
            showAddToCart: false,
          ),
        );
      },
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: section.products.length,
          itemBuilder: (context, index) => ProductCard(
            product: section.products[index],
            showAddToCart: true,
          ),
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }
}
