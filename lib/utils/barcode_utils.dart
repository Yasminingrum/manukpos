// lib/utils/barcode_utils.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide Barcode; // Mengganti barcode_scan2

/// Utility class for barcode operations
class BarcodeUtils {
  /// Scan a barcode or QR code
  static Future<String?> scanBarcode() async {
    try {
      final MobileScannerController controller = MobileScannerController();
      String? scannedValue;
      
      // Perlu implementasi UI untuk scanner
      // Berikut hanya contoh logika yang perlu diimplementasikan dalam widget sebenarnya
      controller.barcodes.listen((barcodeCapture) {
        if (barcodeCapture.barcodes.isNotEmpty && barcodeCapture.barcodes.first.displayValue != null) {
          scannedValue = barcodeCapture.barcodes.first.displayValue;
          controller.stop();
        }
      });
      
      // Dalam implementasi aktual, nilai akan dikembalikan setelah scan berhasil
      // Di sini kita menggunakan nilai placeholder
      return scannedValue;
    } on PlatformException catch (e) {
      if (e.code == 'CameraAccessDenied') {
        throw 'Camera permission was denied';
      } else {
        throw 'Unknown error: $e';
      }
    } catch (e) {
      throw 'Unknown error: $e';
    }
  }

  /// Generate a barcode as a Widget
  static Widget generateBarcodeWidget(
    String data, {
    BarcodeType type = BarcodeType.code128,
    double width = 200,
    double height = 80,
    Color color = Colors.black,
    BoxFit fit = BoxFit.contain,
  }) {
    return CustomPaint(
      size: Size(width, height),
      painter: BarcodePainter(
        data: data,
        barcodeType: type,
        color: color,
      ),
    );
  }

  /// Save barcode as image file
  static Future<File> saveBarcodeAsImage(
    String data, {
    BarcodeType type = BarcodeType.code128,
    double width = 200,
    double height = 80,
  }) async {
    // Create a widget to capture
    final barcodeWidget = RepaintBoundary(
      child: Container(
        color: Colors.white,
        child: generateBarcodeWidget(
          data,
          type: type,
          width: width,
          height: height,
        ),
      ),
    );

    // Create a GlobalKey to get the render object
    final RenderRepaintBoundary boundary = RenderRepaintBoundary();
    
    // Create a buildOwner and pipelineOwner for rendering
    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
    
    // Attach the renderObject to the pipelineOwner
    boundary.attach(pipelineOwner);
    
    // Create an element to manage the widget
    RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: barcodeWidget,
    ).attachToRenderTree(buildOwner);
    
    // Do a layout pass
    boundary.layout(BoxConstraints.tight(Size(width, height)));
    
    // Paint the boundary to an image
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('Failed to generate barcode image');
    }
    
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    
    // Save to file
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/barcode_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes);
    
    return file;
  }
}

/// Custom painter for rendering barcodes
class BarcodePainter extends CustomPainter {
  final String data;
  final BarcodeType barcodeType;
  final Color color;

  BarcodePainter({
    required this.data,
    required this.barcodeType,
    this.color = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Simple implementation: draw a rectangle with text
    final paint = Paint()..color = color;
    final textSpan = TextSpan(
      text: data,
      style: TextStyle(color: color, fontSize: 12),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    
    // Draw pattern based on barcode type
    _drawBarcodePattern(canvas, size, paint);
    
    // Draw the text at the bottom
    textPainter.paint(canvas, Offset(0, size.height * 0.8));
  }

  /// Draw a simple pattern based on barcode type
  void _drawBarcodePattern(Canvas canvas, Size size, Paint paint) {
    switch (barcodeType) {
      case BarcodeType.qrCode:
        _drawQRPattern(canvas, size, paint);
        break;
      default:
        _drawLinearPattern(canvas, size, paint);
        break;
    }
  }
  
  /// Draw a simple QR code pattern
  void _drawQRPattern(Canvas canvas, Size size, Paint paint) {
    final cellSize = size.width / 10;
    
    // Create a simple QR-like pattern (just for visual representation)
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        // Create a random-looking pattern based on data hash
        if ((data.hashCode + i * j) % 3 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(i * cellSize, j * cellSize, cellSize, cellSize),
            paint
          );
        }
      }
    }
    
    // Draw finder patterns (corners)
    final finderSize = cellSize * 3;
    
    // Top-left finder
    canvas.drawRect(Rect.fromLTWH(0, 0, finderSize, finderSize), paint);
    canvas.drawRect(
      Rect.fromLTWH(cellSize, cellSize, finderSize - 2 * cellSize, finderSize - 2 * cellSize),
      Paint()..color = Colors.white
    );
    canvas.drawRect(
      Rect.fromLTWH(cellSize * 1.5, cellSize * 1.5, cellSize, cellSize),
      paint
    );
    
    // Top-right finder
    canvas.drawRect(
      Rect.fromLTWH(size.width - finderSize, 0, finderSize, finderSize),
      paint
    );
    
    // Bottom-left finder
    canvas.drawRect(
      Rect.fromLTWH(0, size.width - finderSize, finderSize, finderSize),
      paint
    );
  }
  
  /// Draw a simple linear barcode pattern
  void _drawLinearPattern(Canvas canvas, Size size, Paint paint) {
    final barWidth = size.width / 50;
    double currentX = 0;
    
    // Draw start marker
    canvas.drawRect(
      Rect.fromLTWH(currentX, 0, barWidth, size.height * 0.7),
      paint
    );
    currentX += barWidth * 2;
    
    // Draw data bars (simplified)
    for (int i = 0; i < data.length; i++) {
      int charCode = data.codeUnitAt(i);
      bool drawBar = charCode % 2 == 0; // Simple pattern based on character code
      
      if (drawBar) {
        canvas.drawRect(
          Rect.fromLTWH(currentX, 0, barWidth, size.height * 0.7),
          paint
        );
      }
      
      currentX += barWidth * 1.5;
    }
    
    // Draw end marker
    canvas.drawRect(
      Rect.fromLTWH(size.width - barWidth * 2, 0, barWidth, size.height * 0.7),
      paint
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - barWidth, 0, barWidth, size.height * 0.7),
      paint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Barcode types supported by the application
enum BarcodeType {
  code128,
  ean13,
  ean8,
  qrCode,
  upcA,
  code39,
}