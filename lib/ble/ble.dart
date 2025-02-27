import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'db.dart';
import 'widget.dart';

final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

void main() {
  runApp(new FlutterBlueApp());
}

class FlutterBlueApp extends StatefulWidget {
  FlutterBlueApp({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _FlutterBlueAppState createState() => new _FlutterBlueAppState();
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  FlutterBlue _flutterBlue = FlutterBlue.instance;

  /// Scanning
  StreamSubscription _scanSubscription;
  Map<DeviceIdentifier, ScanResult> scanResults = new Map();
  bool isScanning = false;

  /// State
  StreamSubscription _stateSubscription;
  BluetoothState state = BluetoothState.unknown;

  /// Device
  BluetoothDevice device;
  bool get isConnected => (device != null);
  StreamSubscription deviceConnection;
  StreamSubscription deviceStateSubscription;
  List<BluetoothService> services = new List();
  Map<Guid, StreamSubscription> valueChangedSubscriptions = {};
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;
  List<DeviceContainer> deviceContainers = List();
  AppDatabaseHelper _helper;

  @override
  void initState() {
    super.initState();
    // Immediately get the state of FlutterBlue
    _helper = AppDatabaseHelper();
    _helper.getAllDevices().then((devices) {
      deviceContainers = devices ?? List();
    });

    _flutterBlue.state.then((s) {
      setState(() {
        state = s;
      });
    });
    // Subscribe to state changes
    _stateSubscription = _flutterBlue.onStateChanged().listen((s) {
      setState(() {
        state = s;
      });
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
    super.dispose();
  }

  _startScan() async {
    _scanSubscription = _flutterBlue
        .scan(
      timeout: const Duration(seconds: 5),
      /*
      withServices: [
          new Guid('0000180F-0000-1000-8000-00805F9B34FB')
        ]*/
    )
        .listen((scanResult) {
      print('localName: ${scanResult.advertisementData.localName}');
      print(
          'manufacturerData: ${scanResult.advertisementData.manufacturerData}');
      print('serviceData: ${scanResult.advertisementData.serviceData}');

      setState(() {
        scanResults[scanResult.device.id] = scanResult;
      });
    }, onDone: _stopScan);

    setState(() {
      isScanning = true;
    });
  }

  _stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    //TODO: Modify here for list cute name
    setState(() {
      isScanning = false;
    });
  }

  _connect(BluetoothDevice d) async {
    device = d;
    // Connect to device
    deviceConnection = _flutterBlue
        .connect(device, timeout: const Duration(seconds: 4))
        .listen(
          null,
//      onDone: _disconnect,
        );

    // Update the connection state immediately
    device.state.then((s) {
      setState(() {
        deviceState = s;
      });
    });

    // Subscribe to connection changes
    deviceStateSubscription = device.onStateChanged().listen((s) {
      setState(() {
        deviceState = s;
      });
      if (s == BluetoothDeviceState.connected) {
        device.discoverServices().then((s) {
          setState(() {
            services = s;
          });
        });
      }
    });
  }

  _disconnect() {
    // Remove all value changed listeners
    valueChangedSubscriptions.forEach((uuid, sub) => sub.cancel());
    valueChangedSubscriptions.clear();
    deviceStateSubscription?.cancel();
    deviceStateSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
    setState(() {
      device = null;
    });
  }

  _readCharacteristic(BluetoothCharacteristic c) async {
    await device.readCharacteristic(c);
    setState(() {});
  }

  _writeCharacteristic(BluetoothCharacteristic c) async {
    await device.writeCharacteristic(c, [0x12, 0x34],
        type: CharacteristicWriteType.withResponse);
    setState(() {});
  }

  _readDescriptor(BluetoothDescriptor d) async {
    await device.readDescriptor(d);
    setState(() {});
  }

  _writeDescriptor(BluetoothDescriptor d) async {
    await device.writeDescriptor(d, [0x12, 0x34]);
    setState(() {});
  }

  _setNotification(BluetoothCharacteristic c) async {
    if (c.isNotifying) {
      await device.setNotifyValue(c, false);
      // Cancel subscription
      valueChangedSubscriptions[c.uuid]?.cancel();
      valueChangedSubscriptions.remove(c.uuid);
    } else {
      await device.setNotifyValue(c, true);
      // ignore: cancel_subscriptions
      final sub = device.onValueChanged(c).listen((d) {
        setState(() {
          print('onValueChanged $d');
        });
      });
      // Add to map
      valueChangedSubscriptions[c.uuid] = sub;
    }
    setState(() {});
  }

  _refreshDeviceState(BluetoothDevice d) async {
    var state = await d.state;
    setState(() {
      deviceState = state;
      print('State refreshed: $deviceState');
    });
  }

  _buildScanningButton() {
    if (isConnected || state != BluetoothState.on) {
      return null;
    }
    if (isScanning) {
      return new FloatingActionButton(
        child: new Icon(Icons.stop),
        onPressed: _stopScan,
        backgroundColor: Colors.red,
      );
    } else {
      return new FloatingActionButton(
          child: new Icon(Icons.search), onPressed: _startScan);
    }
  }

  void _refresh() async {
    var dc = await _helper.getAllDevices();

    setState(() {
      deviceContainers = dc;
    });
  }

  _buildScanResultTiles() {
    return scanResults.values
        .map((r) => ScanResultTile(
              result: r,
              devices: deviceContainers,
              refresh: _refresh,
              onTap: () {
                return _connect(r.device);
              },
            ))
        .toList();
  }

  List<Widget> _buildServiceTiles() {
    return services
        .map(
          (s) => new ServiceTile(
                service: s,
                characteristicTiles: s.characteristics
                    .map(
                      (c) => new CharacteristicTile(
                            device: device,
                            isUpdatable: _isUpdatable(),
                            refreshCallback: _refresh,
                            characteristic: c,
                            onReadPressed: () => _readCharacteristic(c),
                            onWritePressed: () => _writeCharacteristic(c),
                            onNotificationPressed: () => _setNotification(c),
                            descriptorTiles: c.descriptors
                                .map(
                                  (d) => new DescriptorTile(
                                        descriptor: d,
                                        onReadPressed: () => _readDescriptor(d),
                                        onWritePressed: () =>
                                            _writeDescriptor(d),
                                      ),
                                )
                                .toList(),
                          ),
                    )
                    .toList(),
              ),
        )
        .toList();
  }

  _buildActionButtons() {
    if (isConnected) {
      return <Widget>[
        new IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () => _disconnect(),
        )
      ];
    }
  }

  _buildAlertTile() {
    return new Container(
      color: Colors.redAccent,
      child: new ListTile(
        title: new Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: new Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subhead.color,
        ),
      ),
    );
  }

  bool _isUpdatable() {
    var _isPresent = deviceContainers
            .indexWhere((container) => container.id == device.id.toString()) >=
        0;

    return _isPresent;
  }

  String _getTitle() {
    var index = deviceContainers
        .indexWhere((container) => container.id == device.id.toString());

    return index >= 0 ? deviceContainers[index].name : null;
  }

  // Second State
  _buildDeviceStateTile(BuildContext context) {
    return new ListTile(
        onTap: () {
          showDialog(
              context: navKey.currentState.overlay.context,
              builder: (BuildContext _) {
                var nameController = TextEditingController();
                var passwordController = TextEditingController();
                var passwordValidateController = TextEditingController();

                return AlertDialog(
                  title: Text("Save Custom Name"),
                  content: CreateDialogBody(nameController, passwordController,
                      passwordValidateController),
                  actions: <Widget>[
                    if (_isUpdatable())
                      FlatButton(
                        child: const Text('DELETE'),
                        onPressed: () async {
                          var helper = AppDatabaseHelper();
                          var msg = await helper.removeResult(device);

                          scaffoldKey.currentState.showSnackBar(SnackBar(
                            content: Text(msg),
                            duration: Duration(seconds: 5),
                          ));

                          Timer(Duration(seconds: 5), () {
                            scaffoldKey.currentState.removeCurrentSnackBar();
                          });

                          _refresh();

                          Navigator.of(_).pop();
                        },
                      ),
                    FlatButton(
                        child: const Text('ACCEPT'),
                        onPressed: () async {
                          var helper = AppDatabaseHelper();
                          if (nameController.text.isEmpty ||
                              passwordController.text.isEmpty ||
                              passwordValidateController.text.isEmpty) {
                            scaffoldKey.currentState.showSnackBar(SnackBar(
                                duration: Duration(milliseconds: 5),
                                content: Text("All fields are required")));
                            Timer(Duration(seconds: 5), () {
                              scaffoldKey.currentState.removeCurrentSnackBar();
                            });

                            return;
                          } else if (passwordController.text !=
                              passwordValidateController.text) {
                            scaffoldKey.currentState.showSnackBar(SnackBar(
                                duration: Duration(milliseconds: 5),
                                content: Text("Password fields do not match")));
                            Timer(Duration(seconds: 5), () {
                              scaffoldKey.currentState.removeCurrentSnackBar();
                            });

                            return;
                          }

                          var msg;
                          if (!_isUpdatable()) {
                            msg = await helper.saveDevice(device,
                                nameController.text, passwordController.text);
                          } else {
                            msg = await helper.updateDevice(device,
                                nameController.text, passwordController.text);
                          }

                          scaffoldKey.currentState.showSnackBar(SnackBar(
                            content: Text(msg),
                            duration: Duration(seconds: 5),
                          ));

                          Timer(Duration(seconds: 5), () {
                            scaffoldKey.currentState.removeCurrentSnackBar();
                          });
                          _refresh();
                          if (!msg.contains("Error")) {
                            Navigator.of(_).pop();
                          }
                        })
                  ],
                );
              });
        },
        leading: (deviceState == BluetoothDeviceState.connected)
            ? const Icon(Icons.bluetooth_connected)
            : const Icon(Icons.bluetooth_disabled),
        title: new Text('Device is ${deviceState.toString().split('.')[1]}.'),
        subtitle: new Text('${_getTitle() ?? device.name}'),
        trailing: new IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _refreshDeviceState(device),
          color: Theme.of(context).iconTheme.color.withOpacity(0.5),
        ));
  }

  _buildProgressBarTile() {
    return new LinearProgressIndicator();
  }

  static final navKey = new GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    var tiles = new List<Widget>();
    if (state != BluetoothState.on) {
      tiles.add(_buildAlertTile());
    }
    if (isConnected) {
      tiles.add(_buildDeviceStateTile(context));
      tiles.addAll(_buildServiceTiles());
    } else {
      tiles.addAll(_buildScanResultTiles());
    }
    return new MaterialApp(
      navigatorKey: navKey,
      home: new Scaffold(
        key: scaffoldKey,
        appBar: new AppBar(
          title: const Text('BLE Apllication'),
          actions: _buildActionButtons(),
        ),
        floatingActionButton: _buildScanningButton(),
        body: new Stack(
          children: <Widget>[
            (isScanning) ? _buildProgressBarTile() : new Container(),
            new ListView(
              children: tiles,
            )
          ],
        ),
      ),
    );
  }
}
