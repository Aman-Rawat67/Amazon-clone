import 'package:flutter/material.dart';

/// Simple hover dropdown menu item model
class HoverDropdownItem {
  final Widget child;
  final VoidCallback? onTap;

  const HoverDropdownItem({
    required this.child,
    this.onTap,
  });
}

/// Enhanced hover dropdown menu widget with proper behavior and styling
class HoverDropdownMenu extends StatefulWidget {
  final Widget trigger;
  final List<HoverDropdownItem> menuItems;
  final double? menuWidth;
  final double? menuHeight;
  final EdgeInsets? menuPadding;
  final Offset? offset;

  const HoverDropdownMenu({
    super.key,
    required this.trigger,
    required this.menuItems,
    this.menuWidth,
    this.menuHeight,
    this.menuPadding,
    this.offset,
  });

  @override
  State<HoverDropdownMenu> createState() => _HoverDropdownMenuState();
}

class _HoverDropdownMenuState extends State<HoverDropdownMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;
  bool _isHoveringTrigger = false;
  bool _isHoveringDropdown = false;

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  void _openDropdown() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _DropdownOverlay(
        layerLink: _layerLink,
        menuItems: widget.menuItems,
        menuWidth: widget.menuWidth ?? 250,
        menuHeight: widget.menuHeight,
        menuPadding: widget.menuPadding,
        offset: widget.offset ?? const Offset(0, 8),
        onHoverEnter: () {
          _isHoveringDropdown = true;
        },
        onHoverExit: () {
          _isHoveringDropdown = false;
          _scheduleClose();
        },
        onItemTap: () {
          _closeDropdown();
        },
        onClickOutside: () {
          _closeDropdown();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isDropdownOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isDropdownOpen = false);
    }
  }

  void _scheduleClose() {
    // Add delay to prevent flickering when moving between trigger and dropdown
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_isHoveringTrigger && !_isHoveringDropdown && mounted) {
        _closeDropdown();
      }
    });
  }

  void _onTriggerHoverEnter() {
    _isHoveringTrigger = true;
    if (!_isDropdownOpen) {
      _openDropdown();
    }
  }

  void _onTriggerHoverExit() {
    _isHoveringTrigger = false;
    _scheduleClose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _onTriggerHoverEnter(),
        onExit: (_) => _onTriggerHoverExit(),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isDropdownOpen 
                ? Colors.grey.shade100 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: _isDropdownOpen 
                ? Border.all(color: Colors.grey.shade300, width: 1)
                : null,
          ),
          child: widget.trigger,
        ),
      ),
    );
  }
}

/// Dropdown overlay widget with proper positioning and click-outside handling
class _DropdownOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final List<HoverDropdownItem> menuItems;
  final double menuWidth;
  final double? menuHeight;
  final EdgeInsets? menuPadding;
  final Offset offset;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;
  final VoidCallback onItemTap;
  final VoidCallback onClickOutside;

  const _DropdownOverlay({
    required this.layerLink,
    required this.menuItems,
    required this.menuWidth,
    required this.offset,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onItemTap,
    required this.onClickOutside,
    this.menuHeight,
    this.menuPadding,
  });

  @override
  State<_DropdownOverlay> createState() => _DropdownOverlayState();
}

class _DropdownOverlayState extends State<_DropdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClickOutside,
      behavior: HitTestBehavior.translucent,
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Invisible barrier for click outside detection
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            // Dropdown content
            CompositedTransformFollower(
              link: widget.layerLink,
              showWhenUnlinked: false,
              offset: widget.offset,
              child: Material(
                color: Colors.transparent,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: MouseRegion(
                          onEnter: (_) => widget.onHoverEnter(),
                          onExit: (_) => widget.onHoverExit(),
                          child: Container(
                            width: widget.menuWidth,
                            constraints: BoxConstraints(
                              maxHeight: widget.menuHeight ?? 300,
                              minWidth: 180,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      padding: widget.menuPadding ?? 
                                          const EdgeInsets.symmetric(vertical: 4),
                                      itemCount: widget.menuItems.length,
                                      itemBuilder: (context, index) {
                                        return _DropdownMenuItem(
                                          item: widget.menuItems[index],
                                          onTap: widget.onItemTap,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced dropdown menu item with hover effects
class _DropdownMenuItem extends StatefulWidget {
  final HoverDropdownItem item;
  final VoidCallback onTap;

  const _DropdownMenuItem({
    required this.item,
    required this.onTap,
  });

  @override
  State<_DropdownMenuItem> createState() => _DropdownMenuItemState();
}

class _DropdownMenuItemState extends State<_DropdownMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          widget.item.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          decoration: BoxDecoration(
            color: _isHovered 
                ? Colors.grey.shade50 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: widget.item.child,
        ),
      ),
    );
  }
} 