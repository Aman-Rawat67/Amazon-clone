import 'package:flutter/material.dart';
import 'dart:async';

/// Enhanced hover dropdown menu widget with proper behavior and styling
class HoverDropdownMenu extends StatefulWidget {
  final Widget trigger;
  final double menuWidth;
  final List<Widget> items;
  final Offset offset;

  const HoverDropdownMenu({
    super.key,
    required this.trigger,
    required this.items,
    this.menuWidth = 200,
    this.offset = const Offset(0, 0),
  });

  @override
  State<HoverDropdownMenu> createState() => _HoverDropdownMenuState();
}

class _HoverDropdownMenuState extends State<HoverDropdownMenu> {
  bool _isHovered = false;
  bool _isMenuHovered = false;
  final _menuKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isNavigating = false;
  Timer? _closeTimer;

  @override
  void dispose() {
    _removeOverlay();
    _closeTimer?.cancel();
    super.dispose();
  }

  void _showOverlay(BuildContext context) {
    if (!mounted || _overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate available space below and to the right
    final spaceBelow = screenSize.height - (offset.dy + size.height + widget.offset.dy);
    final spaceRight = screenSize.width - (offset.dx + widget.menuWidth);
    
    // Adjust position based on available space
    final double verticalOffset = spaceBelow < 200 ? -200 : widget.offset.dy;
    final double horizontalOffset = spaceRight < 0 ? -widget.menuWidth + size.width : 0;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + size.height + verticalOffset,
        left: offset.dx + horizontalOffset + widget.offset.dx,
        child: MouseRegion(
          onEnter: (_) {
            _closeTimer?.cancel();
            if (mounted) setState(() => _isMenuHovered = true);
          },
          onExit: (_) {
            _startCloseTimer();
            if (mounted) setState(() => _isMenuHovered = false);
          },
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              key: _menuKey,
              width: widget.menuWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.items.isNotEmpty 
                  ? widget.items 
                  : [const HoverDropdownItem(text: 'No items')],
              ),
            ),
          ),
        ),
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _startCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (!_isHovered && !_isMenuHovered) {
        _removeOverlay();
      }
    });
  }

  void _handleHover(bool isHovered) {
    if (!mounted || _isNavigating) return;
    
    _closeTimer?.cancel();
    
    setState(() {
      _isHovered = isHovered;
      if (isHovered) {
        _showOverlay(context);
      } else {
        _startCloseTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: widget.trigger,
    );
  }
}

/// Hover dropdown item widget with consistent styling
class HoverDropdownItem extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isSelected;
  final IconData? icon;
  final bool isHeader;

  const HoverDropdownItem({
    super.key,
    required this.text,
    this.onTap,
    this.isSelected = false,
    this.icon,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isHeader ? null : () {
        if (onTap != null) {
          // Find the parent HoverDropdownMenu and close its overlay
          final ancestor = context.findAncestorStateOfType<_HoverDropdownMenuState>();
          if (ancestor != null) {
            ancestor._isNavigating = true;
            ancestor._removeOverlay();
          }
          
          // Execute the onTap callback after a short delay
          Future.microtask(() {
            onTap!();
            if (ancestor != null && ancestor.mounted) {
              ancestor._isNavigating = false;
            }
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: isHeader ? 14 : 13,
                  fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
                  color: isHeader ? Colors.grey.shade800 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Divider widget for hover dropdown menu
class HoverDropdownDivider extends StatelessWidget {
  const HoverDropdownDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
    );
  }
} 