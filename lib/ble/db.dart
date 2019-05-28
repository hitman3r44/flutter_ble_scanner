import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabaseHelper {
  static final AppDatabaseHelper _singleton = AppDatabaseHelper._internal();
  static Database _db;

  factory AppDatabaseHelper() => _singleton;

  get db async {
    if (_db == null) {
      _db = await createDatabase();
    }

    return _db;
  }

  AppDatabaseHelper._internal();

  Future<Database> createDatabase() async {
    String databasesPath = await getDatabasesPath();
    String dbPath = join(databasesPath, 'my.db');
    var database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: _populateDb,
        onUpgrade: _onUpgrade
    );

    return database;
  }

  void _populateDb(Database db, int version) async {
    await db.execute(
        "CREATE TABLE BluetoothDevice(id VARCHAR UNIQUE,"
            " name TEXT, password TEXT)");
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute("DROP TABLE IF EXISTS BluetoothDevice");
    _populateDb(db, newVersion);
  }

  Future<String> saveDevice(BluetoothDevice device, String name, String password) async {
    var id = "${device.id.toString()}";
    Database database = await db;
    var list = await database.rawQuery("SELECT * FROM BluetoothDevice WHERE name = '$name' OR id='$id'");

    if (list.isNotEmpty) {
      return Future(() => "Error: Name or Device id must be unique");
    }

    Map<String, String> map = Map();
    map['id'] = id;
    map['name'] = name;
    map['password'] = password;

    var res = await database.insert("BluetoothDevice", map);

    if (res > 0) {
      return Future(() => "Successfully saved");
    } else {
      return Future(() => "Error: Something went wrong");
    }
  }

  Future<List<DeviceContainer>> getAllDevices() async {
    Database database = await db;
    var list = await database.rawQuery("SELECT * FROM BluetoothDevice");

    return Future(() {
      return list.map((keyValue) {
        var id = keyValue['id'];
        var name = keyValue['name'];

        return DeviceContainer(name, id);
      }).toList();
    });
  }

  Future<String> removeResult(BluetoothDevice device) async {
    var dbClient = await db;
    var id = "${device.id.toString()}";

    var res = await dbClient
        .rawDelete('DELETE FROM BluetoothDevice WHERE id = ?', [id]);

    if (res > 0) {
      return Future(() => "Successfully deleted");
    } else {
      return Future(() => "Error: Something went wrong");
    }
  }

  Future<String> updateDevice(BluetoothDevice device, String name, String password) async {
    var id = "${device.id.toString()}";
    Database database = await db;
    var list = await database.rawQuery("SELECT * FROM BluetoothDevice WHERE name = '$name'");
    var passwordList = await database.rawQuery("SELECT * FROM BluetoothDevice WHERE id = '$id' AND password = '$password'");

    if (list.isNotEmpty) {
      return Future(() => "Error: Name already given to another device");
    } else if (passwordList.isEmpty) {
      return Future(() => "Error: Password for device does not match");
    }

    Map<String, String> map = Map();
    map['id'] = id;
    map['name'] = name;
    map['password'] = password;

    var res = await database.update(
        "BluetoothDevice",
        map,
        where: "id = ?",
        whereArgs: <String>[id]
    );

    if (res > 0) {
      return Future(() => "Successfully updated");
    } else {
      return Future(() => "Error: Something went wrong");
    }
  }
}

class DeviceContainer {
  String name;
  String id;

  DeviceContainer(this.name, this.id);
}