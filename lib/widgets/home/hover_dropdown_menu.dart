import 'package:flutter/material.dart';

/// Enhanced hover dropdown menu widget with proper behavior and styling
class HoverDropdownMenu extends StatefulWidget {
  final Widget trigger;
  final double menuWidth;
  final List<Widget>? items;
  final Offset offset;

  const HoverDropdownMenu({
    super.key,
    required this.trigger,
    this.menuWidth = 200,
    this.items,
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

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showOverlay(BuildContext context) {
    _removeOverlay();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate available space below and to the right
    final spaceBelow = screenSize.height - (offset.dy + size.height + widget.offset.dy);
    final spaceRight = screenSize.width - (offset.dx + widget.offset.dx + widget.menuWidth);
    
    // Adjust horizontal position if menu would go off-screen
    final leftOffset = spaceRight < 0
        ? offset.dx + widget.offset.dx - (widget.menuWidth + spaceRight)
        : offset.dx + widget.offset.dx;
    
    // Decide whether to show menu above or below
    final showAbove = spaceBelow < 400 && offset.dy > spaceBelow;
    
    // Calculate final vertical position
    final topOffset = showAbove 
        ? offset.dy - 400 // Show above
        : offset.dy + size.height + widget.offset.dy; // Show below

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: leftOffset,
        top: topOffset,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isMenuHovered = true),
          onExit: (_) => _handleMenuExit(),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: widget.menuWidth,
              constraints: BoxConstraints(
                maxHeight: 400, // Maximum height for the menu
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items ?? [],
                ),
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

  void _handleMenuExit() {
    setState(() => _isMenuHovered = false);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (!_isHovered && !_isMenuHovered) {
        _removeOverlay();
      }
    });
  }

  void _handleTriggerExit() {
    setState(() => _isHovered = false);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (!_isHovered && !_isMenuHovered) {
        _removeOverlay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      key: _menuKey,
      onEnter: (_) => setState(() {
        _isHovered = true;
        _showOverlay(context);
      }),
      onExit: (_) => _handleTriggerExit(),
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
      onTap: isHeader ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? Colors.grey.shade100 : Colors.transparent,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isHeader 
                    ? Colors.black87
                    : isSelected 
                        ? Colors.amber
                        : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isHeader 
                      ? Colors.black87
                      : isSelected 
                          ? Colors.amber
                          : Colors.grey.shade800,
                  fontWeight: isHeader || isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
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