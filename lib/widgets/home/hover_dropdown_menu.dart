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

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + widget.offset.dx,
        top: offset.dy + size.height + widget.offset.dy,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: widget.menuWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.items ?? [],
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

  void _updateHoverState(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _showOverlay(context);
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_isHovered) {
          _removeOverlay();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      key: _menuKey,
      onEnter: (_) => _updateHoverState(true),
      onExit: (_) => _updateHoverState(false),
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
  final bool showDivider;

  const HoverDropdownItem({
    super.key,
    required this.text,
    this.onTap,
    this.isSelected = false,
    this.icon,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isSelected ? Colors.grey.shade100 : Colors.transparent,
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
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: Colors.grey.shade300),
      ],
    );
  }
} 