import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../models/banner_model.dart';
import '../../constants/app_constants.dart';

/// Banner carousel widget for hero section
class BannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;

  const BannerCarousel({
    super.key,
    required this.banners,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: widget.banners.length,
            options: CarouselOptions(
              height: 300,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final banner = widget.banners[index];
              return _buildBannerItem(context, banner);
            },
          ),
          const SizedBox(height: 16),
          _buildIndicators(),
        ],
      ),
    );
  }

  Widget _buildBannerItem(BuildContext context, BannerModel banner) {
    return GestureDetector(
      onTap: () {
        if (banner.actionUrl != null) {
          // Handle external URL
          // You can use url_launcher package here
        }
      },
      child: Stack(
        children: [
          // Banner Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(banner.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          // Content
          Positioned(
            left: 24,
            bottom: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (banner.title?.isNotEmpty == true) ...[
                  Text(
                    banner.title!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  if (banner.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      banner.subtitle!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.banners.asMap().entries.map((entry) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == entry.key
                ? AppColors.primary
                : Colors.grey.shade300,
          ),
        );
      }).toList(),
    );
  }
} 