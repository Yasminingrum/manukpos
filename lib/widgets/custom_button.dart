// widgets/custom_button.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
  success,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.width,
    this.height = 50,
    this.borderRadius = 8.0,
    this.padding,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Determine button colors based on variant
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    Color disabledBackgroundColor = const Color(0xFFE0E0E0);
    Color disabledTextColor = AppTheme.textMedium;
    Color disabledBorderColor = const Color(0xFFE0E0E0);

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = AppTheme.primaryColor;
        textColor = Colors.white;
        borderColor = AppTheme.primaryColor;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppTheme.secondaryColor;
        textColor = Colors.white;
        borderColor = AppTheme.secondaryColor;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.primaryColor;
        borderColor = AppTheme.primaryColor;
        break;
      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.primaryColor;
        borderColor = Colors.transparent;
        break;
      case ButtonVariant.danger:
        backgroundColor = AppTheme.errorColor;
        textColor = Colors.white;
        borderColor = AppTheme.errorColor;
        break;
      case ButtonVariant.success:
        backgroundColor = AppTheme.successColor;
        textColor = Colors.white;
        borderColor = AppTheme.successColor;
        break;
    }

    // Create button based on state and variant
    final button = ElevatedButton(
      onPressed: (isLoading || onPressed == null) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        disabledBackgroundColor: disabledBackgroundColor,
        disabledForegroundColor: disabledTextColor,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            color: onPressed == null ? disabledBorderColor : borderColor,
            width: variant == ButtonVariant.outline ? 2 : 0,
          ),
        ),
        elevation: variant == ButtonVariant.ghost || variant == ButtonVariant.outline ? 0 : 2,
        shadowColor: variant == ButtonVariant.ghost || variant == ButtonVariant.outline 
            ? Colors.transparent 
            : null,
        textStyle: textStyle ?? const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: Size(0, height),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(text),
          ],
        ],
      ),
    );

    // Apply width constraints if necessary
    if (fullWidth || width != null) {
      return SizedBox(
        width: fullWidth ? double.infinity : width,
        height: height,
        child: button,
      );
    }

    return button;
  }
}