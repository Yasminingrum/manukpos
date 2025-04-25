// widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final String? initialValue;
  final bool autofocus;
  final AutovalidateMode? autovalidateMode;
  final TextCapitalization textCapitalization;
  final BoxConstraints? suffixIconConstraints;
  final BoxConstraints? prefixIconConstraints;
  final void Function()? onTap;
  final Color? fillColor;
  final Color? cursorColor;
  final BorderRadius? borderRadius;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.contentPadding,
    this.initialValue,
    this.autofocus = false,
    this.autovalidateMode,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIconConstraints,
    this.prefixIconConstraints,
    this.onTap,
    this.fillColor,
    this.cursorColor,
    this.borderRadius,
  }) : assert(
          controller == null || initialValue == null,
          'Cannot provide both a controller and an initialValue',
        );

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _borderAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _borderAnimation = Tween<double>(begin: 0, end: 1.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final defaultFillColor = widget.fillColor ?? 
                           (widget.enabled ? Colors.white : const Color(0xFFF8F9FE));
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          obscureText: widget.obscureText,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          autovalidateMode: widget.autovalidateMode,
          textCapitalization: widget.textCapitalization,
          onTap: widget.onTap,
          cursorColor: widget.cursorColor ?? AppTheme.primaryColor,
          cursorWidth: 1.5,
          cursorRadius: const Radius.circular(4),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: widget.enabled ? AppTheme.textDark : AppTheme.textMedium,
          ),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            contentPadding: widget.contentPadding ?? 
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            prefixIcon: widget.prefixIcon != null 
                      ? Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: widget.prefixIcon,
                        ) 
                      : null,
            prefixIconConstraints: widget.prefixIconConstraints,
            suffixIcon: widget.suffixIcon != null 
                      ? Padding(
                          padding: const EdgeInsets.only(right: 16, left: 8),
                          child: widget.suffixIcon,
                        ) 
                      : null,
            suffixIconConstraints: widget.suffixIconConstraints,
            filled: true,
            fillColor: defaultFillColor,
            
            // Floating label style with subtle animation
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            floatingLabelStyle: TextStyle(
              color: _isFocused ? AppTheme.primaryColor : AppTheme.textMedium,
              fontSize: 14,
              fontWeight: _isFocused ? FontWeight.w600 : FontWeight.normal,
            ),
            
            // Dynamic border styling based on state
            border: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide(
                color: AppTheme.primaryColor, 
                width: _borderAnimation.value,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide(color: AppTheme.errorColor, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide(color: AppTheme.errorColor, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide.none,
            ),
            
            // Text styles
            errorStyle: TextStyle(color: AppTheme.errorColor, fontSize: 12),
            labelStyle: TextStyle(
              color: _isFocused ? AppTheme.primaryColor : AppTheme.textMedium,
            ),
            hintStyle: TextStyle(
              color: AppTheme.textLight,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }
}