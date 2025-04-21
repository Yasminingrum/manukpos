// lib/utils/export_utils.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Utility class for exporting data to various formats
class ExportUtils {
  /// Export data to CSV format
  static Future<File> exportToCSV(
    List<List<dynamic>> data, 
    List<String> headers, 
    String fileName,
  ) async {
    final directory = await getExternalStorageDirectory();
    final path = '${directory!.path}/$fileName.csv';
    final file = File(path);
    
    final buffer = StringBuffer();
    
    // Add headers
    buffer.writeln(headers.join(','));
    
    // Add data rows
    for (var row in data) {
      final processedRow = row.map((item) {
        // Handle commas in text by quoting
        if (item is String && item.contains(',')) {
          return '"$item"';
        }
        return item;
      }).toList();
      
      buffer.writeln(processedRow.join(','));
    }
    
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Export data to Excel format
  static Future<File> exportToExcel(
    List<List<dynamic>> data, 
    List<String> headers, 
    String fileName,
    {String sheetName = 'Sheet1'}
  ) async {
    final excelObj = excel.Excel.createExcel();
    
    // Remove default sheet
    excelObj.delete('Sheet1');
    
    // Create new sheet
    final sheet = excelObj[sheetName];
    
    // Add headers
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = headers[i];
    }
    
    // Add data
    for (var i = 0; i < data.length; i++) {
      for (var j = 0; j < data[i].length; j++) {
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1)).value = data[i][j];
      }
    }
    
    // Save to file
    final directory = await getExternalStorageDirectory();
    final path = '${directory!.path}/$fileName.xlsx';
    final file = File(path);
    
    await file.writeAsBytes(excelObj.encode()!);
    return file;
  }

  /// Export data to PDF format
  static Future<File> exportToPDF(
    List<List<dynamic>> data, 
    List<String> headers, 
    String fileName, 
    {String title = '', String subtitle = ''}
  ) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPDFHeader(title, subtitle),
        footer: (context) => _buildPDFFooter(context),
        build: (context) => [
          _buildPDFTable(headers, data),
        ],
      ),
    );
    
    // Save to file
    final directory = await getExternalStorageDirectory();
    final path = '${directory!.path}/$fileName.pdf';
    final file = File(path);
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Build PDF header
  static pw.Widget _buildPDFHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (subtitle.isNotEmpty)
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
        pw.SizedBox(height: 8),
        pw.Divider(),
      ],
    );
  }

  /// Build PDF footer
  static pw.Widget _buildPDFFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Build PDF table
  static pw.Widget _buildPDFTable(List<String> headers, List<List<dynamic>> data) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColors.grey300,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }

  /// Share exported file
  static Future<void> shareFile(File file, {String subject = ''}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported from MANUK POS',
      subject: subject.isNotEmpty ? subject : 'Data Export',
    );
  }
}