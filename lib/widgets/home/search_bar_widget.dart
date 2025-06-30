import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import '../../providers/home_data_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchCategoryProvider = StateProvider<String>((ref) => 'All');

/// Search bar widget with autocomplete suggestions
class SearchBarWidget extends ConsumerStatefulWidget {
  final String? initialQuery;
  final void Function(String query, {String? category})? onSearch;

  const SearchBarWidget({
    super.key,
    this.initialQuery,
    this.onSearch,
  });

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  late TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final searchQuery = _searchController.text.trim();
    final category = ref.read(searchCategoryProvider);
    
    if (searchQuery.isNotEmpty) {
      // Update the search query provider
      ref.read(searchQueryProvider.notifier).state = searchQuery;
      
      if (widget.onSearch != null) {
        // Use the callback if provided
        widget.onSearch!(searchQuery, category: category);
      } else {
        // Navigate to search results with category
        context.push('/search?q=${Uri.encodeComponent(searchQuery)}&category=${Uri.encodeComponent(category)}');
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(searchCategoryProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      height: 40,
      constraints: BoxConstraints(maxWidth: isSmallScreen ? double.infinity : 800),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Category dropdown
          if (!isSmallScreen) Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
              color: Colors.grey.shade50,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              value: selectedCategory,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: ['All', 'Electronics', 'Fashion', 'Books'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref.read(searchCategoryProvider.notifier).state = newValue;
                }
              },
            ),
          ),
          // Search input
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (value) {
                // Only update the provider if needed for suggestions
                if (value.length > 2) {
                  ref.read(searchQueryProvider.notifier).state = value;
                }
              },
              onSubmitted: (_) => _handleSearch(),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          // Search button
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF3A847),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.black87),
              onPressed: _handleSearch,
            ),
          ),
        ],
      ),
    );
  }
}