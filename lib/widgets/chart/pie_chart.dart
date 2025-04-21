// lib/widgets/chart/pie_chart.dart
import 'dart:math';
import 'package:flutter/material.dart';

class PieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String labelKey;
  final String valueKey;
  final List<Color>? colors;
  final String Function(dynamic)? valueFormatter;
  final double? radius;
  final bool showLabels;
  final bool showValues;
  final bool showLegend;
  final TextStyle? labelStyle;

  const PieChart({
    super.key,
    required this.data,
    required this.labelKey,
    required this.valueKey,
    this.colors,
    this.valueFormatter,
    this.radius,
    this.showLabels = true,
    this.showValues = true,
    this.showLegend = true,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data to display'),
      );
    }

    // Calculate total value to determine percentages
    double total = 0;
    for (final item in data) {
      total += (item[valueKey] is num) ? item[valueKey].toDouble() : 0;
    }

    // Generate colors if not provided
    final chartColors = colors ?? _generateColors(data.length);

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _PieChartPainter(
              data: data,
              total: total,
              labelKey: labelKey,
              valueKey: valueKey,
              colors: chartColors,
              valueFormatter: valueFormatter,
              showLabels: showLabels,
              showValues: showValues,
              labelStyle: labelStyle ?? Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(data.length, (index) {
              final item = data[index];
              final color = chartColors[index % chartColors.length];
              final label = item[labelKey]?.toString() ?? '';
              final value = item[valueKey] ?? 0;
              final percentage = total > 0 ? (value / total * 100) : 0;
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$label (${percentage.toStringAsFixed(1)}%)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }),
          ),
        ],
      ],
    );
  }

  // Generate a list of distinct colors
  List<Color> _generateColors(int count) {
    final baseColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    
    if (count <= baseColors.length) {
      return baseColors.sublist(0, count);
    }
    
    // If we need more colors, generate additional ones
    final List<Color> colors = List.from(baseColors);
    final random = Random(0); // Use fixed seed for consistency
    
    for (int i = baseColors.length; i < count; i++) {
      colors.add(
        Color.fromRGBO(
          random.nextInt(255),
          random.nextInt(255),
          random.nextInt(255),
          1,
        ),
      );
    }
    
    return colors;
  }
}

class _PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double total;
  final String labelKey;
  final String valueKey;
  final List<Color> colors;
  final String Function(dynamic)? valueFormatter;
  final bool showLabels;
  final bool showValues;
  final TextStyle? labelStyle;

  _PieChartPainter({
    required this.data,
    required this.total,
    required this.labelKey,
    required this.valueKey,
    required this.colors,
    this.valueFormatter,
    this.showLabels = true,
    this.showValues = true,
    this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2.2;

    // Draw pie slices
    double startAngle = -pi / 2; // Start at the top
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final value = (item[valueKey] is num) ? item[valueKey].toDouble() : 0.0;
      final sweepAngle = (value / total) * 2 * pi;
      
      if (value <= 0 || sweepAngle <= 0) continue;
      
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors[i % colors.length];
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // Calculate position for label
      if (showLabels) {
        final labelAngle = startAngle + sweepAngle / 2;
        final labelRadius = radius * 0.65; // Place label at 65% of radius
        final labelX = center.dx + labelRadius * cos(labelAngle);
        final labelY = center.dy + labelRadius * sin(labelAngle);
        
        final label = item[labelKey]?.toString() ?? '';
        final percentage = (value / total * 100).toStringAsFixed(1) + '%';
        
        final textSpan = TextSpan(
          text: showValues 
              ? '$label\n$percentage' 
              : label,
          style: labelStyle ?? 
                 const TextStyle(
                   color: Colors.white,
                   fontSize: 10,
                   fontWeight: FontWeight.bold,
                 ),
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        
        textPainter.layout();
        
        // Calculate text position to center it
        final textX = labelX - textPainter.width / 2;
        final textY = labelY - textPainter.height / 2;
        
        textPainter.paint(canvas, Offset(textX, textY));
      }
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}