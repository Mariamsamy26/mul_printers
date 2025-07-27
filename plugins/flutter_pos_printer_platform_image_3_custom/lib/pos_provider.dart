import 'dart:developer';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;

// PosProvider.dart
class PosProvider with ChangeNotifier {
  //* USB PRINTER
  bool _isUSBPrinter = false;
  late PrinterManager _printerManagerUSB;
  int _vendorId = -1;
  int _productId = -1;
  String _printName = '';
  String _address = '';
  String _fullAddress = '';

  bool get isUSBPrinter => _isUSBPrinter;
  PrinterManager get printerManagerUSB => _printerManagerUSB;
  int get vendorId => _vendorId;
  int get productId => _productId;
  String get printName => _printName;
  String get address => _address;
  String get fullAddress => _fullAddress;

  void updateUSBPrinter({
    required PrinterManager printerManager,
    required String printName,
    required int vendorId,
    required int productId,
    required String rawAddress,
  }) {
    _printerManagerUSB = printerManager;
    _printName = printName;
    _vendorId = vendorId;
    _productId = productId;

    _address = rawAddress;
    _fullAddress = _getFullAddress(rawAddress);

    _isUSBPrinter = true;
    notifyListeners();

    // Log only once with full details
    print(
      "✅ Updated printer: $_printName (vendor=$_vendorId, product=$_productId, address=$_address, full=$_fullAddress)",
    );
  }

  Future printReceipt(
    ScreenshotController screenshotController,
    bool isUSB,
  ) async {
    List<int> bytes = [];

    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    final generator = Generator(PaperSize.mm80, profile);
    bytes += generator.setGlobalCodeTable('CP1252');

    var logoFromAssets = await rootBundle.load(
      'assets/images/gosmart_logo.png',
    );
    var logo = logoFromAssets.buffer.asUint8List();

    final capturedImage = await screenshotController.capture(
      delay: const Duration(milliseconds: 20),
      pixelRatio: 1.5,
    );

    if (capturedImage == null) {
      log("❌ Could not capture screenshot.");
      return;
    }

    img.Image? decodedImage = img.decodeImage(capturedImage);
    img.Image? decodedLogo = img.decodeImage(logo);

    if (decodedLogo != null) {
      bytes += generator.image(
        decodedLogo,
        align: PosAlign.center,
        isDoubleDensity: true,
      );
    }

    bytes += generator.text(
      '------------------------------------------------',
      styles: const PosStyles(
        bold: true,
        fontType: PosFontType.fontA,
        height: PosTextSize.size1,
      ),
    );

    if (decodedImage != null) {
      bytes += generator.image(
        decodedImage,
        align: PosAlign.center,
        isDoubleDensity: true,
      );
    }

    if (_isUSBPrinter) {
      _printEscPosUSB(bytes, generator);
    }
  }

  String _getFullAddress(String deviceAddress) {
    if (deviceAddress.length < 4) return '';

    // Ensure exactly 4 digits
    deviceAddress = deviceAddress.padLeft(4, '0');

    String first = deviceAddress.substring(0, 1);
    String last = deviceAddress.substring(2, 4);

    first = first.padLeft(3, '0');
    last = last.padLeft(3, '0');

    _fullAddress = "/dev/bus/usb/$first/$last";
    return _fullAddress;
  }

  /// Print USB
  void _printEscPosUSB(List<int> bytes, Generator generator) async {
    final printerInput = UsbPrinterInput(
      name: _printName,
      vendorId: _vendorId.toString(),
      productId: _productId.toString(),
      fullAddress: _fullAddress,
    );

    try {
      await _printerManagerUSB.connect(
        type: PrinterType.usb,
        model: printerInput,
      );

      bytes += generator.cut();

      await _printerManagerUSB.send(bytes: bytes, type: PrinterType.usb);
      await _printerManagerUSB.disconnect(type: PrinterType.usb);
    } catch (e) {
      log('❌ USB Print Error: $e');
    }
  }
}
