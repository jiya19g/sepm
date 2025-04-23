import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'resources.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE resources(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        type TEXT,
        filePath TEXT,
        uploadDate TEXT,
        size TEXT
      )
    ''');
  }

  Future<int> insertResource(Map<String, dynamic> resource) async {
    Database db = await database;
    return await db.insert('resources', resource);
  }

  Future<List<Map<String, dynamic>>> getResources() async {
    Database db = await database;
    return await db.query('resources', orderBy: 'uploadDate DESC');
  }

  Future<int> deleteResource(int id) async {
    Database db = await database;
    return await db.delete('resources', where: 'id = ?', whereArgs: [id]);
  }
}