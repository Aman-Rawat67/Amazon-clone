import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_section_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/home_data_provider.dart';
import '../../models/product_section_model.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../constants/filter_constants.dart';
import '../../widgets/home/top_nav_bar.dart';
import '../../widgets/home/category_nav_bar.dart';
import '../../widgets/home/product_section_widget.dart';
import '../../widgets/home/banner_carousel.dart';

/// Dynamic Amazon-style homepage that fetches sections from Firebase
class DynamicHomeScreen extends ConsumerWidget {
  const DynamicHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final banners = ref.watch(bannersProvider);
    final filters = ref.watch(productFiltersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: CustomScrollView(
        slivers: [
          // Main navigation with logo, search, account, cart
          const SliverToBoxAdapter(child: TopNavBar()),

          // Unified category navigation
          const SliverToBoxAdapter(child: CategoryNavBar()),

          // Hero banner section
          SliverToBoxAdapter(
            child: banners.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Error loading banners: $error')),
              data: (bannerList) => BannerCarousel(banners: bannerList),
            ),
          ),

          // All Offers Banner
          SliverToBoxAdapter(
            child: _buildAllOffersBanner(context),
          ),

          // // Delivery features bar
          // const SliverToBoxAdapter(
          //   child: Padding(
          //     padding: EdgeInsets.only(top: 16),
          //     child: DeliveryFeaturesBar(),
          //   ),
          // ),

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
      bottomNavigationBar: isMobile
          ? _buildBottomNavigationBar(context, ref)
          : null,
    );
  }

  /// Build bottom navigation bar for mobile
  BottomNavigationBar _buildBottomNavigationBar(
    BuildContext context,
    WidgetRef ref,
  ) {
    final filters = ref.watch(productFiltersProvider);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.filter_alt,
                color: filters.hasActiveFilters ? Colors.blue : null,
              ),
              if (filters.hasActiveFilters)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
          label: filters.hasActiveFilters ? 'Filters On' : 'Sort & Filter',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt),
          label: 'Orders',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
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

  /// Build all offers banner
  Widget _buildAllOffersBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/offers'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_offer,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Offers & Deals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Flash deals, bank offers, cashback & more',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget that dynamically loads and displays product sections from Firestore
class _DynamicProductSections extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DynamicProductSections> createState() =>
      _DynamicProductSectionsState();
}

class _DynamicProductSectionsState
    extends ConsumerState<_DynamicProductSections> {
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(productSectionsStreamProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return const Center(child: Text('No products found'));
  }

  @override
  Widget build(BuildContext context) {
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
            if (filters.hasActiveFilters) {
              if (filteredProducts.isEmpty) {
                return _buildNoResultsState();
              }

              return _buildFilteredProducts(filteredProducts, filters);
            }

            return _buildProductSections(sections);
          },
        );
      },
    );
  }

  Widget _buildFilteredProducts(
    List<ProductModel> products,
    ProductFilters filters,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getFilterTitle(filters),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${products.length} products found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 24),
          ProductSectionWidget(
            section: ProductSection(
              id: 'filtered',
              title: '',
              products: products,
              isActive: true,
              order: 0,
              displayCount: products.length,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProductSections(List<ProductSection> sections) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        if (section.products.isEmpty) return const SizedBox.shrink();
        return ProductSectionWidget(section: section);
      },
    );
  }

  String _getFilterTitle(ProductFilters filters) {
    final List<String> filterParts = [];

    if (filters.category != null) {
      filterParts.add(filters.category!.toUpperCase());
      if (filters.subcategory != null) {
        filterParts.add(filters.subcategory!.toUpperCase());
      }
    }

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

    if (filters.minPrice != null || filters.maxPrice != null) {
      if (filters.maxPrice == 500) {
        filterParts.add('Under ₹500');
      } else if (filters.minPrice == 500 && filters.maxPrice == 2000) {
        filterParts.add('₹500 - ₹2000');
      } else if (filters.minPrice == 2000) {
        filterParts.add('Above ₹2000');
      } else {
        filterParts.add(
          '₹${filters.minPrice?.round() ?? 0} - ₹${filters.maxPrice?.round() ?? 10000}',
        );
      }
    }

    if (filters.minRating != null) {
      filterParts.add('${filters.minRating}★ & above');
    }

    return filterParts.join(' • ');
  }
}

/// Mobile-friendly sort and filter modal for bottom sheet
class _MobileSortFilterModal extends ConsumerStatefulWidget {
  const _MobileSortFilterModal();

  @override
  ConsumerState<_MobileSortFilterModal> createState() =>
      _MobileSortFilterModalState();
}

