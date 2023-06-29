import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'home.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;

  static Database? _db;

  Future<Database?> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();
    return _db;
  }

  DatabaseHelper.internal();

  Future<Database> initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'workouts.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE workouts(id INTEGER PRIMARY KEY, name TEXT, "order" INTEGER)',
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    Database? db = await this.db;
    return await db!.query('workouts');
  }

  Future<int> deleteWorkout(int id) async {
    Database? db = await this.db;
    return await db!.delete(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateWorkoutName(int id, String newName) async {
    Database? db = await this.db;
    return await db!.update(
      'workouts',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
