// lib/widgets/sales_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../config/theme.dart';

class SalesChart extends StatelessWidget {
  final List<Transaction> transactions;
  final int daysToShow;

  const SalesChart({
    super.key, 
    required this.transactions,
    this.daysToShow = 7,
  });

  @override
  Widget build(BuildContext context) {
    // Preprocess data
    final Map<DateTime, double> dailySales = _processDailySales();
    final List<FlSpot> spots = _createSpots(dailySales);
    
    // If no data, show a message
    if (spots.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data penjualan',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafik Penjualan ${daysToShow > 1 ? "$daysToShow Hari Terakhir" : "Hari Ini"}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                gridData: _buildGridData(),
                titlesData: _buildTitlesData(dailySales),
                borderData: _buildBorderData(),
                lineBarsData: [_buildLineChartBarData(spots)],
                minX: spots.first.x,
                maxX: spots.last.x,
                minY: 0,
                maxY: _findMaxY(spots) * 1.2, // Add 20% padding on top
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Process daily sales from transactions
  Map<DateTime, double> _processDailySales() {
    // Get current date for reference
    final now = DateTime.now();
    final Map<DateTime, double> dailySales = {};
    
    // Initialize with zero values for all days in range
    for (int i = 0; i < daysToShow; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      dailySales[date] = 0;
    }
    
    // Sum transactions by date
    for (final transaction in transactions) {
      if (transaction.transactionDate != null) {
        final date = DateTime.parse(transaction.transactionDate!);
        final dateOnly = DateTime(date.year, date.month, date.day);
        
        // Only include transactions within daysToShow range
        final daysDifference = now.difference(dateOnly).inDays;
        if (daysDifference < daysToShow) {
          dailySales.update(
            dateOnly,
            (value) => value + transaction.grandTotal,
            ifAbsent: () => transaction.grandTotal,
          );
        }
      }
    }
    
    // Convert to sorted list of entries (oldest first)
    final sortedDates = dailySales.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    final sortedDailySales = <DateTime, double>{};
    for (final date in sortedDates) {
      sortedDailySales[date] = dailySales[date]!;
    }
    
    return sortedDailySales;
  }

  // Create FlSpot list for the chart
  List<FlSpot> _createSpots(Map<DateTime, double> dailySales) {
    final List<FlSpot> spots = [];
    int index = 0;
    
    dailySales.forEach((date, amount) {
      spots.add(FlSpot(index.toDouble(), amount));
      index++;
    });
    
    return spots;
  }

  // Find maximum Y value in data
  double _findMaxY(List<FlSpot> spots) {
    double max = 0;
    for (final spot in spots) {
      if (spot.y > max) {
        max = spot.y;
      }
    }
    return max > 0 ? max : 1000; // Default if all values are 0
  }

  // Build grid data
  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 10000,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.grey.shade200,
          strokeWidth: 1,
        );
      },
    );
  }

  // Build titles data
  FlTitlesData _buildTitlesData(Map<DateTime, double> dailySales) {
    final dateFormat = DateFormat('dd/MM');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            if (value < 0 || value >= dailySales.length) {
              return const SizedBox.shrink();
            }
            
            final date = dailySales.keys.elementAt(value.toInt());
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                dateFormat.format(date),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
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
          reservedSize: 80,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                currencyFormat.format(value),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.right,
              ),
            );
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
  LineChartBarData _buildLineChartBarData(List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: AppTheme.primaryColor,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: AppTheme.primaryColor,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: AppTheme.primaryColor.withOpacity(0.2),
      ),
    );
  }
}