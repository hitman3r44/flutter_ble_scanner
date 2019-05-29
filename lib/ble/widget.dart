import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'ble.dart';
import 'db.dart';

class ScanResultTile extends StatelessWidget {
  ScanResultTile({Key key, this.result, this.devices, this.onTap, this.refresh})
      : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;
  final VoidCallback refresh;
  final List<DeviceContainer> devices;
  var _isPresent;

  var nameController = TextEditingController();
  var passwordController = TextEditingController();
  var passwordValidateController = TextEditingController();

  String _getTitle() {
    var index = devices
        .indexWhere((container) => container.id == result.device.id.toString());

    return index >= 0 ? devices[index].name : null;
  }

  bool _isUpdatable() {
    _isPresent = devices.indexWhere(
            (container) => container.id == result.device.id.toString()) >=
        0;

    return _isPresent;
  }

  Widget _buildTitle(BuildContext context) {
    var customName = _getTitle();

    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(customName ?? result.device.name),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(customName ?? result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    // Showing the Information of Scanned Devices
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
            context: context,
            builder: (BuildContext _) {
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
                        var msg = await helper.removeResult(result.device);

                        scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text(msg),
                          duration: Duration(seconds: 5),
                        ));

                        Timer(Duration(seconds: 5), () {
                          scaffoldKey.currentState.removeCurrentSnackBar();
                        });

                        refresh();

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
                          msg = await helper.saveDevice(result.device,
                              nameController.text, passwordController.text);
                        } else {
                          msg = await helper.updateDevice(result.device,
                              nameController.text, passwordController.text);
                        }

