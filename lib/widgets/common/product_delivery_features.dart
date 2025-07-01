import 'package:flutter/material.dart';

class ProductDeliveryFeatures extends StatelessWidget {
  const ProductDeliveryFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FeatureButton(
            icon: Icons.replay_outlined,
            label: '10 Days',
            sublabel: 'Easy Returns',
            color: const Color(0xFFFF9900),
          ),
          const SizedBox(width: 8),
          _FeatureButton(
            icon: Icons.payments_outlined,
            label: 'COD',
            sublabel: 'Available',
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 8),
          _FeatureButton(
            icon: Icons.local_shipping_outlined,
            label: 'Express',
            sublabel: 'Delivery',
            color: const Color(0xFF1976D2),
          ),
          const SizedBox(width: 8),
          _FeatureButton(
            icon: Icons.verified_user_outlined,
            label: '100%',
            sublabel: 'Authentic',
            color: const Color(0xFF7B1FA2),
          ),
          const SizedBox(width: 8),
          _FeatureButton(
            icon: Icons.security_outlined,
            label: 'Secure',
            sublabel: 'Payment',
            color: const Color(0xFFD32F2F),
          ),
          const SizedBox(width: 8),
          _FeatureButton(
            icon: Icons.support_agent_outlined,
            label: '24/7',
            sublabel: 'Support',
            color: const Color(0xFF00796B),
          ),
          const SizedBox(width: 8),
          _FeatureButton(
            icon: Icons.price_check_outlined,
            label: 'Best',
            sublabel: 'Price',
            color: const Color(0xFF303F9F),
          ),
          const SizedBox(width: 8),
          _FeatureButton(
            icon: Icons.verified_outlined,
            label: 'Quality',
            sublabel: 'Assured',
            color: const Color(0xFF5E35B1),
          ),
        ],
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _FeatureButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 