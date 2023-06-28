import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/label.dart';
import '../models/station.dart';

const databaseVersion = 2;
const databaseName = 'Sonore.sqlite3';
const tableLabels = 'labels';
const tableStations = 'stations';
const sqlCreateLabels = 'CREATE TABLE $tableLabels ('
    'id INTEGER PRIMARY KEY,'
    'position INTEGER,'
    'name TEXT UNIQUE,'
    'info TEXT)';
const sqlCreateStations = 'CREATE TABLE $tableStations ('
    'uuid TEXT UNIQUE,'
    'name TEXT,'
    'url TEXT,'
    'image TEXT,'
    'bitrate INTEGER,'
    'votes INTEGER,'
    'lastChanged TEXT,'
    'info TEXT,'
    // field removed from version 1
    // 'categoryId INTEGER NOT NULL,'
    'userData TEXT,'
    // field added to version 2
    'labels TEXT)';
const sqlCreateTables = [sqlCreateLabels, sqlCreateStations];
const sqlInsertClassical =
    "INSERT INTO $tableLabels (position,name) VALUES(0, 'Classical')";
const sqlInsertDance =
    "INSERT INTO $tableLabels (position,name) VALUES(1, 'Dance Music')";
const sqlInsertElectronic =
    "INSERT INTO $tableLabels (position,name) VALUES(0, 'Electronic Music')";
const sqlInsertHipHop =
    "INSERT INTO $tableLabels (position,name) VALUES(2, 'Hip Hop Music')";
const sqlInsertJazz =
    "INSERT INTO $tableLabels (position,name) VALUES(3, 'Jazz')";
const sqlInsertNews =
    "INSERT INTO $tableLabels (position,name) VALUES(4, 'News')";
const sqlInsertPop =
    "INSERT INTO $tableLabels (position,name) VALUES(5, 'Pop Music')";
const sqlInsertRock =
    "INSERT INTO $tableLabels (position,name) VALUES(6, 'Rock')";
const sqlInsertBlues =
    "INSERT INTO $tableLabels (position,name) VALUES(7, 'Rhythm and Blues')";
const sqlInsertTalk =
    "INSERT INTO $tableLabels (position,name) VALUES(8, 'Talk Show')";
const sqlInsertLabels = [
  sqlInsertClassical,
  sqlInsertDance,
  sqlInsertElectronic,
  sqlInsertHipHop,
  sqlInsertJazz,
  sqlInsertNews,
  sqlInsertPop,
  sqlInsertRock,
  sqlInsertBlues,
  sqlInsertTalk,
];

//
// alter table from v1 to v2
//
// table of categories becomes table of labels at version 2
const tableCategories = 'categories';
//
// add labels field to the stations
//
const sqlAddLabels = 'ALTER TABLE $tableStations ADD labels TEXT';
//
// copy category name (v1) into labels column (v2)
//
const sqlCopyCategory = 'UPDATE $tableStations SET labels = '
    '$tableCategories.name FROM $tableCategories '
    'where $tableCategories.id = categoryId AND labels is NULL';
// rename table
const sqlRenameCategory = 'ALTER TABLE $tableCategories REANME TO $tableLabels';

class SqliteService {
  // signleton using factory method is preferred for the way it is instanciated.
  // https://stackoverflow.com/questions/54057958/comparing-ways-to-create-singletons-in-dart
  SqliteService._private();
  static final SqliteService _instance = SqliteService._private();
  factory SqliteService() {
    return _instance;
  }

  Database? _db;

  Future<void> open() async {
    var dbPath = await getDatabasesPath();
    String path = join(dbPath, databaseName);
    debugPrint('database path: $path');

    _db = await openDatabase(path, version: databaseVersion,
        onCreate: (Database db, int version) async {
      debugPrint('create database version $version');
      // create tables
      for (final statement in sqlCreateTables) {
        await db.execute(statement);
      }
      // insert initial data to labels
      for (final statement in sqlInsertLabels) {
        await db.execute(statement);
      }
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      debugPrint('upgrade database from version $oldVersion to $newVersion');
      if (oldVersion == 1) {
        debugPrint('adding labels field');
        await db.execute(sqlAddLabels);
        debugPrint('copying categoryId to labels');
        await db.execute(sqlCopyCategory);
        debugPrint('rename table');
        await db.execute(sqlRenameCategory);
      }
    });
  }

  Future<void> close() async {
    await _db?.close();
  }

  Future<Database> getDatabase() async {
    if (_db == null) {
      await open();
    }
    return _db!;
  }

  //
  // Station
  //
  Future<List<Station>> getStations({Map<String, dynamic>? query}) async {
    final db = await getDatabase();
    final snapshot = await db.query(
      tableStations,
      distinct: query?['distinct'],
      columns: query?['columns'],
      where: query?['where'],
      whereArgs: query?['whereArgs'],
      groupBy: query?['groupBy'],
      having: query?['having'],
      orderBy: query?['orderBy'],
      limit: query?['limit'],
      offset: query?['offset'],
    );
    final result = snapshot.map((e) => Station.fromDatabaseMap(e)).toList();
    // debugPrint('getStations: $result');
    return result;
  }

  Future<Station> getStationById(String uuid) async {
    final db = await getDatabase();
    final snapshot =
        await db.query(tableStations, where: 'uuid = ?', whereArgs: [uuid]);

    try {
      return Station.fromDatabaseMap(snapshot.first);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<int> addStation(Station station) async {
    final db = await getDatabase();
    final result = await db.insert(
      tableStations,
      station.toDatabaseMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  Future<int> updateStation(Station station) async {
    final db = await getDatabase();
    final result = await db.update(
      tableStations,
      station.toDatabaseMap(),
      where: 'uuid = ?',
      whereArgs: [station.uuid],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  Future<int> deleteStationById(String uuid) async {
    final db = await getDatabase();
    final result = await db.delete(
      tableStations,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    return result;
  }

  //
  // Station Label
  //
  Future<List<StationLabel>> getLabels({Map<String, dynamic>? query}) async {
    final db = await getDatabase();
    final snapshot = await db.query(
      tableLabels,
      distinct: query?['distinct'],
      columns: query?['columns'],
      where: query?['where'],
      whereArgs: query?['whereArgs'],
      groupBy: query?['groupBy'],
      having: query?['having'],
      orderBy: query?['orderBy'],
      limit: query?['limit'],
      offset: query?['offset'],
    );
    final result =
        snapshot.map((e) => StationLabel.fromDatabaseMap(e)).toList();
    return result;
  }

  Future<int> addLabel(StationLabel label) async {
    final db = await getDatabase();
    final result = await db.insert(
      tableLabels,
      label.toDatabaseMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  Future<int> updateLabel(StationLabel label) async {
    final db = await getDatabase();
    final result = db.update(
      tableLabels,
      label.toDatabaseMap(),
      where: 'id = ?',
      whereArgs: [label.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  Future<int> deleteLabel(StationLabel label) async {
    final db = await getDatabase();
    final result = await db.delete(
      tableLabels,
      where: 'id = ?',
      whereArgs: [label.id],
    );
    return result;
  }
}
