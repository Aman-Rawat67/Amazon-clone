import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/category_model.dart';
import '../../constants/app_constants.dart';

/// Category tile widget with hover effects
class CategoryTile extends ConsumerStatefulWidget {
  final CategoryModel category;
  final double? width;
  final double? height;

  const CategoryTile({
    super.key,
    required this.category,
    this.width,
    this.height,
  });

  @override
  ConsumerState<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends ConsumerState<CategoryTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.category.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height ?? 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Category image/icon section
              Expanded(
                flex: 3,
                child: _buildCategoryImage(),
              ),
              
              // Category details section
              Expanded(
                flex: 2,
                child: _buildCategoryDetails(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build category image/icon section
  Widget _buildCategoryImage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _getCategoryBackgroundColor(),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Stack(
        children: [
          // Background pattern (optional)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryBackgroundColor().withOpacity(0.8),
                    _getCategoryBackgroundColor(),
                  ],
                ),
              ),
            ),
          ),
          
          // Category icon/image
          Center(
            child: widget.category.imageUrl != null
                ? _buildCategoryImageWidget()
                : _buildCategoryIcon(),
          ),
          
          // Hover overlay
          AnimatedOpacity(
            opacity: _isHovered ? 0.1 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build category image widget
  Widget _buildCategoryImageWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.category.imageUrl!,
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          errorBuilder: (context, error, stackTrace) => _buildCategoryIcon(),
        ),
      ),
    );
  }

  /// Build category icon widget
  Widget _buildCategoryIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Image.network(
        widget.category.iconUrl,
        width: 60,
        height: 60,
        fit: BoxFit.contain,
        color: _getCategoryIconColor(),
        errorBuilder: (context, error, stackTrace) => Icon(
          _getDefaultIcon(),
          size: 60,
          color: _getCategoryIconColor(),
        ),
      ),
    );
  }

  /// Build category details section
  Widget _buildCategoryDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Category name
          Text(
            widget.category.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Category description
          if (widget.category.description != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.category.description!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Subcategories count
          if (widget.category.hasSubcategories) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.category.subcategories.length} items',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get category background color
  Color _getCategoryBackgroundColor() {
    if (widget.category.backgroundColor != null) {
      try {
        return Color(int.parse(widget.category.backgroundColor!.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fallback if color parsing fails
      }
    }
    
    // Default color based on category name
    final colors = [
      Colors.blue.shade50,
      Colors.green.shade50,
      Colors.orange.shade50,
      Colors.purple.shade50,
      Colors.red.shade50,
      Colors.teal.shade50,
      Colors.indigo.shade50,
      Colors.pink.shade50,
    ];
    
    final index = widget.category.name.hashCode % colors.length;
    return colors[index.abs()];
  }

  /// Get category icon color
  Color _getCategoryIconColor() {
    if (widget.category.color != null) {
      try {
        return Color(int.parse(widget.category.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fallback if color parsing fails
      }
    }
    
    // Default color based on category name
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.pink.shade600,
    ];
    
    final index = widget.category.name.hashCode % colors.length;
    return colors[index.abs()];
  }

  /// Get default icon for category
  IconData _getDefaultIcon() {
    final name = widget.category.name.toLowerCase();
    
    if (name.contains('electronics') || name.contains('mobile')) {
      return Icons.phone_android;
    } else if (name.contains('fashion') || name.contains('clothing')) {
      return Icons.shopping_bag;
    } else if (name.contains('home') || name.contains('kitchen')) {
      return Icons.home;
    } else if (name.contains('books')) {
      return Icons.book;
    } else if (name.contains('sports')) {
      return Icons.sports_soccer;
    } else if (name.contains('health') || name.contains('beauty')) {
      return Icons.favorite;
    } else if (name.contains('toys') || name.contains('games')) {
      return Icons.toys;
    } else if (name.contains('automotive') || name.contains('car')) {
      return Icons.directions_car;
    } else if (name.contains('grocery') || name.contains('food')) {
      return Icons.shopping_cart;
    } else if (name.contains('jewelry')) {
      return Icons.diamond;
    } else {
      return Icons.category;
    }
  }
} 