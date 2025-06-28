import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import '../../providers/home_data_provider.dart';

/// Search bar widget with autocomplete suggestions
class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _suggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      _removeOverlay();
      return;
    }

    ref.read(searchSuggestionsProvider(query).future).then((suggestions) {
      if (mounted && _controller.text == query) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
        
        if (suggestions.isNotEmpty && _focusNode.hasFocus) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getSearchBarWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.search,
                      size: 16,
                      color: Colors.grey,
                    ),
                    title: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      _controller.text = suggestion;
                      _search(suggestion);
                      _removeOverlay();
                    },
                    hoverColor: Colors.grey.shade100,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getSearchBarWidth() {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    
    _focusNode.unfocus();
    _removeOverlay();
    
    // Navigate to search results page
    context.go('/search?q=${Uri.encodeComponent(query)}');
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category dropdown
            _buildCategoryDropdown(),
            
            // Search input field
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  onSubmitted: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search Amazon Clone',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            
            // Search button
            _buildSearchButton(),
          ],
        ),
      ),
    );
  }

  /// Build category dropdown for search filter
  Widget _buildCategoryDropdown() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFE6E6E6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'All',
          items: ['All', ...AppConstants.productCategories]
              .map((category) => DropdownMenuItem(
                    value: category,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        category,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            // Handle category selection
          },
          icon: const Icon(
            Icons.arrow_drop_down,
            size: 16,
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// Build search button
  Widget _buildSearchButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _search(_controller.text),
        child: Container(
          width: 45,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: const Icon(
            Icons.search,
            color: Colors.black,
            size: 20,
          ),
        ),
      ),
    );
  }
} 