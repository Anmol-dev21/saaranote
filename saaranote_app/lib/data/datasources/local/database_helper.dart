import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('saaranote.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const integerType = 'INTEGER NOT NULL';

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id $idType,
        title $textType,
        content $textType,
        created_at $integerType,
        updated_at $integerType,
        is_archived $integerType DEFAULT 0,
        color $textNullableType
      )
    ''');

    // Summaries table
    await db.execute('''
      CREATE TABLE summaries (
        id $idType,
        note_id $integerType,
        summary_text $textType,
        created_at $integerType,
        FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');

    // Flashcards table
    await db.execute('''
      CREATE TABLE flashcards (
        id $idType,
        note_id $integerType,
        question $textType,
        answer $textType,
        created_at $integerType,
        last_reviewed_at $integerType,
        confidence_level $integerType DEFAULT 0,
        FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
        'CREATE INDEX idx_notes_created_at ON notes(created_at DESC)');
    await db.execute('CREATE INDEX idx_summaries_note_id ON summaries(note_id)');
    await db.execute(
        'CREATE INDEX idx_flashcards_note_id ON flashcards(note_id)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here when version changes
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE notes ADD COLUMN new_field TEXT');
    // }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
