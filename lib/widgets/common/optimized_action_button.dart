import 'package:flutter/material.dart';

/// Styles for the OptimizedActionButton
enum OptimizedButtonStyle {
  filled,
  outlined,
}

/// A modern, optimized action button with loading state support
class OptimizedActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final OptimizedButtonStyle style;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const OptimizedActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = OptimizedButtonStyle.filled,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = 48,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Default colors based on style
    final defaultBgColor = style == OptimizedButtonStyle.filled
        ? theme.primaryColor
        : Colors.transparent;
    final defaultTextColor = style == OptimizedButtonStyle.filled
        ? Colors.white
        : theme.primaryColor;

    // Final colors considering custom colors
    final finalBgColor = backgroundColor ?? defaultBgColor;
    final finalTextColor = textColor ?? defaultTextColor;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isEnabled && !isLoading) ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: isEnabled ? finalBgColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              border: style == OptimizedButtonStyle.outlined
                  ? Border.all(
                      color: isEnabled ? finalTextColor : Colors.grey[400]!,
                      width: 1.5,
                    )
                  : null,
              boxShadow: style == OptimizedButtonStyle.filled && isEnabled
                  ? [
                      BoxShadow(
                        color: finalBgColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          style == OptimizedButtonStyle.filled
                              ? Colors.white
                              : finalTextColor,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: isEnabled ? finalTextColor : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          style: TextStyle(
                            color: isEnabled ? finalTextColor : Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
} 