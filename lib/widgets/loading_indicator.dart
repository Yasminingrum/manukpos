// widgets/loading_indicator.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;
  final String? message;
  final bool useShimmer;

  const LoadingIndicator({
    super.key,
    this.color,
    this.size = 50.0,
    this.strokeWidth = 3.0,
    this.message,
    this.useShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoader(),
          if (message != null) ...[
            const SizedBox(height: 16.0),
            _buildMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoader() {
    if (useShimmer) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (color ?? AppTheme.primaryColor).withAlpha(51), // 0.2 opacity as alpha
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: _buildPulseAnimation(),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow effect
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (color ?? AppTheme.primaryColor).withAlpha(51), // 0.2 opacity as alpha
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // Outer circular progress indicator
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppTheme.primaryColor,
            ),
            strokeWidth: strokeWidth,
          ),
          // Inner circular progress indicator (rotating in opposite direction)
          SizedBox(
            width: size * 0.65,
            height: size * 0.65,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color != null ? color!.withAlpha(179) : AppTheme.primaryColor.withAlpha(179), // 0.7 as alpha
              ),
              strokeWidth: strokeWidth * 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseAnimation() {
    return PulseAnimationLoader(
      color: color ?? AppTheme.primaryColor,
      size: size * 0.5,
    );
  }

  Widget _buildMessage() {
    if (useShimmer) {
      return ShimmerText(
        text: message!,
        style: TextStyle(
          color: color ?? AppTheme.primaryColor,
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      message!,
      style: TextStyle(
        color: color ?? AppTheme.primaryColor,
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// A pulsating animation for loading
class PulseAnimationLoader extends StatefulWidget {
  final Color color;
  final double size;

  const PulseAnimationLoader({
    super.key,
    required this.color,
    this.size = 30.0,
  });

  @override
  State<PulseAnimationLoader> createState() => _PulseAnimationLoaderState();
}

class _PulseAnimationLoaderState extends State<PulseAnimationLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size * _animation.value,
          height: widget.size * _animation.value,
          decoration: BoxDecoration(
            color: widget.color.withAlpha((128 * (1 - _animation.value + 0.5)).toInt()), // 0.5 opacity converted to alpha
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// A shimmering text animation
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const ShimmerText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.style.color!.withAlpha(128), // 0.5 as alpha
                widget.style.color!,
                widget.style.color!.withAlpha(128), // 0.5 as alpha
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(_animation.value * 2 * 3.14159),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

/// A full-screen loading indicator with modern blur effect and animation
class FullScreenLoader extends StatelessWidget {
  final Color? color;
  final Color backgroundColor;
  final double opacity;
  final String? message;
  final bool useBlur;
  final bool useShimmer;

  const FullScreenLoader({
    super.key,
    this.color,
    this.backgroundColor = Colors.black,
    this.opacity = 0.5,
    this.message,
    this.useBlur = true,
    this.useShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: useBlur ? backgroundColor.withAlpha((opacity * 0.5 * 255).toInt()) : backgroundColor.withAlpha((opacity * 255).toInt()),
      child: BackdropFilter(
        filter: useBlur
            ? ImageFilter.blur(sigmaX: 4, sigmaY: 4)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38), // 0.15 opacity as alpha
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26), // 0.1 opacity as alpha
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: LoadingIndicator(
              color: color ?? Colors.white,
              message: message,
              useShimmer: useShimmer,
            ),
          ),
        ),
      ),
    );
  }
}

/// A loading indicator that can be used inside buttons with modern animation
class ButtonLoadingIndicator extends StatelessWidget {
  final Color color;
  final double size;
  final bool useGradient;

  const ButtonLoadingIndicator({
    super.key,
    this.color = Colors.white,
    this.size = 24.0,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useGradient) {
      return SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

// Modern Animated Card Skeleton Loader
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFF5F5F5),
                Color(0xFFEEEEEE),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(_animation.value),
            ),
          ),
        );
      },
    );
  }
}