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

class CustomButton extends StatefulWidget {
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
    this.height = 48,
    this.borderRadius = 30.0, // Rounded corners for modern look
    this.padding,
    this.textStyle,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  // We need to use this variable to handle the button press state visually
  // Variable ini digunakan untuk mengontrol animasi saat tombol ditekan
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Get colors and gradients based on variant
  Map<String, dynamic> _getButtonStyles() {
    // Base colors
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    List<Color> gradientColors;
    double elevation;

    switch (widget.variant) {
      case ButtonVariant.primary:
        backgroundColor = AppTheme.primaryColor;
        textColor = Colors.white;
        borderColor = Colors.transparent;
        gradientColors = [AppTheme.primaryColor, Color(0xFF8e9aef)];
        elevation = 2;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppTheme.secondaryColor;
        textColor = Colors.white;
        borderColor = Colors.transparent;
        gradientColors = [AppTheme.secondaryColor, Color(0xFF72e7fb)];
        elevation = 2;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.primaryColor;
        borderColor = AppTheme.primaryColor;
        gradientColors = [Colors.transparent, Colors.transparent];
        elevation = 0;
        break;
      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.primaryColor;
        borderColor = Colors.transparent;
        gradientColors = [Colors.transparent, Colors.transparent];
        elevation = 0;
        break;
      case ButtonVariant.danger:
        backgroundColor = AppTheme.errorColor;
        textColor = Colors.white;
        borderColor = Colors.transparent;
        gradientColors = [AppTheme.errorColor, Color(0xFFff7885)];
        elevation = 2;
        break;
      case ButtonVariant.success:
        backgroundColor = AppTheme.successColor;
        textColor = Colors.white;
        borderColor = Colors.transparent;
        gradientColors = [AppTheme.successColor, Color(0xFF5fe0a8)];
        elevation = 2;
        break;
    }

    // Disabled colors
    Color disabledBackgroundColor = const Color(0xFFEEEEEE);
    Color disabledTextColor = AppTheme.textMedium;
    Color disabledBorderColor = const Color(0xFFE0E0E0);
    List<Color> disabledGradientColors = [disabledBackgroundColor, disabledBackgroundColor];

    return {
      'backgroundColor': widget.onPressed == null ? disabledBackgroundColor : backgroundColor,
      'textColor': widget.onPressed == null ? disabledTextColor : textColor,
      'borderColor': widget.onPressed == null ? disabledBorderColor : borderColor,
      'gradientColors': widget.onPressed == null ? disabledGradientColors : gradientColors,
      'elevation': elevation,
    };
  }

  @override
  Widget build(BuildContext context) {
    final styles = _getButtonStyles();
    final bool useGradient = widget.variant != ButtonVariant.outline && 
                            widget.variant != ButtonVariant.ghost;

    // Build inner button content
    Widget buttonContent = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(styles['textColor']),
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            widget.text,
            style: widget.textStyle?.copyWith(color: styles['textColor']) ?? 
                   TextStyle(
                     color: styles['textColor'],
                     fontSize: 16,
                     fontWeight: FontWeight.w600,
                     letterSpacing: 0.5,
                   ),
          ),
        ],
      ],
    );

    // Create the button
    Widget button = GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null && !widget.isLoading) {
          setState(() => _isPressed = true);
          _controller.forward();
        }
      },
      onTapUp: (_) {
        if (widget.onPressed != null && !widget.isLoading) {
          setState(() => _isPressed = false);
          _controller.reverse();
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null && !widget.isLoading) {
          setState(() => _isPressed = false);
          _controller.reverse();
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: styles['borderColor'],
              width: widget.variant == ButtonVariant.outline ? 2 : 0,
            ),
            gradient: useGradient ? LinearGradient(
              colors: styles['gradientColors'],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            color: !useGradient ? styles['backgroundColor'] : null,
            // Gunakan _isPressed untuk mengubah shadow saat tombol ditekan
            boxShadow: (styles['elevation'] > 0 && widget.onPressed != null) 
                ? [
                    BoxShadow(
                      color: styles['backgroundColor'].withAlpha(_isPressed ? 120 : 77), // Ubah opacity saat ditekan
                      blurRadius: _isPressed ? 4 : 8, // Ubah blur saat ditekan
                      offset: Offset(0, _isPressed ? 1 : 3), // Ubah offset saat ditekan
                      spreadRadius: _isPressed ? -1 : -2, // Ubah spread saat ditekan
                    )
                  ] 
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              onTap: (widget.isLoading || widget.onPressed == null) ? null : widget.onPressed,
              splashColor: Colors.transparent, // Disable default splash
              highlightColor: Colors.transparent, // Disable default highlight
              child: Padding(
                padding: widget.padding ?? 
                         EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: buttonContent,
              ),
            ),
          ),
        ),
      ),
    );

    // Apply width constraints if necessary
    if (widget.fullWidth || widget.width != null) {
      return SizedBox(
        width: widget.fullWidth ? double.infinity : widget.width,
        child: button,
      );
    }

    return button;
  }
}