import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
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
          '${input.deviceId} Test Ticket',
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
      ..addAll(generator.feed(7));

    try {
      await printerManager.disconnect(type: PrinterType.usb);
      await printerManager.connect(type: PrinterType.usb, model: input);
      await printerManager.send(type: PrinterType.usb, bytes: bytes);
      await printerManager.disconnect(type: PrinterType.usb);
    } catch (e) {
      debugPrint("❌ Print error: $e");
    }
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
                      'إعادة تحميل',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
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

                  final fullAddress = posProvider.getFullAddress(
                    device.address!,
                  );

                  final currentInput = UsbPrinterInput(
                    name: device.name,
                    vendorId: device.vendorId,
                    productId: device.productId,
                    deviceId: fullAddress, 
                  );

                  final isSelected =
                      selectedInput?.vendorId == currentInput.vendorId &&
                      selectedInput?.productId == currentInput.productId &&
                      selectedInput?.deviceId == currentInput.deviceId;

                  final displayName =
                      '${device.name ?? "Printer"} (${device.address})';

                  return Card(
                    margin: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? Colors.green
                            : Colors.blue,
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.usb,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'vendorId: ${device.vendorId} - productId: ${device.productId}',
                      ),
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.green[700]
                              : Colors.blue,
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
                          await printerManager.disconnect(
                            type: PrinterType.usb,
                          );
                          await Future.delayed(
                            const Duration(milliseconds: 800),
                          );

                          posProvider.updateUSBPrinter(
                            printerManager: printerManager,
                            printName: currentInput.name ?? '',
                            vendorId:
                                int.tryParse(currentInput.vendorId ?? '') ?? -1,
                            productId:
                                int.tryParse(currentInput.productId ?? '') ??
                                -1,
                            address: fullAddress,
                            // address: currentInput.deviceId ?? '',
                          );
                          print("KKKKKKKKKKK ${fullAddress}");

                          final connected = await printerManager.connect(
                            type: PrinterType.usb,
                            model: currentInput,
                          );

                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("فشل الاتصال بالطابعة المحددة."),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            selectedInput = currentInput;
                          });

                          await _printTest(currentInput);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
