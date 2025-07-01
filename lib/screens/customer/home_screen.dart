import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/home/top_nav_bar.dart';
import '../../widgets/home/search_bar_widget.dart';
import '../../widgets/home/category_filter_widget.dart';
import '../../widgets/home/sort_filter_widget.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../constants/filter_constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final productsAsync = ref.watch(filteredProductsProvider);
    final filters = ref.watch(productFiltersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEAEDED),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: TopNavBar()),
          const SliverToBoxAdapter(child: SearchBarWidget()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile)
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const CategoryFilterWidget(),
                              const SizedBox(width: 16),
                              SortFilterWidget(
                                onSortChanged: (SortOption newSort) {
                                  ref.read(productFiltersProvider.notifier).updateSortBy(newSort);
                                },
                                onPriceRangeChanged: (double? min, double? max) {
                                  ref.read(productFiltersProvider.notifier).updatePriceRange(min, max);
                                },
                                onRatingChanged: (double? rating) {
                                  ref.read(productFiltersProvider.notifier).updateRating(
                                    rating == 0 ? null : rating,
                                  );
                                },
                                selectedSort: filters.sortBy,
                                selectedPriceRange: RangeValues(
                                  filters.minPrice ?? 0,
                                  filters.maxPrice ?? 10000,
                                ),
                                selectedRating: filters.minRating ?? 0,
                              ),
                              const SizedBox(width: 16),
                              if (filters.category != null ||
                                  filters.sortBy != SortOption.newest ||
                                  filters.minPrice != null ||
                                  filters.maxPrice != null ||
                                  filters.minRating != null)
                                TextButton.icon(
                                  onPressed: () {
                                    ref.read(productFiltersProvider.notifier).resetFilters();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reset Filters'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const CategoryFilterWidget(),
                              const SizedBox(width: 8),
                              SortFilterWidget(
                                onSortChanged: (SortOption newSort) {
                                  ref.read(productFiltersProvider.notifier).updateSortBy(newSort);
                                },
                                onPriceRangeChanged: (double? min, double? max) {
                                  ref.read(productFiltersProvider.notifier).updatePriceRange(min, max);
                                },
                                onRatingChanged: (double? rating) {
                                  ref.read(productFiltersProvider.notifier).updateRating(
                                    rating == 0 ? null : rating,
                                  );
                                },
                                selectedSort: filters.sortBy,
                                selectedPriceRange: RangeValues(
                                  filters.minPrice ?? 0,
                                  filters.maxPrice ?? 10000,
                                ),
                                selectedRating: filters.minRating ?? 0,
                              ),
                              const SizedBox(width: 8),
                              if (filters.category != null ||
                                  filters.sortBy != SortOption.newest ||
                                  filters.minPrice != null ||
                                  filters.maxPrice != null ||
                                  filters.minRating != null)
                                TextButton.icon(
                                  onPressed: () {
                                    ref.read(productFiltersProvider.notifier).resetFilters();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reset Filters'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const SliverToBoxAdapter(
                child: Center(
                  child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Try adjusting your filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 4,
                    childAspectRatio: 0.7,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(product: products[index]),
                    childCount: products.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
        Text(
                          'Error: $error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            ref.invalidate(filteredProductsProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
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
