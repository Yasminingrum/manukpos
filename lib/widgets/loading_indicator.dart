import 'package:flutter/material.dart';
import '../../config/theme.dart';

class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;
  final String? message;

  const LoadingIndicator({
    super.key,
    this.color,
    this.size = 50.0,
    this.strokeWidth = 4.0,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppTheme.primaryColor,
            ),
            strokeWidth: strokeWidth,
          ),
          if (message != null) ...[
            const SizedBox(height: 16.0),
            Text(
              message!,
              style: TextStyle(
                color: color ?? AppTheme.primaryColor,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A full-screen loading indicator with optional background overlay
class FullScreenLoader extends StatelessWidget {
  final Color? color;
  final Color backgroundColor;
  final double opacity;
  final String? message;

  const FullScreenLoader({
    super.key,
    this.color,
    this.backgroundColor = Colors.black,
    this.opacity = 0.5,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor.withOpacity(opacity),
      child: LoadingIndicator(
        color: color ?? Colors.white,
        message: message,
      ),
    );
  }
}

/// A loading indicator that can be used inside buttons
class ButtonLoadingIndicator extends StatelessWidget {
  final Color color;
  final double size;

  const ButtonLoadingIndicator({
    super.key,
    this.color = Colors.white,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 2.5,
      ),
    );
  }
}