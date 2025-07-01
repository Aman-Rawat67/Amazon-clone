import 'package:flutter/material.dart';

class ProductOffersSection extends StatelessWidget {
  final double productPrice;

  const ProductOffersSection({
    super.key,
    required this.productPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate how many cards can fit in a row based on available width
          final cardWidth = 280.0;
          final spacing = 12.0;
          final cardsPerRow = (constraints.maxWidth / (cardWidth + spacing)).floor();
          
          return Wrap(
            spacing: spacing,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: [
              _OfferCard(
                title: 'Cashback',
                description: 'Upto ₹23.00 cashback as Amazon Pay Balance when you pay using UPI',
                offers: '1 offer >',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: Colors.blue[700]!,
                width: cardWidth,
              ),
              _OfferCard(
                title: 'Bank Offer',
                description: 'Upto ₹1,000.00 discount on select Credit Cards',
                offers: '7 offers >',
                icon: Icons.credit_card_outlined,
                iconColor: Colors.green[700]!,
                width: cardWidth,
              ),
              _OfferCard(
                title: 'Partner Offers',
                description: 'Get GST invoice and save up to 28% on business purchases',
                offers: '1 offer >',
                icon: Icons.local_offer_outlined,
                iconColor: Colors.orange[700]!,
                width: cardWidth,
              ),
              _OfferCard(
                title: 'EMI Options',
                description: 'No Cost EMI available on select cards',
                offers: 'View Plans >',
                icon: Icons.calendar_today_outlined,
                iconColor: Colors.purple[700]!,
                width: cardWidth,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final String title;
  final String description;
  final String offers;
  final IconData icon;
  final Color iconColor;
  final double width;

  const _OfferCard({
    required this.title,
    required this.description,
    required this.offers,
    required this.icon,
    required this.iconColor,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            offers,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 