// lib/widgets/report_filter_chip.dart
import 'package:flutter/material.dart';

class ReportFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const ReportFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
      ),
    );
  }
}