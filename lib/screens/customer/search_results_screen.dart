import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/home/product_card.dart';
import '../../widgets/home/search_bar_widget.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;
  final String category;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.category = 'All',
  });

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late String currentQuery;
  late String currentCategory;

  @override
  void initState() {
    super.initState();
    currentQuery = widget.query;
    currentCategory = widget.category;
  }

  void _performSearch(String query, {String? category}) {
    setState(() {
      currentQuery = query;
      currentCategory = category ?? currentCategory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth < 1200 && screenWidth >= 600;
    
    final searchResults = ref.watch(searchProductsProvider((
      query: currentQuery,
      category: currentCategory,
    )));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: SearchBarWidget(
          initialQuery: currentQuery,
          onSearch: _performSearch,
        ),
        automaticallyImplyLeading: true,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search info bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Wrap(
              spacing: 4,
              children: [
                Text(
                  'Search results for ',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '"$currentQuery"',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (currentCategory != 'All') ...[
                  Text(
                    ' in ',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    currentCategory,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFF3A847),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Search results
          Expanded(
            child: searchResults.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found for "$currentQuery"',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey,
                          ),
                        ),
                        if (currentCategory != 'All') ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _performSearch(currentQuery, category: 'All'),
                            child: const Text('Search in all categories'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isSmallScreen ? 2 : isMediumScreen ? 3 : 4,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => ProductCard(product: products[index]),
                          childCount: products.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF3A847)),
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                        'Error loading search results',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _performSearch(currentQuery),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3A847),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
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