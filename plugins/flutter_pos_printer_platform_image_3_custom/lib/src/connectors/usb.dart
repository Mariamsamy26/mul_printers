import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pos_provider.dart';

class USBPrinterSetupWidget extends StatefulWidget {
  const USBPrinterSetupWidget({super.key});

  @override
  State<USBPrinterSetupWidget> createState() => _USBPrinterSetupWidgetState();
}

class _USBPrinterSetupWidgetState extends State<USBPrinterSetupWidget> {
  final PrinterManager printerManager = PrinterManager.instance;
  final List<PrinterDevice> devices = [];
  UsbPrinterInput? selectedInput;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getDeviceList();
  }

  Future<void> _getDeviceList() async {
    setState(() {
      isLoading = true;
      devices.clear();
    });

    printerManager
        .discovery(type: PrinterType.usb)
        .listen((device) {
          setState(() {
            devices.add(device);
          });
        })
        .onDone(() {
          setState(() {
            isLoading = false;
          });
        });
  }

  Future<void> _printTest(UsbPrinterInput input) async {
    final generator = Generator(
      PaperSize.mm58,
      await CapabilityProfile.load(name: 'XP-N160I'),
    );

    final now = DateTime.now();
    final formattedDateTime =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final bytes = <int>[]
      ..addAll(generator.setGlobalCodeTable('CP1252'))
      ..addAll(generator.feed(1))
      ..addAll(
        generator.text(
          '${input.fullAddress} Test Ticket',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
          ),
        ),
      )
      ..addAll(
        generator.text(
          'Time: $formattedDateTime',
          styles: const PosStyles(
            align: PosAlign.center,
            fontType: PosFontType.fontB,
          ),
        ),
      )
      ..addAll(generator.feed(9));

    try {
      await printerManager
        ..connect(type: PrinterType.usb, model: input)
        ..send(type: PrinterType.usb, bytes: bytes)
        ..disconnect(type: PrinterType.usb);
      debugPrint('Printed to ${input.name}');
    } catch (e) {
      debugPrint("Print error: $e");
    }
  }

  String _getDeviceKey(PrinterDevice device) {
    if (device.address != null && device.address!.isNotEmpty) {
      return 'printer_${device.address}';
    }
    return 'printer_${device.vendorId}_${device.productId}';
  }

  Future<void> _saveCustomPrinterName(String key, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, name);
  }

  Future<String?> _getCustomPrinterName(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<String> _getDisplayName(PrinterDevice device, int index) async {
    final customName = await _getCustomPrinterName(_getDeviceKey(device));
    return customName ?? '${device.name ?? "Printer"} ${device.address}';
  }

  Future<void> _showRenameDialog(PrinterDevice device) async {
    final key = _getDeviceKey(device);
    final currentName = await _getCustomPrinterName(key);
    final controller = TextEditingController(text: currentName ?? '');

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Rename Printer"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Custom printer name"),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () async {
                await _saveCustomPrinterName(key, controller.text.trim());
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final posProvider = Provider.of<PosProvider>(context);

    return Container(
      color: Colors.grey[200],
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: SizedBox(
                width: 200.w,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: _getDeviceList,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'اعاده تحميل',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (devices.isEmpty)
            Padding(
              padding: EdgeInsets.all(40.w),
              child: const Text(
                'اضغط اعاده تحميل للبحث عن الطابعات المتصله',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final currentInput = UsbPrinterInput(
                    name: device.name,
                    vendorId: device.vendorId,
                    productId: device.productId,
                    fullAddress: device.address,
                  );

                  final isSelected =
                      selectedInput?.vendorId == currentInput.vendorId &&
                      selectedInput?.productId == currentInput.productId &&
                      selectedInput?.fullAddress == currentInput.fullAddress;

                  return FutureBuilder<String>(
                    future: _getDisplayName(device, index),
                    builder: (context, snapshot) {
                      final displayName = snapshot.data ?? 'Loading...';

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16.w),
                          onLongPress: () => _showRenameDialog(device),
                          leading: CircleAvatar(
                            radius: 30.r,
                            backgroundColor: isSelected
                                ? Colors.green
                                : Colors.blue,
                            child: Icon(
                              isSelected ? Icons.check_circle : Icons.usb,
                              color: Colors.white,
                              size: 30.r,
                            ),
                          ),
                          title: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          ),
                          subtitle: Text(
                            'vendorId: ${device.vendorId} - productId: ${device.productId}',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? Colors.green[700]
                                  : Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            icon: Icon(
                              isSelected ? Icons.check : Icons.print,
                              color: Colors.white,
                            ),
                            label: Text(
                              isSelected ? 'تم التحديد' : 'اختبار الطباعة',
                              style: const TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              posProvider.updateUSBPrinter(
                                printerManager: printerManager,
                                printName: currentInput.name ?? '',
                                vendorId:
                                    int.tryParse(currentInput.vendorId ?? '') ??
                                    -1,
                                productId:
                                    int.tryParse(
                                      currentInput.productId ?? '',
                                    ) ??
                                    -1,
                                rawAddress: currentInput.fullAddress ?? '',
                              );
                              await _printTest(currentInput);
                              setState(() {
                                selectedInput = currentInput;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
