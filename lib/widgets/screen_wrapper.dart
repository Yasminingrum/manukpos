// widgets/screen_wrapper.dart
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/navigation_helper.dart';

class ScreenWrapper extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final Color? backgroundColor;
  final Widget? leading;

  const ScreenWrapper({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showBackButton = true, // Default to true agar tombol back selalu muncul
    this.onBackPressed,
    this.centerTitle = true,
    this.backgroundColor,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (onBackPressed != null) {
          onBackPressed!();
          return false; // Prevent default back behavior
        }
        return true; // Allow default back behavior
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: title,
          showBackButton: showBackButton,
          centerTitle: centerTitle,
          backgroundColor: backgroundColor,
          actions: actions,
          leading: leading,
          onBackPressed: onBackPressed ?? () {
            NavigationHelper.goBack(context);
          },
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}