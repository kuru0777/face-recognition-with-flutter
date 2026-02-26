import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const _databaseName = "MyDatabase.db";
  static const _databaseVersion = 2;

  static const table = 'my_table2';

  static const columnId = 'id';
  static const columnStdNumber = 'StdNumber';
  static const columnFirstName = 'FirstName';
  static const columnLastName = 'LastName';
  static const columnEmbedding = 'Embedding';

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = '${documentsDirectory.path}/$_databaseName';
    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnStdNumber TEXT NOT NULL,
            $columnFirstName TEXT NOT NULL,
            $columnLastName TEXT NOT NULL,
            $columnEmbedding TEXT NOT NULL
          )
          ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    return await _db!.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db!.query(table);
  }

  Future<int> queryRowCount() async {
    final results = await _db!.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  Future<int> update(Map<String, dynamic> row) async {
    int id = row[columnId];
    return await _db!.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return await _db!.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllRow() async {
    return await _db!.delete(table);
  }

  Future<void> dropTable() async {
    return await _db!.execute('DROP TABLE IF EXISTS $table');
  }

  Future<List<Map<String, dynamic>>> getAllFaces() async {
    return await _db!.query(table, columns: [
      columnId,
      columnStdNumber,
      columnFirstName,
      columnLastName,
      columnEmbedding,
    ]);
  }

  Future<int> queryRowCountWhere(String column, String value) async {
    final results = await _db!
        .rawQuery('SELECT COUNT(*) FROM $table WHERE $column = ?', [value]);
    return Sqflite.firstIntValue(results) ?? 0;
  }

  Future<int> registerFace(
      String number, String name, String surname, List<double> embedding) async {
    await init();
    final row = {
      columnStdNumber: number,
      columnFirstName: name,
      columnLastName: surname,
      columnEmbedding: embedding.join(","),
    };
    final id = await insert(row);
    debugPrint('Registered face with id: $id');
    return id;
  }
}