                        scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text(msg),
                          duration: Duration(seconds: 5),
                        ));

                        Timer(Duration(seconds: 5), () {
                          scaffoldKey.currentState.removeCurrentSnackBar();
                        });
                        refresh();
                        if (!msg.contains("Error")) {
                          Navigator.of(_).pop();
                        }
                      })
                ],
              );
            });
      },
      child: ExpansionTile(
        title: _buildTitle(context),
        leading: Text(result.rssi.toString()),
        trailing: RaisedButton(
          child: Text(_isUpdatable() ? 'EDIT' : 'CONNECT'),
          color: Colors.black,
          textColor: Colors.white,
          onPressed: (result.advertisementData.connectable)
              ? () {
                  if (_isUpdatable()) {
                    showDialog(
                        context: context,
                        builder: (BuildContext _) {
                          return AlertDialog(
                            title: Text("Give password"),
                            content: TextField(
                              controller: passwordController,
                              obscureText: true,
                            ),
                            actions: <Widget>[
                              FlatButton(
                                child: Text("Validate"),
                                onPressed: () async {
                                  AppDatabaseHelper helper =
                                      AppDatabaseHelper();
                                  if (await helper.validatePassword(
                                      result.device, passwordController.text)) {
                                    Navigator.of(_).pop();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => PasswordScreen(
                                              result,
                                              <Widget>[
                                                _buildAdvRow(
                                                    context,
                                                    'Complete Local Name',
                                                    result.advertisementData
                                                            .localName ??
                                                        'N/A'),
                                                _buildAdvRow(
                                                    context,
                                                    'Tx Power Level',
                                                    '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
                                                _buildAdvRow(
                                                    context,
                                                    'Manufacturer Data',
                                                    getNiceManufacturerData(result
                                                            .advertisementData
                                                            .manufacturerData) ??
                                                        'N/A'),
                                                _buildAdvRow(
                                                    context,
                                                    'Service UUIDs',
                                                    (result
                                                            .advertisementData
                                                            .serviceUuids
                                                            .isNotEmpty)
                                                        ? result
                                                            .advertisementData
                                                            .serviceUuids
                                                            .join(', ')
                                                            .toUpperCase()
                                                        : 'N/A'),
                                                _buildAdvRow(
                                                    context,
                                                    'Service Data',
                                                    getNiceServiceData(result
                                                            .advertisementData
                                                            .serviceData) ??
                                                        'N/A'),
                                              ],
                                              _isUpdatable(),
                                              refresh)),
                                    );
                                  } else {
                                    scaffoldKey.currentState
                                        .showSnackBar(SnackBar(
                                      content: Text("Password Invalid"),
                                      duration: Duration(seconds: 5),
                                    ));

                                    Timer(Duration(seconds: 5), () {
                                      scaffoldKey.currentState
                                          .removeCurrentSnackBar();
                                    });
                                  }
                                },
                              )
                            ],
                          );
                        });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PasswordScreen(
                              result,
                              <Widget>[
                                _buildAdvRow(
                                    context,
                                    'Complete Local Name',
                                    result.advertisementData.localName ??
                                        'N/A'),
                                _buildAdvRow(context, 'Tx Power Level',
                                    '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
                                _buildAdvRow(
                                    context,
                                    'Manufacturer Data',
                                    getNiceManufacturerData(result
                                            .advertisementData
                                            .manufacturerData) ??
                                        'N/A'),
                                _buildAdvRow(
                                    context,
                                    'Service UUIDs',
                                    (result.advertisementData.serviceUuids
                                            .isNotEmpty)
                                        ? result.advertisementData.serviceUuids
                                            .join(', ')
                                            .toUpperCase()
                                        : 'N/A'),
                                _buildAdvRow(
                                    context,
                                    'Service Data',
                                    getNiceServiceData(result
                                            .advertisementData.serviceData) ??
                                        'N/A'),
                              ],
                              _isUpdatable(),
                              refresh)),
                    );
                  }
                }
              : null,
        ),
        children: <Widget>[
          _buildAdvRow(context, 'Complete Local Name',
              result.advertisementData.localName ?? 'N/A'),
          _buildAdvRow(context, 'Tx Power Level',
              '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
          _buildAdvRow(
              context,
              'Manufacturer Data',
              getNiceManufacturerData(
                      result.advertisementData.manufacturerData) ??
                  'N/A'),
          _buildAdvRow(
              context,
              'Service UUIDs',
              (result.advertisementData.serviceUuids.isNotEmpty)
                  ? result.advertisementData.serviceUuids
                      .join(', ')
                      .toUpperCase()
                  : 'N/A'),
          _buildAdvRow(
              context,
              'Service Data',
              getNiceServiceData(result.advertisementData.serviceData) ??
                  'N/A'),
        ],
      ),
    );
  }
}

class CreateDialogBody extends StatelessWidget {
  TextEditingController nameController;
  TextEditingController passwordController;
  TextEditingController passwordValidateController;

