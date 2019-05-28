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

  Future<String> saveDevice(ScanResult result, String name, String password) async {
    var id = "${result.device.id.toString()}-$name";
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
        var id = keyValue['id'].toString().split("-")[0];
        var name = keyValue['id'].toString().split("-")[1];

        return DeviceContainer(name, id);
      }).toList();
    });
  }
}

class DeviceContainer {
  String name;
  String id;

  DeviceContainer(this.name, this.id);
}