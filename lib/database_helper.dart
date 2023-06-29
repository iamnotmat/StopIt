import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'workout_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutId INTEGER,
        setName TEXT,
        FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    Database db = await instance.database;
    return await db.query('workouts');
  }

  Future<int> insertWorkout(String name) async {
    Database db = await instance.database;
    Map<String, dynamic> row = {'name': name};
    return await db.insert('workouts', row);
  }

  Future<int> deleteWorkout(int id) async {
    Database db = await instance.database;
    return await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllWorkouts() async {
    Database db = await instance.database;
    await db.delete('workouts');
    await db.delete('sets');
  }

  Future<List<Map<String, dynamic>>> getSets(int workoutId) async {
    Database db = await instance.database;
    return await db
        .query('sets', where: 'workoutId = ?', whereArgs: [workoutId]);
  }

  Future<int> insertSet(int workoutId, String setName) async {
    Database db = await instance.database;
    Map<String, dynamic> row = {
      'workoutId': workoutId,
      'setName': setName,
    };
    return await db.insert('sets', row);
  }

  Future<int> deleteSet(int setId) async {
    Database db = await instance.database;
    return await db.delete('sets', where: 'id = ?', whereArgs: [setId]);
  }

  Future<void> deleteAllSets() async {
    Database db = await instance.database;
    await db.delete('sets');
  }
}
