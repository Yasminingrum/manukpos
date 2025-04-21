// widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

class CustomTextField extends StatelessWidget {
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
  }) : assert(
          controller == null || initialValue == null,
          'Cannot provide both a controller and an initialValue',
        );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      autofocus: autofocus,
      autovalidateMode: autovalidateMode,
      textCapitalization: textCapitalization,
      onTap: onTap,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: enabled ? AppTheme.textDark : AppTheme.textMedium,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIconConstraints,
        suffixIcon: suffixIcon,
        suffixIconConstraints: suffixIconConstraints,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        errorStyle: TextStyle(color: AppTheme.errorColor),
        labelStyle: TextStyle(
          color: enabled ? AppTheme.textMedium : AppTheme.textLight,
        ),
        hintStyle: TextStyle(
          color: AppTheme.textLight,
        ),
      ),
    );
  }
}