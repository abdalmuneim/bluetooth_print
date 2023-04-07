import 'dart:convert';
import 'dart:developer';

import 'package:blue_print_pos/blue_print_pos.dart';
import 'package:blue_print_pos/models/models.dart';
import 'package:blue_print_pos/receipt/receipt.dart';
import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/src/enums.dart';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BluePrintPos _bluePrintPos = BluePrintPos.instance;
  List<BlueDevice> _blueDevices = <BlueDevice>[];
  BlueDevice? _selectedDevice;
  bool _isLoading = false;
  int _loadingAtIndex = -1;
  PaperSize paperSize = PaperSize.mm58;

  @override
  Widget build(BuildContext context) {
    return Sizer(builder:
        (BuildContext context, Orientation orientation, DeviceType deviceType) {
      return GetMaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Blue Print Pos'), actions: [
            DropdownButton<PaperSize>(
              hint: const Text('selecte printer size'),
              items: const <DropdownMenuItem<PaperSize>>[
                DropdownMenuItem(
                  value: PaperSize.mm58,
                  child: Text('mm58'),
                ),
                DropdownMenuItem(
                  value: PaperSize.mm72,
                  child: Text('mm72'),
                ),
                DropdownMenuItem(
                  value: PaperSize.mm80,
                  child: Text('mm80'),
                ),
              ],
              value: paperSize,
              onChanged: (PaperSize? value) {
                setState(() {
                  paperSize = value!;
                });
              },
            ),
          ]),
          body: SafeArea(
            child: _isLoading && _blueDevices.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                : _blueDevices.isNotEmpty
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Column(
                              children: List<Widget>.generate(
                                  _blueDevices.length, (int index) {
                                return Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _blueDevices[index].address ==
                                                (_selectedDevice?.address ?? '')
                                            ? _onDisconnectDevice
                                            : () => _onSelectDevice(index),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                _blueDevices[index].name,
                                                style: TextStyle(
                                                  color: _selectedDevice
                                                              ?.address ==
                                                          _blueDevices[index]
                                                              .address
                                                      ? Colors.blue
                                                      : Colors.black,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                _blueDevices[index].address,
                                                style: TextStyle(
                                                  color: _selectedDevice
                                                              ?.address ==
                                                          _blueDevices[index]
                                                              .address
                                                      ? Colors.blueGrey
                                                      : Colors.grey,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_loadingAtIndex == index && _isLoading)
                                      Container(
                                        height: 24.0,
                                        width: 24.0,
                                        margin:
                                            const EdgeInsets.only(right: 8.0),
                                        child: const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.blue,
                                          ),
                                        ),
                                      ),
                                    if (!_isLoading &&
                                        _blueDevices[index].address ==
                                            (_selectedDevice?.address ?? ''))
                                      TextButton(
                                        onPressed: _onPrintReceipt,
                                        style: ButtonStyle(
                                          backgroundColor: MaterialStateProperty
                                              .resolveWith<Color>(
                                            (Set<MaterialState> states) {
                                              if (states.contains(
                                                  MaterialState.pressed)) {
                                                return Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.5);
                                              }
                                              return Theme.of(context)
                                                  .primaryColor;
                                            },
                                          ),
                                        ),
                                        child: Container(
                                          color: _selectedDevice == null
                                              ? Colors.grey
                                              : Colors.blue,
                                          padding: const EdgeInsets.all(8.0),
                                          child: const Text(
                                            'Test Print',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            Text(
                              'Scan bluetooth device',
                              style:
                                  TextStyle(fontSize: 24, color: Colors.blue),
                            ),
                            Text(
                              'Press button scan',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _isLoading ? null : _onScanPressed,
            backgroundColor: _isLoading ? Colors.grey : Colors.blue,
            child: const Icon(Icons.search),
          ),
        ),
      );
    });
  }

  Future<void> _onScanPressed() async {
    log('---------- Width: ${50.w}');
    log('---------- Width MediaQ: ${Get.width}');

    setState(() => _isLoading = true);
    _bluePrintPos.scan().then((List<BlueDevice> devices) {
      if (devices.isNotEmpty) {
        setState(() {
          _blueDevices = devices;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  void _onDisconnectDevice() {
    _bluePrintPos.disconnect().then((ConnectionStatus status) {
      if (status == ConnectionStatus.disconnect) {
        setState(() {
          _selectedDevice = null;
        });
      }
    });
  }

  void _onSelectDevice(int index) {
    setState(() {
      _isLoading = true;
      _loadingAtIndex = index;
    });
    final BlueDevice blueDevice = _blueDevices[index];
    _bluePrintPos.connect(blueDevice).then((ConnectionStatus status) {
      if (status == ConnectionStatus.connected) {
        setState(() => _selectedDevice = blueDevice);
      } else if (status == ConnectionStatus.timeout) {
        _onDisconnectDevice();
      } else {
        print('$runtimeType - something wrong');
      }
      setState(() => _isLoading = false);
    });
  }

  Future<void> _onPrintReceipt() async {
    /// Example for Print Image
    final ByteData logoBytes = await rootBundle.load(
      'assets/logo.png',
    );
    const String qrURL =
        "https://cdn.britannica.com/17/155017-050-9AC96FC8/Example-QR-code.jpg";
    Uint8List qrBytes = (await NetworkAssetBundle(Uri.parse(qrURL)).load(qrURL))
        .buffer
        .asUint8List();

    /// Example for Print Text
    final ReceiptSectionText receiptText = ReceiptSectionText();

    receiptText.addImage(
      base64.encode(Uint8List.view(logoBytes.buffer)),
      width: imageSize,
    );

    receiptText.addText(
      'فاتورة ضريبية مبسطة',
      alignment: ReceiptAlignment.center,
      size: ReceiptTextSizeType.large,
      style: ReceiptTextStyleType.bold,
    );
    receiptText.addText(
      'Os-121212121221#رقم الطلب',
      size: ReceiptTextSizeType.medium,
      style: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer();
    receiptText.addText(
      'الطازج',
      size: ReceiptTextSizeType.medium,
      style: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer();
    receiptText.addText(
      'العنوان',
      size: ReceiptTextSizeType.medium,
      style: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer();

    receiptText.addLeftRightText(
      '',
      getTime(),
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addLeftRightText(
      '',
      'رقم التسجيل الضريبي:12132312',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer();
    receiptText.addLeftRightText(
      'الاجمالي',
      'الطلب',
      leftStyle: ReceiptTextStyleType.bold,
      leftSize: ReceiptTextSizeType.medium,
    );
    final List<void> l = List.generate(
      3,
      (index) => receiptText.addLeftRightText(
        '٣٠ر.س',
        '٣٠x ٢ x وجبة فروج',
        leftStyle: ReceiptTextStyleType.bold,
        leftSize: ReceiptTextSizeType.medium,
      ),
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      '٦٠ر.س',
      'اجمالي الطلبات',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.normal,
    );
    receiptText.addLeftRightText(
      '٣٠ر.س',
      'ضريبة القيمة المضافة(15%)',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.normal,
    );

    receiptText.addLeftRightText(
      '٣٠ر.س',
      'اجمالي الطلبات شامل الضريبة',
      leftStyle: ReceiptTextStyleType.bold,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      '٣٠ر.س',
      'الاجمالي الكل',
      leftStyle: ReceiptTextStyleType.bold,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'بطاقة',
      'طريقة الدفع',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer();
    receiptText.addText(
      '(Drive Through)استعلام في الشباك',
      size: ReceiptTextSizeType.medium,
      alignment: ReceiptAlignment.right,
      style: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer(count: 1);

    /// printer QR
    receiptText.addImage(
      base64.encode(Uint8List.view(qrBytes.buffer)),
      width: imageSize,
    );

    receiptText.addSpacer(count: 3);

    /// print data
    await _bluePrintPos.printReceiptText(
      receiptText,
      height: paperSize == PaperSize.mm80
          ? heightMM80(l.length)
          : paperSize == PaperSize.mm58
              ? heightMM58(l.length)
              : heightMM72(l.length),
      paperSize: paperSize,
      useCut: false,
      useRaster: false,
      feedCount: 0,
    );
  }

  double heightMM58(int l) {
    var logoAndQrHeight = 90;
    var headerAndFooterRowCount = 20;
    var rowHeight = 50;
    return (logoAndQrHeight +
            headerAndFooterRowCount * rowHeight +
            l * rowHeight)
        .toDouble();
  }

  double heightMM72(int l) {
    return (120 + 20 * 40 + l * 40);
  }

  double heightMM80(int l) {
    double h = 140 + 20 * 50 + l * 55;
    log('offset H: $h');
    return (h);
  }

  String getTime() {
    final dbTimeKey = DateTime.now()
        .toString()
        .replaceRange(19, 26, '')
        .replaceAll(' ', '     ');
    return dbTimeKey;
  }

  int get imageSize => paperSize == PaperSize.mm58
      ? 120
      : paperSize == PaperSize.mm72
          ? 120
          : 170;
}
