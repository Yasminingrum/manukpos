// widgets/report_summary_card.dart
import 'package:flutter/material.dart';

class ReportSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const ReportSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = Colors.blue,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(26), // 0.1 * 255 ≈ 26
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withAlpha(26), // 0.1 * 255 ≈ 26
                    child: Icon(
                      icon,
                      size: 22,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Additional summary card for comparative data
class ComparativeSummaryCard extends StatelessWidget {
  final String title;
  final String currentValue;
  final String previousValue;
  final double percentageChange;
  final IconData icon;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  const ComparativeSummaryCard({
    super.key,
    required this.title,
    required this.currentValue,
    required this.previousValue,
    required this.percentageChange,
    required this.icon,
    required this.isPositiveTrend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on trend and whether increase is good
    final Color trendColor = isPositiveTrend
        ? Colors.green
        : Colors.red;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(26), // 0.1 * 255 ≈ 26
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: trendColor.withAlpha(26), // 0.1 * 255 ≈ 26
                    child: Icon(
                      icon,
                      size: 22,
                      color: trendColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentValue,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Previous: $previousValue',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isPositiveTrend 
                            ? Icons.arrow_upward 
                            : Icons.arrow_downward,
                        size: 14,
                        color: trendColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percentageChange.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: trendColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}