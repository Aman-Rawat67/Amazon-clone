import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/home_data_provider.dart';
import '../../providers/auth_provider.dart';
import 'hover_dropdown_menu.dart';
import 'search_bar_widget.dart';

/// Top navigation bar widget with clean light theme
class TopNavBar extends ConsumerWidget {
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).asData?.value;
    final cartCount = ref.watch(cartCountProvider).asData?.value ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1024 && screenWidth >= 768;
    final isMobile = screenWidth < 768;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      height: 60,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : isTablet ? 12 : 16,
          vertical: 8,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use LayoutBuilder to get available width and adjust layout accordingly
            return _buildResponsiveLayout(context, ref, user, cartCount, constraints.maxWidth);
          },
        ),
      ),
    );
  }

  /// Build responsive layout based on available width
  Widget _buildResponsiveLayout(BuildContext context, WidgetRef ref, user, int cartCount, double availableWidth) {
    final isVerySmall = availableWidth < 480;
    final isSmall = availableWidth < 768;
    final isMedium = availableWidth < 1024;
    
    if (isVerySmall) {
      // Very small screens: minimal layout
      return Row(
        children: [
          // Compact logo
          _buildCompactLogo(context),
          const SizedBox(width: 8),
          // Search bar takes remaining space
          const Expanded(child: SearchBarWidget()),
          const SizedBox(width: 8),
          // Compact account section
          _buildCompactAccountSection(context, ref, user),
          const SizedBox(width: 8),
          // Cart icon only
          _buildCompactCartSection(context, cartCount),
        ],
      );
    } else if (isSmall) {
      // Small screens: basic layout
      return Row(
        children: [
          _buildLogo(context),
          const SizedBox(width: 12),
          const Expanded(child: SearchBarWidget()),
          const SizedBox(width: 12),
          _buildAccountSection(context, ref, user),
          const SizedBox(width: 12),
          _buildCartSection(context, cartCount),
        ],
      );
    } else if (isMedium) {
      // Medium screens: add location
      return Row(
        children: [
          _buildLogo(context),
          const SizedBox(width: 16),
          _buildLocationSelector(context),
          const SizedBox(width: 16),
          const Expanded(child: SearchBarWidget()),
          const SizedBox(width: 16),
          _buildAccountSection(context, ref, user),
          const SizedBox(width: 16),
          _buildCartSection(context, cartCount),
        ],
      );
    } else {
      // Large screens: full layout
      return Row(
        children: [
          _buildLogo(context),
          const SizedBox(width: 20),
          _buildLocationSelector(context),
          const SizedBox(width: 20),
          const Expanded(child: SearchBarWidget()),
          const SizedBox(width: 20),
          _buildLanguageSelector(context),
          const SizedBox(width: 16),
          _buildAccountSection(context, ref, user),
          const SizedBox(width: 16),
          _buildCartSection(context, cartCount),
        ],
      );
    }
  }

  /// Build compact logo for very small screens
  Widget _buildCompactLogo(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/home'),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: const Text(
            'amazon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
        ),
      ),
    );
  }

  /// Build location selector with hover effect
  Widget _buildLocationSelector(BuildContext context) {
    return HoverDropdownMenu(
      trigger: _buildHoverableItem(
        context,
        icon: Icons.location_on_outlined,
        title: 'Deliver to',
        subtitle: 'India',
        iconSize: 16,
      ),
      menuItems: [
        HoverDropdownItem(
          child: const ListTile(
            leading: Icon(Icons.location_on, color: Color(0xFF111111)),
            title: Text('Change Location', style: TextStyle(color: Color(0xFF111111))),
            subtitle: Text('Select delivery address', style: TextStyle(color: Colors.grey)),
          ),
          onTap: () {
            // Handle location change
          },
        ),
      ],
    );
  }

  /// Build language selector with hover effect
  Widget _buildLanguageSelector(BuildContext context) {
    return HoverDropdownMenu(
      trigger: _buildHoverableItem(
        context,
        icon: Icons.language,
        title: 'EN',
        iconSize: 16,
      ),
      menuWidth: 180,
      offset: const Offset(-30, 8), // Position under the trigger
      menuItems: [
        HoverDropdownItem(
          child: _buildCompactMenuItem(
            icon: Icons.check,
            title: 'English',
            isSelected: true,
          ),
          onTap: () {},
        ),
        HoverDropdownItem(
          child: _buildCompactMenuItem(
            title: 'हिन्दी',
          ),
          onTap: () {},
        ),
        HoverDropdownItem(
          child: _buildCompactMenuItem(
            title: 'தமிழ்',
          ),
          onTap: () {},
        ),
      ],
    );
  }

  /// Build account section with hover dropdown
  Widget _buildAccountSection(BuildContext context, WidgetRef ref, user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1024;
    
    // Truncate user name for smaller screens
    String getDisplayName() {
      if (user == null) {
        return isCompact ? 'Sign in' : 'Hello, Sign in';
      }
      
      final firstName = user.name.split(' ').first;
      if (isCompact && firstName.length > 8) {
        return 'Hello, ${firstName.substring(0, 8)}...';
      }
      return isCompact ? 'Hello, $firstName' : 'Hello, $firstName';
    }
    
    String getSubtitle() {
      return isCompact ? 'Account ▼' : 'Account & Lists ▼';
    }

    return HoverDropdownMenu(
      trigger: _buildHoverableItem(
        context,
        title: getDisplayName(),
        subtitle: getSubtitle(),
      ),
      menuWidth: 280,
      offset: const Offset(-50, 8), // Position under the trigger
      menuItems: _buildAccountMenuItems(context, ref, user),
    );
  }

  /// Build compact menu item for language selector
  Widget _buildCompactMenuItem({
    IconData? icon,
    required String title,
    bool isSelected = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF111111) : Colors.transparent,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF111111),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build menu list tile with hover effect
  Widget _buildMenuListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: isDestructive 
            ? Colors.red.shade50 
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDestructive 
                    ? Colors.red.shade600 
                    : Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDestructive 
                      ? Colors.red.shade600 
                      : const Color(0xFF111111),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build divider for dropdown sections
  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.shade200,
    );
  }

  /// Handle logout functionality
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9900)),
          ),
        ),
      );

      // Sign out user using Firebase directly and provider
      await FirebaseAuth.instance.signOut();
      await ref.read(userProvider.notifier).signOut();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Navigate to login screen
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build cart section with badge
  Widget _buildCartSection(BuildContext context, int cartCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 900;
    final isCompact = screenWidth < 1024;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/cart'),
        child: _HoverEffect(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
              vertical: isCompact ? 6 : 8,
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: const Color(0xFF111111),
                      size: isCompact ? 24 : 28,
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF9900),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartCount > 99 ? '99+' : cartCount.toString(),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: isCompact ? 9 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                // Show cart text only on larger screens
                if (!isVeryCompact) ...[
                  SizedBox(width: isCompact ? 4 : 6),
                  Text(
                    'Cart',
                    style: TextStyle(
                      color: const Color(0xFF111111),
                      fontSize: isCompact ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build compact account section for small screens
  Widget _buildCompactAccountSection(BuildContext context, WidgetRef ref, user) {
    return HoverDropdownMenu(
      trigger: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: const Icon(
          Icons.account_circle_outlined,
          color: Color(0xFF111111),
          size: 24,
        ),
      ),
      menuWidth: 280,
      offset: const Offset(-240, 8),
      menuItems: _buildAccountMenuItems(context, ref, user),
    );
  }

  /// Build compact cart section for small screens
  Widget _buildCompactCartSection(BuildContext context, int cartCount) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/cart'),
        child: _HoverEffect(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Stack(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF111111),
                  size: 24,
                ),
                if (cartCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9900),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        cartCount.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build hoverable item widget
  Widget _buildHoverableItem(
    BuildContext context, {
    IconData? icon,
    required String title,
    String? subtitle,
    double iconSize = 20,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1024;

    return _HoverEffect(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 12,
          vertical: isCompact ? 6 : 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: const Color(0xFF111111),
                size: isCompact ? iconSize - 2 : iconSize,
              ),
              SizedBox(width: isCompact ? 4 : 6),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFF111111),
                      fontSize: isCompact ? 11 : 12,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFF111111),
                        fontSize: isCompact ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Amazon logo
  Widget _buildLogo(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/home'),
        child: _HoverEffect(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Amazon-style logo using text
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text(
                    'amazon',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Add the signature smile curve
                Container(
                  width: 20,
                  height: 4,
                  margin: const EdgeInsets.only(left: 4, top: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9900),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build account menu items (reusable for both regular and compact layouts)
  List<HoverDropdownItem> _buildAccountMenuItems(BuildContext context, WidgetRef ref, user) {
    return [
      if (user == null) ...[
        // Not signed in - Show sign in option
        HoverDropdownItem(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9900),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'New customer? ',
                      style: TextStyle(fontSize: 12, color: Color(0xFF111111)),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: const Text(
                        'Start here.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          onTap: () {},
        ),
        // Divider
        HoverDropdownItem(
          child: _buildDivider(),
          onTap: () {},
        ),
      ] else ...[
        // Signed in - Show user menu
        HoverDropdownItem(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          onTap: () {},
        ),
        // Divider
        HoverDropdownItem(
          child: _buildDivider(),
          onTap: () {},
        ),
      ],
      
      // Common menu items
      HoverDropdownItem(
        child: _buildMenuListTile(
          icon: Icons.receipt_long,
          title: 'Your Orders',
          onTap: () => context.go('/orders'),
        ),
        onTap: () => context.go('/orders'),
      ),
      HoverDropdownItem(
        child: _buildMenuListTile(
          icon: Icons.settings,
          title: 'Account Settings',
          onTap: () => context.go('/profile'),
        ),
        onTap: () => context.go('/profile'),
      ),
      
      // Show logout only if user is signed in
      if (user != null) ...[
        // Divider
        HoverDropdownItem(
          child: _buildDivider(),
          onTap: () {},
        ),
        HoverDropdownItem(
          child: _buildMenuListTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => _handleLogout(context, ref),
            isDestructive: true,
          ),
          onTap: () => _handleLogout(context, ref),
        ),
      ],
    ];
  }
}

/// Hover effect wrapper widget for light theme
class _HoverEffect extends StatefulWidget {
  final Widget child;

  const _HoverEffect({required this.child});

  @override
  State<_HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<_HoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.grey.shade100 : Colors.transparent,
          border: _isHovered 
              ? Border.all(color: Colors.grey.shade300, width: 1)
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: widget.child,
      ),
    );
  }
} 