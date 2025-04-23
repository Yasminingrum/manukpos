// lib/utils/print_utils.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Model untuk printer bluetooth
class PrinterBluetooth {
  final String name;
  final String address;
  final int type;

  PrinterBluetooth({
    required this.name,
    required this.address,
    required this.type,
  });
}

/// Enum untuk jenis align teks
enum PosAlign {
  left,
  center,
  right,
}

/// Enum untuk ukuran teks
enum PosTextSize {
  size1,
  size2,
  size3,
  size4,
}

/// Enum untuk jenis font
enum PosFontType {
  fontA,
  fontB,
}

/// Class untuk style teks
class PosStyles {
  final PosAlign align;
  final bool bold;
  final PosTextSize? height;
  final PosTextSize? width;
  final PosFontType? fontType;

  const PosStyles({
    this.align = PosAlign.left,
    this.bold = false,
    this.height,
    this.width,
    this.fontType,
  });
}

/// Class untuk kolom teks
class PosColumn {
  final String text;
  final int width;
  final PosStyles styles;

  PosColumn({
    required this.text,
    required this.width,
    this.styles = const PosStyles(),
  });
}

/// Class untuk profil printer
class CapabilityProfile {
  CapabilityProfile._();

  static Future<CapabilityProfile> load() async {
    return CapabilityProfile._();
  }
}

/// Enum untuk ukuran kertas
enum PaperSize {
  mm58,
  mm80,
}

/// Generator untuk receipt
class Generator {
  final PaperSize paperSize;
  final CapabilityProfile profile;

  Generator(this.paperSize, this.profile);

  List<int> text(String text, {PosStyles styles = const PosStyles()}) {
    return []; // Seharusnya mengembalikan byte untuk teks
  }

  List<int> row(List<PosColumn> columns) {
    return []; // Seharusnya mengembalikan byte untuk baris
  }

  List<int> hr({String ch = '-', int? linesAfter}) {
    return []; // Seharusnya mengembalikan byte untuk garis horizontal
  }

  List<int> cut() {
    return []; // Seharusnya mengembalikan byte untuk memotong kertas
  }
}

/// Class untuk mengelola printer bluetooth
class PrinterBluetoothManager {
  static const int connectedDevice = 1; // Menggunakan lowerCamelCase
  
  /// Memilih printer
  Future<void> selectPrinter(PrinterBluetooth printer) async {
    // Implementasi untuk memilih printer
  }

  /// Mencetak tiket
  Future<void> printTicket(List<int> bytes) async {
    // Implementasi untuk mencetak tiket
  }
}

/// Utility class for receipt printing operations
class PrintUtils {
  static final PrinterBluetoothManager _printerManager = PrinterBluetoothManager();
  
  /// Initialize printer manager
  static Future<void> initPrinter() async {
    // Initialize printer manager
  }

  /// Get available Bluetooth printers
  static Future<List<PrinterBluetooth>> getBluetoothDevices() async {
    final List<PrinterBluetooth> devices = [];
    
    try {
      final paired = await FlutterBluetoothSerial.instance.getBondedDevices();
      
      for (final device in paired) {
        final printer = PrinterBluetooth(
          name: device.name ?? 'Unknown',
          address: device.address,
          type: PrinterBluetoothManager.connectedDevice,
        );
        devices.add(printer);
      }
    } catch (e) {
      debugPrint('Error getting Bluetooth devices: $e');
    }
    
    return devices;
  }

  /// Connect to a Bluetooth printer
  static Future<bool> connectPrinter(PrinterBluetooth printer) async {
    try {
      await _printerManager.selectPrinter(printer);
      return true;
    } catch (e) {
      debugPrint('Error connecting to printer: $e');
      return false;
    }
  }

  /// Generate receipt content
  static Future<List<int>> generateReceipt({
    required String businessName,
    required String address,
    required String phone,
    required String invoiceNumber,
    required DateTime date,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required double paid,
    required double change,
    String? cashierName,
    String? customerName,
    String? footer,
  }) async {
    // Get profile
    final profile = await CapabilityProfile.load();
    // Initialize printer
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(businessName,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += generator.text(address, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Tel: $phone', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // Invoice info
    bytes += generator.text('Invoice #: $invoiceNumber',
        styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Date: ${date.toString().substring(0, 16)}',
        styles: const PosStyles(align: PosAlign.left));

    if (cashierName != null) {
      bytes += generator.text('Cashier: $cashierName',
          styles: const PosStyles(align: PosAlign.left));
    }

    if (customerName != null) {
      bytes += generator.text('Customer: $customerName',
          styles: const PosStyles(align: PosAlign.left));
    }

    bytes += generator.hr();

    // Items
    bytes += generator.row([
      PosColumn(text: 'Item', width: 4),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.right)),
      PosColumn(text: 'Price', width: 3, styles: const PosStyles(align: PosAlign.right)),
      PosColumn(text: 'Total', width: 3, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.hr();

    for (var item in items) {
      // Item name might be long, handle line breaks
      final String name = item['name'];
      final double qty = item['quantity'];
      final double price = item['price'];
      final double itemTotal = item['total'];

      bytes += generator.row([
        PosColumn(text: name, width: 4),
        PosColumn(
            text: qty.toString(), width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(
            text: price.toStringAsFixed(0),
            width: 3,
            styles: const PosStyles(align: PosAlign.right)),
        PosColumn(
            text: itemTotal.toStringAsFixed(0),
            width: 3,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();

    // Totals
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(
          text: subtotal.toStringAsFixed(0),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount', width: 6),
        PosColumn(
            text: '(${discount.toStringAsFixed(0)})',
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if (tax > 0) {
      bytes += generator.row([
        PosColumn(text: 'Tax', width: 6),
        PosColumn(
            text: tax.toStringAsFixed(0),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr(ch: '=', linesAfter: 1);

    bytes += generator.row([
      PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )),
      PosColumn(
          text: total.toStringAsFixed(0),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )),
    ]);

    bytes += generator.hr();

    // Payment info
    bytes += generator.row([
      PosColumn(text: 'PAID', width: 6),
      PosColumn(
          text: paid.toStringAsFixed(0),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'CHANGE', width: 6),
      PosColumn(
          text: change.toStringAsFixed(0),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.hr();

    // Footer
    if (footer != null) {
      bytes += generator.text(footer, styles: const PosStyles(align: PosAlign.center));
    }

    bytes += generator.text('Terima kasih atas kunjungan Anda!',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(DateTime.now().toString().substring(0, 19),
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));

    bytes += generator.cut();

    return bytes;
  }

  /// Print receipt
  static Future<void> printReceipt(List<int> bytes) async {
    try {
      await _printerManager.printTicket(bytes);
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      throw Exception('Failed to print receipt');
    }
  }
}