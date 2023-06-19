// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main() {
  runApp(const FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(color: Colors.lightBlue, home: MyWidget());
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final flutterReactiveBle = FlutterReactiveBle();
  final List<DiscoveredDevice> devices = [];
  StreamSubscription? subscription;
  final StreamController<BleScannerState> _stateStreamController =
      StreamController();

  bool isScan = false;

  @override
  void initState() {
    startScan();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.cleaning_services),
          onPressed: () {
            devices.clear();
            stopScan();
            print('devices number: ${devices.length}');
            print('stopped and clear devices');
            setState(() {});
          },
        ),
      ),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final d = devices[index];
          return Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: Column(
              children: [
                /// devices
                Row(
                  children: [
                    Text((index + 1).toString()),
                    Expanded(
                      child: ListTile(
                        title: Text(d.name == "" ? "No name" : d.name),
                        subtitle: Text(d.id),
                      ),
                    ),
                  ],
                ),
                index == devices.length - 1 && isScan
                    ? const CircularProgressIndicator()
                    : const SizedBox(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: isScan ? () => stopScan() : () => startScan(),
          child: isScan
              ? const Icon(
                  Icons.stop,
                  color: Colors.red,
                )
              : const Icon(Icons.search)),
    );
  }

  void _pushState() {
    _stateStreamController.add(
      BleScannerState(
        discoveredDevices: devices,
        scanIsInProgress: _subscription != null,
      ),
    );
  }

  startScan() {
    isScan = true;
    setState(() {});
    print('Start ble discovery');
    devices.clear();
    _subscription?.cancel();
    _subscription =
        flutterReactiveBle.scanForDevices(withServices: []).listen((device) {
      final knownDeviceIndex = devices.indexWhere((d) => d.id == device.id);
      if (knownDeviceIndex >= 0) {
        devices[knownDeviceIndex] = device;
      } else {
        devices.add(device);
      }
      _pushState();
      print(devices.length);
      setState(() {});
    }, onError: (Object e) => print('Device scan fails with error: $e'));
    _pushState();
  }

  Future<void> stopScan() async {
    isScan = false;
    setState(() {});
    print('Stop ble discovery');

    await _subscription?.cancel();
    _subscription = null;
    _pushState();
    print('devices number: ${devices.length}');
    print('stopped and clear devices');
  }

  @override
  Future<void> dispose() async {
    await _stateStreamController.close();
  }

  StreamSubscription? _subscription;
}

@immutable
class BleScannerState {
  const BleScannerState({
    required this.discoveredDevices,
    required this.scanIsInProgress,
  });

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;
}