  CreateDialogBody(this.nameController, this.passwordController,
      this.passwordValidateController);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: "Custom name for device")),
        TextField(
            obscureText: true,
            controller: passwordController,
            decoration: InputDecoration(hintText: "Password for device")),
        TextField(
            obscureText: true,
            controller: passwordValidateController,
            decoration: InputDecoration(hintText: "Re-enter password"))
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile({Key key, this.service, this.characteristicTiles})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (characteristicTiles.length > 0) {
      return new ExpansionTile(
        title: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Service'),
            new Text(
                '0x${service.uuid.toString().toUpperCase().substring(4, 8)}',
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: Theme.of(context).textTheme.caption.color))
          ],
        ),
        children: characteristicTiles,
      );
    } else {
      return new ListTile(
        title: const Text('Service'),
        subtitle: new Text(
            '0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
      );
    }
  }
}

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;
  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;
  final VoidCallback onNotificationPressed;

  final BluetoothDevice device;
  final bool isUpdatable;
  final VoidCallback refreshCallback;

  const CharacteristicTile(
      {Key key,
      this.device,
      this.isUpdatable,
      this.refreshCallback,
      this.characteristic,
      this.descriptorTiles,
      this.onReadPressed,
      this.onWritePressed,
      this.onNotificationPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var actions = new Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new IconButton(
          icon: new Icon(
            Icons.file_download,
            color: Theme.of(context).iconTheme.color.withOpacity(0.5),
          ),
          onPressed: onReadPressed,
        ),
        new IconButton(
          icon: new Icon(Icons.file_upload,
              color: Theme.of(context).iconTheme.color.withOpacity(0.5)),
          onPressed: onWritePressed,
        ),
        new IconButton(
          icon: new Icon(
              characteristic.isNotifying ? Icons.sync_disabled : Icons.sync,
              color: Theme.of(context).iconTheme.color.withOpacity(0.5)),
          onPressed: onNotificationPressed,
        )
      ],
    );

    var title = new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Characteristic'),
        new Text(
            '0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}',
            style: Theme.of(context)
                .textTheme
                .body1
                .copyWith(color: Theme.of(context).textTheme.caption.color))
      ],
    );

    if (descriptorTiles.length > 0) {
      return gestureListenerWidget(
          new ExpansionTile(
            title: new ListTile(
              title: title,
              subtitle: new Text(characteristic.value.toString()),
            ),
            trailing: actions,
            children: descriptorTiles,
          ),
          context);
    } else {
      return gestureListenerWidget(
          new ListTile(
            title: title,
            subtitle: new Text(characteristic.value.toString()),
            trailing: actions,
          ),
          context);
    }
  }

  Widget gestureListenerWidget(Widget child, BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
            context: context,
            builder: (BuildContext _) {
              var nameController = TextEditingController();
              var passwordController = TextEditingController();
              var passwordValidateController = TextEditingController();

              return AlertDialog(
                title: Text("Save Custom Name"),
                content: CreateDialogBody(nameController, passwordController,
                    passwordValidateController),
                actions: <Widget>[
                  if (isUpdatable)
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

                        refreshCallback();

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
                        if (!isUpdatable) {
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
                        refreshCallback();
                        if (!msg.contains("Error")) {
                          Navigator.of(_).pop();
                        }
                      })
                ],
              );
            });
      },
      child: child,
    );
  }
}

class DescriptorTile extends StatelessWidget {
  final BluetoothDescriptor descriptor;
  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;

  const DescriptorTile(
      {Key key, this.descriptor, this.onReadPressed, this.onWritePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var title = new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Descriptor'),
        new Text(
            '0x${descriptor.uuid.toString().toUpperCase().substring(4, 8)}',
            style: Theme.of(context)
                .textTheme
                .body1
                .copyWith(color: Theme.of(context).textTheme.caption.color))
      ],
    );
    return new ListTile(
      title: new ListTile(
        title: title,
        subtitle: new Text(descriptor.value.toString()),
        trailing: new Row(
          children: <Widget>[
            new IconButton(
              icon: new Icon(
                Icons.file_download,
                color: Theme.of(context).iconTheme.color.withOpacity(0.5),
              ),
              onPressed: onReadPressed,
            ),
            new IconButton(
              icon: new Icon(
                Icons.file_upload,
                color: Theme.of(context).iconTheme.color.withOpacity(0.5),
              ),
              onPressed: onWritePressed,
            )
          ],
        ),
      ),
    );
  }
}

class PasswordScreen extends StatefulWidget {
  ScanResult _result;
  List<Widget> _list;
  bool _isUpdatable;
  VoidCallback _refresh;

  PasswordScreen(this._result, this._list, this._isUpdatable, this._refresh);

  @override
  _PasswordScreenState createState() =>
      _PasswordScreenState(_result, _list, _isUpdatable, _refresh);
}

final passwordScreenScaffoldKey = GlobalKey<ScaffoldState>();

class _PasswordScreenState extends State<PasswordScreen> {
  ScanResult _result;
  List<Widget> _list;
  bool _isUpdatable;
  VoidCallback _refresh;

  var nameController = TextEditingController();
  var passwordController = TextEditingController();
  var passwordValidateController = TextEditingController();

