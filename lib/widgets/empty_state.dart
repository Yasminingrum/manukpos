// lib/widgets/empty_state.dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double iconSize;
  final Color? iconColor;
  final Color? textColor;
  final Color? buttonColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.iconSize = 80.0,
    this.iconColor,
    this.textColor,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? theme.colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: textColor ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: textColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor ?? theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}