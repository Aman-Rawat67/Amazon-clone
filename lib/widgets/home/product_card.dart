import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';

/// Product card widget with hover effects
class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final double? width;
  final double? height;
  final bool showAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.height,
    this.showAddToCart = true,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/product/${widget.product.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 8 : 4),
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image with fixed height
              SizedBox(
                height: 200,
                child: _buildProductImage(),
              ),
              
              // Product details in scrollable container
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product name
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Rating
                        _buildRating(),
                        
                        const SizedBox(height: 12),
                        
                        // Price
                        _buildPricing(),
                        
                        const SizedBox(height: 16),
                        
                        // Add to cart button
                        if (widget.showAddToCart)
                          _buildAddToCartButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build product image section
  Widget _buildProductImage() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main product image
            Hero(
              tag: 'product_${widget.product.id}',
              child: Image.network(
                widget.product.imageUrls.isNotEmpty
                    ? widget.product.imageUrls.first
                    : 'https://via.placeholder.com/300x300?text=No+Image',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.image_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            
            // Hover overlay
            if (_isHovered)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: 0.1,
                child: Container(color: Colors.black),
              ),
            
            // Discount badge
            if (widget.product.discountPercentage > 0)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '-${widget.product.discountPercentage.round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            
            // Stock status
            if (widget.product.stock == 0)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build rating section
  Widget _buildRating() {
    return Row(
      children: [
        // Star rating
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < widget.product.rating.floor()
                  ? Icons.star_rounded
                  : (index < widget.product.rating
                      ? Icons.star_half_rounded
                      : Icons.star_border_rounded),
              color: AppColors.rating,
              size: 18,
            );
          }),
        ),
        
        const SizedBox(width: 6),
        
        // Rating text
        Text(
          '(${widget.product.reviewCount})',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Build pricing section
  Widget _buildPricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current price
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${AppConstants.currencySymbol}${widget.product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
                letterSpacing: -0.5,
              ),
            ),
            
            // Original price (if discounted)
            if (widget.product.discountPercentage > 0) ...[
              const SizedBox(width: 8),
              Text(
                '${AppConstants.currencySymbol}${widget.product.originalPrice?.toStringAsFixed(0) ?? '0'}',
                style: TextStyle(
                  fontSize: 15,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),

        if (widget.product.stock > 0 && widget.product.stock <= 10) ...[
          const SizedBox(height: 8),
          Text(
            'Only ${widget.product.stock} left!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// Build add to cart button
  Widget _buildAddToCartButton() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isHovered ? 1.0 : 0.0,
      child: Container(
        width: double.infinity,
        height: 40,
        margin: const EdgeInsets.only(top: 12),
        child: ElevatedButton(
          onPressed: widget.product.stock > 0
              ? () {
                  // Add to cart logic
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            widget.product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
} 