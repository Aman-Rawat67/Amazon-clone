import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';

class SearchBarWidget extends StatefulWidget {
  final bool isSmallScreen;
  final String? initialQuery;
  final void Function(String query, {String? category})? onSearch;

  const SearchBarWidget({
    super.key,
    this.isSmallScreen = false,
    this.initialQuery,
    this.onSearch,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _searchController;
  final _focusNode = FocusNode();
  bool _isFocused = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      if (widget.onSearch != null) {
        widget.onSearch!(query, category: _selectedCategory);
      } else {
        context.push('/search?q=${Uri.encodeComponent(query)}&category=${Uri.encodeComponent(_selectedCategory)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _isFocused ? const Color(0xFFFF9900) : Colors.white,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Category dropdown
          if (!widget.isSmallScreen) ...[
            Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: _isFocused ? const Color(0xFFFF9900) : const Color(0xFFCCCCCC),
                    width: 1,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
                color: const Color(0xFFF3F3F3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  icon: const Icon(Icons.arrow_drop_down),
                  style: const TextStyle(
                    color: Color(0xFF565959),
                    fontSize: 14,
                  ),
                  items: ['All', ...AppConstants.categories].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ],

          // Search input
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search Amazon.in',
                hintStyle: const TextStyle(
                  color: Color(0xFF565959),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.isSmallScreen ? 8 : 16,
                  vertical: 8,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),

          // Search button
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFF9900),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(7),
                bottomRight: Radius.circular(7),
              ),
            ),
            width: 45,
            height: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onSearch,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
                child: const Icon(Icons.search, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}