class _MobileSortFilterModalState
    extends ConsumerState<_MobileSortFilterModal> {
  late SortOption selectedSort;
  late RangeValues priceRange;
  late double minRating;
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(productFiltersProvider);
    selectedSort = filters.sortBy;
    priceRange = RangeValues(filters.minPrice ?? 0, filters.maxPrice ?? 10000);
    minRating = filters.minRating ?? 0;
  }

  void _updateChangesFlag() {
    final filters = ref.read(productFiltersProvider);
    setState(() {
      hasChanges =
          selectedSort != filters.sortBy ||
          priceRange.start != (filters.minPrice ?? 0) ||
          priceRange.end != (filters.maxPrice ?? 10000) ||
          minRating != (filters.minRating ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentFilters = ref.watch(productFiltersProvider);

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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: currentFilters.hasActiveFilters
                      ? () {
                          // Reset filters
                          setState(() {
                            selectedSort = SortOption.newest;
                            priceRange = const RangeValues(0, 10000);
                            minRating = 0;
                            hasChanges = true;
                          });
                        }
                      : null,
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: currentFilters.hasActiveFilters
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active filters summary
          if (currentFilters.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getFilterTitle(currentFilters),
                      style: const TextStyle(color: Colors.blue, fontSize: 14),
                    ),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ...SortOption.values.map(
                    (option) => RadioListTile<SortOption>(
                      title: Text(_getSortOptionText(option)),
                      value: option,
                      groupValue: selectedSort,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setState(() {
                          selectedSort = value!;
                          _updateChangesFlag();
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Price range
                  const Text(
                    'Price Range',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${priceRange.start.round()} - ₹${priceRange.end.round()}',
                    style: TextStyle(
                      color: priceRange.start > 0 || priceRange.end < 10000
                          ? Colors.blue
                          : null,
                      fontWeight: priceRange.start > 0 || priceRange.end < 10000
                          ? FontWeight.w600
                          : null,
                    ),
                  ),
                  RangeSlider(
                    values: priceRange,
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    activeColor: Colors.blue,
                    labels: RangeLabels(
                      '₹${priceRange.start.round()}',
                      '₹${priceRange.end.round()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        priceRange = values;
                        _updateChangesFlag();
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Rating filter
                  const Text(
                    'Minimum Rating',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(5, (index) {
                    final rating = index + 1.0;
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          ...List.generate(
                            rating.toInt(),
                            (_) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          ...List.generate(
                            5 - rating.toInt(),
                            (_) => const Icon(
                              Icons.star_border,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ),
                          Text(
                            ' & above',
                            style: TextStyle(
                              color: minRating == rating ? Colors.blue : null,
                              fontWeight: minRating == rating
                                  ? FontWeight.w600
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      value: minRating >= rating,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setState(() {
                          minRating = value! ? rating : rating - 1;
                          _updateChangesFlag();
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
                onPressed: hasChanges
                    ? () {
                        // Apply filters
                        ref
                            .read(productFiltersProvider.notifier)
                            .updateSortBy(selectedSort);
                        ref
                            .read(productFiltersProvider.notifier)
                            .updatePriceRange(
                              priceRange.start == 0 ? null : priceRange.start,
                              priceRange.end == 10000 ? null : priceRange.end,
                            );
                        ref
                            .read(productFiltersProvider.notifier)
                            .updateRating(minRating == 0 ? null : minRating);
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasChanges
                      ? const Color(0xFFFF9900)
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  hasChanges ? 'Apply Changes' : 'No Changes',
                  style: const TextStyle(
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

  String _getFilterTitle(ProductFilters filters) {
    final List<String> filterParts = [];

    if (filters.category != null) {
      filterParts.add(filters.category!.toUpperCase());
      if (filters.subcategory != null) {
        filterParts.add(filters.subcategory!.toUpperCase());
      }
    }

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

    if (filters.minPrice != null || filters.maxPrice != null) {
      if (filters.maxPrice == 500) {
        filterParts.add('Under ₹500');
      } else if (filters.minPrice == 500 && filters.maxPrice == 2000) {
        filterParts.add('₹500 - ₹2000');
      } else if (filters.minPrice == 2000) {
        filterParts.add('Above ₹2000');
      } else {
        filterParts.add(
          '₹${filters.minPrice?.round() ?? 0} - ₹${filters.maxPrice?.round() ?? 10000}',
        );
      }
    }

    if (filters.minRating != null) {
      filterParts.add('${filters.minRating}★ & above');
    }

    return filterParts.join(' • ');
  }
}
