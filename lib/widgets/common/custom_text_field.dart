import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final Color? backgroundColor;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines,
    this.validator,
    this.onSubmitted,
    this.style,
    this.hintStyle,
    this.labelStyle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxLines = obscureText ? 1 : (maxLines ?? 1);
    final isDark = backgroundColor != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: labelStyle ?? TextStyle(
            fontSize: AppDimensions.fontMedium,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Container(
          decoration: backgroundColor != null
              ? BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: effectiveMaxLines,
            validator: validator,
            onFieldSubmitted: onSubmitted != null ? (value) => onSubmitted!(value) : null,
            style: style ?? TextStyle(color: isDark ? Colors.white : Colors.black87),
            cursorColor: isDark ? Colors.white : Colors.black87,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: hintStyle ?? TextStyle(color: isDark ? Colors.white70 : Colors.grey),
              labelStyle: labelStyle ?? TextStyle(color: isDark ? Colors.white : Colors.black87),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: isDark ? Colors.white70 : Colors.black54) : null,
              prefix: prefix,
              suffixIcon: suffixIcon,
              filled: backgroundColor != null,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: BorderSide(color: isDark ? Colors.white : AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: BorderSide(color: isDark ? Colors.white54 : AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: BorderSide(color: isDark ? Colors.amber : AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 