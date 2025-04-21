// widgets/cash_flow_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import 'dart:math' as math;

class CashFlowChart extends StatelessWidget {
  final List<Expense> expenses;
  final DateTime startDate;
  final DateTime endDate;
  final bool showAverage;

  const CashFlowChart({
    super.key,
    required this.expenses,
    required this.startDate,
    required this.endDate,
    this.showAverage = true,
  });

  @override
  Widget build(BuildContext context) {
    final daysDifference = endDate.difference(startDate).inDays + 1;
    
    // Choose interval type based on the date range
    final ChartIntervalType intervalType = _getIntervalType(daysDifference);
    
    // Generate expense data points
    final groupedData = _prepareChartData(intervalType);
    
    // If no data, show message
    if (groupedData.isEmpty) {
      return const Center(
        child: Text(
          'No expense data for the selected period',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    // Calculate statistics
    final totalAmount = groupedData.fold<double>(
      0, (sum, item) => sum + item.amount);
    final average = totalAmount / groupedData.length;
    
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: _buildChart(groupedData, intervalType, average),
        ),
        const SizedBox(height: 8),
        if (showAverage && groupedData.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: Rp ${NumberFormat('#,###').format(totalAmount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Average: Rp ${NumberFormat('#,###').format(average)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChart(
    List<ChartDataPoint> data, 
    ChartIntervalType intervalType,
    double average,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, right: 16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withAlpha(51),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withAlpha(51),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => _getBottomTitle(value, intervalType),
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      NumberFormat.compact().format(value),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                interval: _calculateYAxisInterval(data),
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              left: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          minX: 0,
          maxX: data.length.toDouble() - 1,
          minY: 0,
          maxY: _calculateMaxY(data),
          lineBarsData: [
            // Expense line
            LineChartBarData(
              spots: _getSpots(data),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: data.length < 15, // Only show dots for smaller datasets
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.red,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withAlpha(26),
              ),
            ),
            // Average line
            if (showAverage)
              LineChartBarData(
                spots: [
                  FlSpot(0, average),
                  FlSpot(data.length - 1, average),
                ],
                isCurved: false,
                color: Colors.blue.withAlpha(204),
                barWidth: 1,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                dashArray: [5, 5],
              ),
          ],
          // Use a simplified touch data configuration to avoid version conflicts
          lineTouchData: LineTouchData(
            enabled: true,
          ),
        ),
      ),
    );
  }

  Widget _getBottomTitle(double value, ChartIntervalType intervalType) {
    final index = value.toInt();
    if (index < 0 || index >= _prepareChartData(intervalType).length) {
      return const SizedBox();
    }
    
    final date = _prepareChartData(intervalType)[index].date;
    
    String text;
    switch (intervalType) {
      case ChartIntervalType.day:
        text = DateFormat('dd').format(date);
        break;
      case ChartIntervalType.week:
        text = 'W${_getWeekOfYear(date)}';
        break;
      case ChartIntervalType.month:
        text = DateFormat('MMM').format(date);
        break;
      case ChartIntervalType.year:
        text = DateFormat('yyyy').format(date);
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 10,
        ),
      ),
    );
  }

  List<FlSpot> _getSpots(List<ChartDataPoint> data) {
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.amount);
    }).toList();
  }

  double _calculateMaxY(List<ChartDataPoint> data) {
    if (data.isEmpty) return 100;
    
    // Find the maximum amount
    double maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    
    // Add 10% for padding
    maxAmount *= 1.1;
    
    // Round to a nice number
    return _roundToNiceNumber(maxAmount);
  }

  double _roundToNiceNumber(double number) {
    // Find the magnitude (e.g., 10, 100, 1000)
    final magnitude = 10.0.pow((number.log() / math.log(10)).floor());
    
    // Round up to a multiple of 1, 2, 5 times the magnitude
    if (number <= 1 * magnitude) return 1 * magnitude;
    if (number <= 2 * magnitude) return 2 * magnitude;
    if (number <= 5 * magnitude) return 5 * magnitude;
    return 10 * magnitude;
  }

  double _calculateYAxisInterval(List<ChartDataPoint> data) {
    final maxY = _calculateMaxY(data);
    
    // Target 4-6 grid lines
    final targetDivisions = 5;
    
    // Start with simple division
    double interval = maxY / targetDivisions;
    
    // Round to a nice number
    final magnitude = 10.0.pow((interval.log() / math.log(10)).floor());
    
    if (interval <= 1 * magnitude) return 1 * magnitude;
    if (interval <= 2 * magnitude) return 2 * magnitude;
    if (interval <= 5 * magnitude) return 5 * magnitude;
    return 10 * magnitude;
  }

  String _formatDateForTooltip(DateTime date, ChartIntervalType intervalType) {
    switch (intervalType) {
      case ChartIntervalType.day:
        return DateFormat('d MMM yyyy').format(date);
      case ChartIntervalType.week:
        final firstDayOfWeek = date;
        final lastDayOfWeek = date.add(const Duration(days: 6));
        return '${DateFormat('d MMM').format(firstDayOfWeek)} - ${DateFormat('d MMM yyyy').format(lastDayOfWeek)}';
      case ChartIntervalType.month:
        return DateFormat('MMMM yyyy').format(date);
      case ChartIntervalType.year:
        return DateFormat('yyyy').format(date);
    }
  }

  int _getWeekOfYear(DateTime date) {
    // Calculate week of year (1-based)
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  ChartIntervalType _getIntervalType(int daysDifference) {
    if (daysDifference <= 31) {
      return ChartIntervalType.day;
    } else if (daysDifference <= 120) {
      return ChartIntervalType.week;
    } else if (daysDifference <= 730) {
      return ChartIntervalType.month;
    } else {
      return ChartIntervalType.year;
    }
  }

  List<ChartDataPoint> _prepareChartData(ChartIntervalType intervalType) {
    if (expenses.isEmpty) return [];
    
    // Group expenses based on the interval type
    Map<String, ChartDataPoint> groupedData = {};
    
    for (var expense in expenses) {
      final date = expense.expenseDate;
      String key;
      DateTime groupDate;
      
      switch (intervalType) {
        case ChartIntervalType.day:
          key = DateFormat('yyyy-MM-dd').format(date);
          groupDate = DateTime(date.year, date.month, date.day);
          break;
        case ChartIntervalType.week:
          // Get the week start date (Monday)
          final weekStart = date.subtract(Duration(days: date.weekday - 1));
          key = DateFormat('yyyy-MM-dd').format(weekStart);
          groupDate = weekStart;
          break;
        case ChartIntervalType.month:
          key = DateFormat('yyyy-MM').format(date);
          groupDate = DateTime(date.year, date.month, 1);
          break;
        case ChartIntervalType.year:
          key = DateFormat('yyyy').format(date);
          groupDate = DateTime(date.year, 1, 1);
          break;
      }
      
      if (groupedData.containsKey(key)) {
        groupedData[key]!.amount += expense.amount;
        groupedData[key]!.count++;
      } else {
        groupedData[key] = ChartDataPoint(
          date: groupDate,
          amount: expense.amount,
          count: 1,
        );
      }
    }
    
    // Sort data points by date
    final dataPoints = groupedData.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    return dataPoints;
  }
}

// Data model for chart points
class ChartDataPoint {
  final DateTime date;
  double amount;
  int count;
  
  ChartDataPoint({
    required this.date,
    required this.amount,
    this.count = 1,
  });
}

// Enum for chart interval types
enum ChartIntervalType {
  day,
  week,
  month,
  year,
}

// Extension method for double
extension DoublePower on double {
  double pow(int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent.abs(); i++) {
      result *= this;
    }
    return exponent < 0 ? 1.0 / result : result;
  }
  
  double log() {
    return math.log(this);
  }
}