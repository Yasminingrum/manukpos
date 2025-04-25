// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';

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
  final bool transparent;
  final Widget? subtitle;
  final Widget? customTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.flexibleSpace,
    this.bottom,
    this.shape,
    this.onBackPressed,
    this.transparent = false,
    this.subtitle,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    
    // Default values
    final Color appBarBackgroundColor = transparent 
        ? Colors.transparent 
        : (backgroundColor ?? AppTheme.surfaceColor);
    
    final Color textColor = transparent
        ? AppTheme.primaryColor
        : (foregroundColor ?? AppTheme.textDark);

    // Modern app bar shape with bottom rounded corners
    final appBarShape = shape ?? const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(16),
      ),
    );

    return AppBar(
      title: customTitle ?? _buildTitle(context, textColor),
      leading: _buildLeading(context, textColor),
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: appBarBackgroundColor,
      elevation: transparent ? 0 : (elevation ?? 0),
      scrolledUnderElevation: transparent ? 0 : 2,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      shape: transparent ? null : appBarShape,
    );
  }

  Widget _buildTitle(BuildContext context, Color textColor) {
    if (subtitle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle!,
        ],
      );
    }
    
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget? _buildLeading(BuildContext context, Color iconColor) {
    if (leading != null) {
      return leading;
    }
    
    if (showBackButton) {
      return Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(26), // 0.1 as alpha
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: iconColor),
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          splashRadius: 24,
        ),
      );
    }
    
    return null;
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}

// A variant of app bar with a gradient background
class GradientAppBar extends CustomAppBar {
  @override
  final bool showBackButton;
  final List<Color> gradientColors;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;

  const GradientAppBar({
    super.key,
    required super.title,
    super.actions,
    super.leading,
    super.centerTitle = true,
    super.elevation,
    super.bottom,
    super.shape,
    super.onBackPressed,
    super.subtitle,
    super.customTitle,
    this.showBackButton = true,
    this.gradientColors = const [Color(0xFF5E72E4), Color(0xFF825EE4)],
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
  }) : super(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: super.customTitle ?? _buildTitle(context, Colors.white),
      leading: _buildLeading(context, Colors.white),
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: elevation ?? 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: gradientBegin,
            end: gradientEnd,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      bottom: bottom,
      shape: shape ?? const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget _buildTitle(BuildContext context, Color textColor) {
    if (subtitle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle!,
        ],
      );
    }
    
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}