// widgets/export_button.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class ExportButton<T> extends StatelessWidget {
  final List<T> data;
  final Function? onExport;
  final String fileNamePrefix;

  const ExportButton({
    super.key,
    required this.data,
    this.onExport,
    this.fileNamePrefix = 'export',
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (onExport != null) {
          await onExport!();
        }
        
        // Store context.mounted in a local variable before async operations
        if (!context.mounted) return;
        
        if (value == 'pdf') {
          await _exportToPdf(context);
        } else if (value == 'csv') {
          await _exportToCsv(context);
        } else if (value == 'excel') {
          await _exportToExcel(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red),
              SizedBox(width: 8),
              Text('Export as PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.green),
              SizedBox(width: 8),
              Text('Export as CSV'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.table_view, color: Colors.blue),
              SizedBox(width: 8),
              Text('Export as Excel'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportToPdf(BuildContext context) async {
    try {
      // Show loading indicator before async operation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF file...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      await _checkPermission();
      
      // Generate file name with date
      final now = DateTime.now();
      final fileName = '${fileNamePrefix}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
      
      // PDF generation would go here
      // Wait for a short period to simulate processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if the context is still valid after the async operation
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF file exported: $fileName'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              // Share functionality would go here
            },
          ),
        ),
      );
    } catch (e) {
      // Check if context is still valid
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting to PDF: $e')),
      );
    }
  }

  Future<void> _exportToCsv(BuildContext context) async {
    try {
      // Show loading indicator before async operation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating CSV file...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      await _checkPermission();
      
      // Generate file name with date
      final now = DateTime.now();
      final fileName = '${fileNamePrefix}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
      
      // Get the document directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      
      // Generate CSV data
      List<List<dynamic>> csvData = _generateCsvData();
      
      // Convert to CSV string
      String csv = _convertToCsv(csvData);
      
      // Write to file
      final File file = File(filePath);
      await file.writeAsString(csv);
      
      // Check if context is still valid after async operations
      if (!context.mounted) return;
      
      // Share the file
      await Share.shareXFiles([XFile(filePath)], text: 'Exported CSV file');
      
      // Check again after another async operation
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV file exported: $fileName')),
      );
    } catch (e) {
      // Check if context is still valid
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting to CSV: $e')),
      );
    }
  }

  // Custom CSV converter implementation
  String _convertToCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        // Handle null values
        if (cell == null) return '';
        
        String value = cell.toString();
        
        // Escape quotes and wrap with quotes if needed
        if (value.contains(',') || value.contains('"') || value.contains('\n')) {
          value = '"${value.replaceAll('"', '""')}"';
        }
        
        return value;
      }).join(',');
    }).join('\n');
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      // Show loading indicator before async operation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating Excel file...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      await _checkPermission();
      
      // Generate file name with date
      final now = DateTime.now();
      final fileName = '${fileNamePrefix}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';
      
      // Excel generation would go here
      // Wait for a short period to simulate processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if the context is still valid after the async operation
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel file exported: $fileName'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              // Share functionality would go here
            },
          ),
        ),
      );
    } catch (e) {
      // Check if context is still valid
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting to Excel: $e')),
      );
    }
  }

  Future<void> _checkPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  List<List<dynamic>> _generateCsvData() {
    // This is a generic implementation that would need to be customized
    // based on the actual data type T
    
    // Header row
    final rows = <List<dynamic>>[];
    
    // Add header row based on type T
    if (data.isNotEmpty) {
      if (data.first is Map) {
        final map = data.first as Map;
        rows.add(map.keys.toList());
      } else {
        // For non-map objects, we'd need specific handling based on the type
        rows.add(['ID', 'Description', 'Amount', 'Date', 'Category']);
      }
    } else {
      rows.add(['No Data']);
    }
    
    // Add data rows
    for (var item in data) {
      if (item is Map) {
        rows.add(item.values.toList());
      } else {
        // Convert object to appropriate row format
        // This is an example and would need to be customized for actual objects
        rows.add([
          item.toString(),
          '',
          '',
          '',
          ''
        ]);
      }
    }
    
    return rows;
  }
}