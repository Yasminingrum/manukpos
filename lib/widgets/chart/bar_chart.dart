// lib/widgets/chart/bar_chart.dart
import 'package:flutter/material.dart';

class BarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String xAxisKey;
  final String yAxisKey;
  final String? labelKey;
  final Color barColor;
  final Color? backgroundColor;
  final bool showValues;
  final bool showLabels;
  final bool showGrid;
  final bool animate;
  final String Function(dynamic)? valueFormatter;
  final bool isVertical;
  final double barSpacing;
  final double barWidth;
  final int maxBars;

  const BarChart({
    super.key,
    required this.data,
    required this.xAxisKey,
    required this.yAxisKey,
    this.labelKey,
    this.barColor = Colors.blue,
    this.backgroundColor,
    this.showValues = true,
    this.showLabels = true,
    this.showGrid = true,
    this.animate = true,
    this.valueFormatter,
    this.isVertical = true,
    this.barSpacing = 8.0,
    this.barWidth = 20.0,
    this.maxBars = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data to display'),
      );
    }

    // Limit the number of bars to display
    final limitedData = data.length > maxBars ? data.sublist(0, maxBars) : data;

    // Find maximum value for scaling
    double maxValue = 0;
    for (final item in limitedData) {
      final value = item[yAxisKey] is num ? (item[yAxisKey] as num).toDouble() : 0.0;
      if (value > maxValue) {
        maxValue = value;
      }
    }

    // Add a little headroom
    maxValue = maxValue * 1.1;

    return Container(
      color: backgroundColor,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarChartPainter(
          data: limitedData,
          xAxisKey: xAxisKey,
          yAxisKey: yAxisKey,
          labelKey: labelKey ?? xAxisKey,
          barColor: barColor,
          maxValue: maxValue,
          showValues: showValues,
          showLabels: showLabels,
          showGrid: showGrid,
          valueFormatter: valueFormatter,
          isVertical: isVertical,
          barSpacing: barSpacing,
          barWidth: barWidth,
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String xAxisKey;
  final String yAxisKey;
  final String labelKey;
  final Color barColor;
  final double maxValue;
  final bool showValues;
  final bool showLabels;
  final bool showGrid;
  final String Function(dynamic)? valueFormatter;
  final bool isVertical;
  final double barSpacing;
  final double barWidth;

  _BarChartPainter({
    required this.data,
    required this.xAxisKey,
    required this.yAxisKey,
    required this.labelKey,
    required this.barColor,
    required this.maxValue,
    this.showValues = true,
    this.showLabels = true,
    this.showGrid = true,
    this.valueFormatter,
    this.isVertical = true,
    this.barSpacing = 8.0,
    this.barWidth = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue <= 0) return;

    // Chart positioning
    final chartPadding = const EdgeInsets.fromLTRB(50, 20, 20, 40);
    final chartRect = Rect.fromLTWH(
      chartPadding.left,
      chartPadding.top,
      size.width - chartPadding.left - chartPadding.right,
      size.height - chartPadding.top - chartPadding.bottom,
    );

    // Draw chart background
    final backgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey.shade200;

    canvas.drawRect(chartRect, backgroundPaint);

    // Draw grid lines
    if (showGrid) {
      _drawGridLines(canvas, chartRect);
    }

    // Draw axis
    _drawAxes(canvas, chartRect);

    // Draw bars
    _drawBars(canvas, chartRect);

    // Draw values and labels
    if (showValues || showLabels) {
      _drawLabelsAndValues(canvas, chartRect);
    }
  }

  void _drawGridLines(Canvas canvas, Rect chartRect) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // Draw horizontal grid lines (for y-axis values)
    const int divisions = 5; // Number of horizontal grid lines
    for (int i = 0; i <= divisions; i++) {
      final y = chartRect.top + (chartRect.height / divisions) * i;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );

      // Draw y-axis labels
      final value = maxValue - (maxValue / divisions) * i;
      final formattedValue = valueFormatter != null ? 
          valueFormatter!(value) : value.toStringAsFixed(0);
      
      final textSpan = TextSpan(
        text: formattedValue,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 10,
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(chartRect.left - textPainter.width - 5, y - textPainter.height / 2),
      );
    }
  }

  void _drawAxes(Canvas canvas, Rect chartRect) {
    final axisPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1;

    // Draw x-axis
    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      axisPaint,
    );

    // Draw y-axis
    canvas.drawLine(
      Offset(chartRect.left, chartRect.top),
      Offset(chartRect.left, chartRect.bottom),
      axisPaint,
    );
  }

  void _drawBars(Canvas canvas, Rect chartRect) {
    if (data.isEmpty) return;

    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final totalWidth = data.length * (barWidth + barSpacing) - barSpacing;
    final startX = chartRect.left + (chartRect.width - totalWidth) / 2;

    for (int i = 0; i < data.length; i++) {
      final value = data[i][yAxisKey] is num ? 
          (data[i][yAxisKey] as num).toDouble() : 0.0;
      
      final barHeight = (value / maxValue) * chartRect.height;
      
      final rect = Rect.fromLTWH(
        startX + i * (barWidth + barSpacing),
        chartRect.bottom - barHeight,
        barWidth,
        barHeight,
      );
      
      canvas.drawRect(rect, barPaint);
    }
  }

  void _drawLabelsAndValues(Canvas canvas, Rect chartRect) {
    if (data.isEmpty) return;

    final totalWidth = data.length * (barWidth + barSpacing) - barSpacing;
    final startX = chartRect.left + (chartRect.width - totalWidth) / 2;

    for (int i = 0; i < data.length; i++) {
      final value = data[i][yAxisKey] is num ? 
          (data[i][yAxisKey] as num).toDouble() : 0.0;
      final label = data[i][labelKey]?.toString() ?? '';
      
      final barHeight = (value / maxValue) * chartRect.height;
      final barCenter = startX + i * (barWidth + barSpacing) + barWidth / 2;
      
      // Draw value above the bar
      if (showValues) {
        final formattedValue = valueFormatter != null ? 
            valueFormatter!(value) : value.toStringAsFixed(0);
        
        final valueSpan = TextSpan(
          text: formattedValue,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        
        final valuePainter = TextPainter(
          text: valueSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        
        valuePainter.layout();
        valuePainter.paint(
          canvas, 
          Offset(
            barCenter - valuePainter.width / 2,
            chartRect.bottom - barHeight - valuePainter.height - 4,
          ),
        );
      }
      
      // Draw label below the bar
      if (showLabels) {
        final labelSpan = TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
          ),
        );
        
        final labelPainter = TextPainter(
          text: labelSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        
        labelPainter.layout();
        
        // Rotate the canvas for angled labels if there are many bars
        canvas.save();
        final pivotX = barCenter;
        final pivotY = chartRect.bottom + 5;
        
        if (data.length > 6) {
          // Rotate labels for better readability when many bars
          canvas.translate(pivotX, pivotY);
          canvas.rotate(45 * 3.14159 / 180);
          canvas.translate(-pivotX, -pivotY);
        }
        
        labelPainter.paint(
          canvas, 
          Offset(
            barCenter - labelPainter.width / 2,
            chartRect.bottom + 5,
          ),
        );
        
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}