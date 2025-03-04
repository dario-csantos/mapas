// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Importações necessárias para usar sqflite e path
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Definimos a classe no nível superior (fora de qualquer função)
class DatabaseHelperLocal {
  static final DatabaseHelperLocal _instance = DatabaseHelperLocal._internal();
  factory DatabaseHelperLocal() => _instance;
  DatabaseHelperLocal._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath(); // sqflite
    final path = join(dbPath, 'mapas.db'); // path
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routes (
        route_id INTEGER PRIMARY KEY AUTOINCREMENT,
        socio_id INTEGER NOT NULL,
        name TEXT,
        description TEXT,
        created_at TEXT,
        avg_speed REAL,
        total_duration INTEGER,
        total_distance REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE route_points (
        route_point_id INTEGER PRIMARY KEY AUTOINCREMENT,
        route_id INTEGER NOT NULL,
        latitude REAL,
        longitude REAL,
        speed REAL,
        timestamp TEXT,
        FOREIGN KEY (route_id) REFERENCES routes(route_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE places (
        place_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        type TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        address TEXT,
        created_at TEXT
      )
    ''');
  }

  // Exemplo de método de inserção
  Future<int> insertRoute(Map<String, dynamic> routeData) async {
    final db = await database;
    return db.insert('routes', routeData);
  }
}

// Função principal
Future<String> databaseHelper() async {
  /// MODIFY CODE ONLY BELOW THIS LINE

  // Instancia a classe e inicializa o banco
  final helper = DatabaseHelperLocal();
  await helper.database;

  // Retornamos String para não ser considerado “vazio”
  return "DatabaseHelper loaded successfully";

  /// MODIFY CODE ONLY ABOVE THIS LINE
}
