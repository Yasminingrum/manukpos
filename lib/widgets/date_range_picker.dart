// widgets/date_range_picker.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangePicker extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime) onDateRangeChanged;

  const DateRangePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Range',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  context, 
                  'Start Date', 
                  startDate,
                  (date) => onDateRangeChanged(date, endDate),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateSelector(
                  context, 
                  'End Date', 
                  endDate,
                  (date) => onDateRangeChanged(startDate, date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPresetButton('Today', () => _setToday(context)),
              _buildPresetButton('This Week', () => _setThisWeek(context)),
              _buildPresetButton('This Month', () => _setThisMonth(context)),
              _buildPresetButton('This Year', () => _setThisYear(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
    BuildContext context, 
    String label, 
    DateTime date,
    Function(DateTime) onDateChanged,
  ) {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        
        if (selected != null) {
          onDateChanged(selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _setToday(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start;
    onDateRangeChanged(start, end);
  }

  void _setThisWeek(BuildContext context) {
    final now = DateTime.now();
    // Calculate the start of the week (Monday)
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(start.year, start.month, start.day);
    
    // Calculate the end of the week (Sunday)
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    onDateRangeChanged(startOfWeek, endOfWeek);
  }

  void _setThisMonth(BuildContext context) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0); // Last day of current month
    
    onDateRangeChanged(startOfMonth, endOfMonth);
  }

  void _setThisYear(BuildContext context) {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);
    
    onDateRangeChanged(startOfYear, endOfYear);
  }
}