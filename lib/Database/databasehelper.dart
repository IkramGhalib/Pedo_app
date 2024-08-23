import 'dart:io';

import 'package:meter_reading/models/contactinfomodel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class SqfliteDatabaseHelper {
  SqfliteDatabaseHelper.internal();
  static final SqfliteDatabaseHelper instance =
      SqfliteDatabaseHelper.internal();
  factory SqfliteDatabaseHelper() => instance;

  static const data_reading1 = 'data_reading1';
  static const local_meters = 'local_meters';
  static const user_groups = 'user_groups';

  static const _version = 1;

  Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String dbPath = p.join(directory.path, 'pedo.db');
    print(dbPath);
    var openDb = await openDatabase(
      dbPath,
      version: _version,
      onCreate: (Database db, int version) async {
        await db.execute("""
        CREATE TABLE data_reading1 (  
          refNo INTEGER PRIMARY KEY,
          meterNo INTEGER,
          cmId INTEGER,
          curReading INTEGER,
          preReading INTEGER,
          status TEXT,
          offPeak TEXT,
          peakImage TEXT,
          offPeakImage TEXT,
          monthYear TEXT
          )""");

        await db.execute("""
        CREATE TABLE local_meters (  
          refNo INTEGER PRIMARY KEY,
          preReading INTEGER,
          cmId INTEGER,
          meterNo INTEGER
          )""");

        await db.execute("""
        CREATE TABLE user_groups (  
          refStart INTEGER,
          refEnd INTEGER          
          )""");
      },
      onUpgrade: (Database db, int oldversion, int newversion) async {
        if (oldversion < newversion) {
          print("Version Upgrade");
        }
      },
    );
    return openDb;
  }

  static void save(ContactinfoModel photo) {}
}
