import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final IconData? icon;
  final Color? backgroundColor;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.text,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: backgroundColor != null 
            ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
            : null,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    const SizedBox(width: AppDimensions.paddingSmall),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontLarge,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 