  _PasswordScreenState(
      this._result, this._list, this._isUpdatable, this._refresh);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: passwordScreenScaffoldKey,
      appBar: AppBar(
        title: Text("Save Device"),
      ),
      body: SingleChildScrollView(
        child: Column(children: <Widget>[
          ..._list,
          Container(
            height: 20,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hasFloatingPlaceholder: true,
                  labelText: "Give Custom Name for Device",
                  border: OutlineInputBorder()
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                  hasFloatingPlaceholder: true,
                  labelText: "Give password for Device",
                  border: OutlineInputBorder()
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: passwordValidateController,
              obscureText: true,
              decoration: InputDecoration(
                  hasFloatingPlaceholder: true,
                  labelText: "Re-enter password",
                  border: OutlineInputBorder()
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (_isUpdatable)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      child: Text("DELETE"),
                      onPressed: () async {
                        var helper = AppDatabaseHelper();
                        var msg = await helper.removeResult(_result.device);

                        passwordScreenScaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text(msg),
                          duration: Duration(seconds: 5),
                        ));

                        _refresh();

                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                      child: Text("SUBMIT"),
                      onPressed: () async {
                        var helper = AppDatabaseHelper();
                        if (nameController.text.isEmpty ||
                            passwordController.text.isEmpty ||
                            passwordValidateController.text.isEmpty) {
                          passwordScreenScaffoldKey.currentState.showSnackBar(
                              SnackBar(
                                  duration: Duration(seconds: 5),
                                  content: Text("All fields are required")));

                          return;
                        } else if (passwordController.text !=
                            passwordValidateController.text) {
                          passwordScreenScaffoldKey.currentState.showSnackBar(
                              SnackBar(
                                  duration: Duration(seconds: 5),
                                  content:
                                      Text("Password fields do not match")));

                          return;
                        }

                        var msg;
                        if (!_isUpdatable) {
                          msg = await helper.saveDevice(_result.device,
                              nameController.text, passwordController.text);
                        } else {
                          msg = await helper.updateDevice(_result.device,
                              nameController.text, passwordController.text);
                        }

                        passwordScreenScaffoldKey.currentState
                            .showSnackBar(SnackBar(
                          content: Text(msg),
                          duration: Duration(seconds: 5),
                        ));

                        _refresh();

                        if (!msg.contains("Error")) {
                          Navigator.of(context).pop();
                        }
                      }),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularToggleButton("Open", Colors.greenAccent, null),
                )),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:
                      CircularToggleButton("Close", Colors.yellowAccent, null),
                )),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularToggleButton("Stop", Colors.redAccent, null),
                )),
              ],
            ),
          )
        ]),
      ),
    );
  }
}

class CircularToggleButton extends StatefulWidget {
  String _text;
  Color _toggleColor;
  VoidCallback _optionalCallback;

  CircularToggleButton(this._text, this._toggleColor, this._optionalCallback);

  @override
  _CircularToggleButtonState createState() =>
      _CircularToggleButtonState(_text, _toggleColor, _optionalCallback);
}

class _CircularToggleButtonState extends State<CircularToggleButton> {
  String _text;
  Color _toggleColor;
  VoidCallback _optionalCallback;

  bool _isToggledOn = false;
  final Color _defaultColor = Colors.grey;

  _CircularToggleButtonState(
      this._text, this._toggleColor, this._optionalCallback);

  @override
  void initState() {
    super.initState();
    _isToggledOn = false;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: GestureDetector(
      onTap: () {
        if (_optionalCallback != null) {
          _optionalCallback();
        }

        setState(() {
          _isToggledOn = !_isToggledOn;
        });
      },
      child: ClipOval(
        child: Container(
          color: _isToggledOn ? _toggleColor : _defaultColor,
          height: 120.0, // height of the button
          width: 120.0, // width of the button
          child: Center(child: Text(_text)),
        ),
      ),
    ));
  }
}
