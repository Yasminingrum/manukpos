// widgets/confirmation_dialog.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final Widget? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Ya',
    this.cancelText = 'Batal',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            if (onCancel != null) {
              onCancel!();
            } else {
              Navigator.of(context).pop(false);
            }
          },
          child: Text(
            cancelText,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () {
            if (onConfirm != null) {
              onConfirm!();
            } else {
              Navigator.of(context).pop(true);
            }
          },
          child: Text(
            confirmText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to show the dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    Widget? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm != null
            ? () {
                Navigator.of(context).pop(true);
                onConfirm();
              }
            : null,
        onCancel: onCancel != null
            ? () {
                Navigator.of(context).pop(false);
                onCancel();
              }
            : null,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }

  // Commonly used confirm dialogs
  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Hapus',
    String cancelText = 'Batal',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      isDestructive: true,
      icon: const Icon(
        Icons.delete_outline,
        color: AppTheme.errorColor,
      ),
    );
  }

  static Future<bool?> showSaveConfirmation({
    required BuildContext context,
    String title = 'Konfirmasi Simpan',
    String message = 'Apakah Anda yakin ingin menyimpan perubahan?',
    String confirmText = 'Simpan',
    String cancelText = 'Batal',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      icon: const Icon(
        Icons.save_outlined,
        color: AppTheme.primaryColor,
      ),
    );
  }

  static Future<bool?> showExitConfirmation({
    required BuildContext context,
    String title = 'Konfirmasi Keluar',
    String message = 'Apakah Anda yakin ingin keluar? Perubahan yang belum disimpan akan hilang.',
    String confirmText = 'Keluar',
    String cancelText = 'Batal',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      isDestructive: true,
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: AppTheme.warningColor,
      ),
    );
  }
}