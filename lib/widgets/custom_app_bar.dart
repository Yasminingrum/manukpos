// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final ShapeBorder? shape;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.flexibleSpace,
    this.bottom,
    this.shape,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? theme.appBarTheme.foregroundColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: _buildLeading(context),
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      elevation: elevation ?? theme.appBarTheme.elevation ?? 4,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      shape: shape,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    }
    
    if (showBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }
    
    return null;
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}