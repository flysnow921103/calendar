// lib/database/todo_database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';
// 確保這個import在這裡

class TodoDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todo.db');
    return _database!;
  }

  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE todos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            title TEXT,
            isCompleted INTEGER
          )
        ''');
      },
    );
  }

  static Future<void> insertTodo(Todo todo) async {
    final db = await database;
    await db.insert('todos', todo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Todo>> getTodosByDate(String date) async {
    final db = await database;
    final maps = await db.query('todos', where: 'date = ?', whereArgs: [date]);
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  static Future<void> updateTodo(Todo todo) async {
    final db = await database;
    await db
        .update('todos', todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  }

  static Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Todo>> getAllTodos() async {
    final db = await database;
    final maps = await db.query('todos');
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  // 新增的範圍查詢方法，返回在指定日期範圍內的待辦事項
  static Future<List<Todo>> getTodosInRange(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final start = startDate.toIso8601String().substring(0, 10);
    final end = endDate.toIso8601String().substring(0, 10);
    final maps = await db.query(
      'todos',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'date ASC', // 按日期從舊到新排列
    );
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  static Future<void> deleteAllTodos() async {
    final db = await database; // 使用 database getter 來取得資料庫實例
    await db.delete('todos'); // 刪除所有待辦事項
  }
}
