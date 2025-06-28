import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/banner_model.dart';
import '../../constants/app_constants.dart';

/// Banner carousel widget for hero section
class BannerCarousel extends ConsumerStatefulWidget {
  final List<BannerModel> banners;
  final double height;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.height = 400,
  });

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Auto-scroll banners
    if (widget.banners.isNotEmpty) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && widget.banners.isNotEmpty) {
        final nextIndex = (_currentIndex + 1) % widget.banners.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  void _onBannerTap(BannerModel banner) {
    if (banner.actionRoute != null) {
      context.go(banner.actionRoute!);
    } else if (banner.actionUrl != null) {
      // Handle external URL
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return _buildFallbackBanner();
    }

    return Container(
      height: widget.height,
      child: Stack(
        children: [
          // Banner PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return _buildBannerItem(banner);
            },
          ),
          
          // Navigation arrows (desktop only)
          if (MediaQuery.of(context).size.width > 768) ...[
            _buildNavigationArrow(
              alignment: Alignment.centerLeft,
              icon: Icons.chevron_left,
              onTap: () => _previousBanner(),
            ),
            _buildNavigationArrow(
              alignment: Alignment.centerRight,
              icon: Icons.chevron_right,
              onTap: () => _nextBanner(),
            ),
          ],
          
          // Page indicators
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildPageIndicators(),
          ),
        ],
      ),
    );
  }

  /// Build individual banner item
  Widget _buildBannerItem(BannerModel banner) {
    return MouseRegion(
      cursor: banner.actionRoute != null || banner.actionUrl != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: () => _onBannerTap(banner),
        child: Container(
          width: double.infinity,
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Banner image
              Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.image,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade300,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              
              // Banner content
              if (banner.title.isNotEmpty || banner.subtitle != null)
                Positioned(
                  bottom: 60,
                  left: 40,
                  right: 40,
                  child: _buildBannerContent(banner),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build banner content overlay
  Widget _buildBannerContent(BannerModel banner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          banner.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black54,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        if (banner.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            banner.subtitle!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black54,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
        if (banner.actionText != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _onBannerTap(banner),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(banner.actionText!),
          ),
        ],
      ],
    );
  }

  /// Build navigation arrow
  Widget _buildNavigationArrow({
    required Alignment alignment,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build page indicators
  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.banners.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? AppColors.secondary
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  /// Build fallback banner when no banners available
  Widget _buildFallbackBanner() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Welcome to Amazon Clone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Discover amazing deals and products',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previousBanner() {
    if (widget.banners.isEmpty) return;
    final previousIndex = _currentIndex == 0
        ? widget.banners.length - 1
        : _currentIndex - 1;
    _pageController.animateToPage(
      previousIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextBanner() {
    if (widget.banners.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % widget.banners.length;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
} 