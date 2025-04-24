// lib/widgets/inventory_movement_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/inventory_movement.dart';

class InventoryMovementChart extends StatelessWidget {
  final List<InventoryMovement> movements;
  final int daysToShow;
  final String title;

  const InventoryMovementChart({
    super.key,
    required this.movements,
    this.daysToShow = 30,
    this.title = 'Pergerakan Stok',
  });

  @override
  Widget build(BuildContext context) {
    // Process movement data
    final processedData = _processMovementData();
    final inSpots = processedData['in'] ?? [];
    final outSpots = processedData['out'] ?? [];

    // If no data, show a message
    if (inSpots.isEmpty && outSpots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Belum ada data pergerakan stok',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    // Find max Y value for scaling
    double maxY = 0;
    for (final spot in [...inSpots, ...outSpots]) {
      if (spot.y > maxY) maxY = spot.y;
    }
    maxY = maxY > 0 ? maxY * 1.2 : 10; // Add 20% padding or default to 10

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem('Masuk', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem('Keluar', Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                gridData: _buildGridData(),
                titlesData: _buildTitlesData(),
                borderData: _buildBorderData(),
                lineBarsData: [
                  if (inSpots.isNotEmpty)
                    _buildLineChartBarData(inSpots, Colors.green),
                  if (outSpots.isNotEmpty)
                    _buildLineChartBarData(outSpots, Colors.red),
                ],
                minX: 0,
                maxX: daysToShow.toDouble() - 1,
                minY: 0,
                maxY: maxY,
                lineTouchData: _buildLineTouchData(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Process movement data into chart data points
  Map<String, List<FlSpot>> _processMovementData() {
    // Initialize with current date
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day - daysToShow + 1);
    
    // Create map with dates as keys and default zero values
    final Map<DateTime, double> inData = {};
    final Map<DateTime, double> outData = {};
    
    // Fill with zero values for all days in range
    for (int i = 0; i < daysToShow; i++) {
      final date = DateTime(startDate.year, startDate.month, startDate.day + i);
      inData[date] = 0;
      outData[date] = 0;
    }
    
    // Sum movements by date and type
    for (final movement in movements) {
      final dateOnly = DateTime(
        movement.date.year,
        movement.date.month,
        movement.date.day,
      );
      
      // Only include movements within range
      if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) && 
          dateOnly.isBefore(now.add(const Duration(days: 1)))) {
        
        if (movement.type == InventoryMovement.typeIn) {
          inData.update(
            dateOnly,
            (value) => value + movement.quantity,
            ifAbsent: () => movement.quantity,
          );
        } else if (movement.type == InventoryMovement.typeOut) {
          outData.update(
            dateOnly,
            (value) => value + movement.quantity,
            ifAbsent: () => movement.quantity,
          );
        }
      }
    }
    
    // Convert to sorted lists
    final sortedDates = inData.keys.toList()..sort();
    
    // Create in/out data points
    final List<FlSpot> inSpots = [];
    final List<FlSpot> outSpots = [];
    
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      
      if (inData.containsKey(date)) {
        inSpots.add(FlSpot(i.toDouble(), inData[date]!));
      }
      
      if (outData.containsKey(date)) {
        outSpots.add(FlSpot(i.toDouble(), outData[date]!));
      }
    }
    
    return {
      'in': inSpots,
      'out': outSpots,
    };
  }

  // Build grid data
  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.grey.shade200,
          strokeWidth: 1,
        );
      },
    );
  }

  // Build titles data
  FlTitlesData _buildTitlesData() {
    // Date formatter
    final dateFormat = DateFormat('dd/MM');
    
    // Calculate dates for the X-axis
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day - daysToShow + 1);
    final dates = List<DateTime>.generate(
      daysToShow,
      (i) => DateTime(startDate.year, startDate.month, startDate.day + i),
    );
    
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: (daysToShow > 14) ? 3 : 1, // Less crowded for many days
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= dates.length) {
              return const SizedBox.shrink();
            }
            
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                dateFormat.format(dates[index]),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            // Only show whole numbers
            if (value == value.roundToDouble()) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  // Build border data
  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        left: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
    );
  }

  // Build line chart bar data
  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withAlpha(40), // Using withAlpha instead of withOpacity
      ),
    );
  }

  // Build line touch data
  LineTouchData _buildLineTouchData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          return touchedSpots.map((LineBarSpot spot) {
            final color = spot.bar.color ?? Colors.blue;
            final type = color == Colors.green ? 'Masuk' : 'Keluar';
            
            return LineTooltipItem(
              '$type: ${spot.y.toStringAsFixed(1)}',
              TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList();
        },
      ),
    );
  }

  // Build legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}