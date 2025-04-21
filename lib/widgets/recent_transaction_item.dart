// widgets/recent_transaction_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

class RecentTransactionItem extends StatelessWidget {
  final String invoice;
  final DateTime date;
  final double amount;
  final String customerName;
  final String status;
  final VoidCallback? onTap;

  const RecentTransactionItem({
    super.key,
    required this.invoice,
    required this.date,
    required this.amount,
    required this.customerName,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    
    // Determine status color
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'paid':
      case 'dibayar':
        statusColor = AppTheme.successColor;
        break;
      case 'unpaid':
      case 'belum dibayar':
        statusColor = AppTheme.warningColor;
        break;
      case 'partial':
      case 'sebagian':
        statusColor = AppTheme.infoColor;
        break;
      case 'cancelled':
      case 'dibatalkan':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.textMedium;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Text(
            invoice,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(dateFormat.format(date)),
          Text('Pelanggan: $customerName'),
        ],
      ),
      trailing: Text(
        currencyFormat.format(amount),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}