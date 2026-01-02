import 'package:sqflite/sqflite.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DatabaseHelper _databaseHelper;

  NoteRepositoryImpl(this._databaseHelper);

  Future<Database> get _db async => await _databaseHelper.database;

  @override
  Future<Note> create(Note note) async {
    final db = await _db;
    final model = NoteModel.fromEntity(note);
    final id = await db.insert('notes', model.toMap());
    return model.copyWith(id: id).toEntity();
  }

  @override
  Future<Note?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return NoteModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<List<Note>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'notes',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => NoteModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<Note>> getArchived() async {
    final db = await _db;
    final maps = await db.query(
      'notes',
      where: 'is_archived = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => NoteModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<Note>> getActive() async {
    final db = await _db;
    final maps = await db.query(
      'notes',
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => NoteModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<Note> update(Note note) async {
    final db = await _db;
    final model = NoteModel.fromEntity(note);
    
    await db.update(
      'notes',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );

    return model.toEntity();
  }

  @override
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Note> archive(int id) async {
    final note = await getById(id);
    if (note == null) {
      throw Exception('Note not found');
    }

    final updatedNote = note.copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );

    return await update(updatedNote);
  }

  @override
  Future<Note> unarchive(int id) async {
    final note = await getById(id);
    if (note == null) {
      throw Exception('Note not found');
    }

    final updatedNote = note.copyWith(
      isArchived: false,
      updatedAt: DateTime.now(),
    );

    return await update(updatedNote);
  }

  @override
  Future<List<Note>> search(String query) async {
    final db = await _db;
    final searchPattern = '%$query%';
    
    final maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: [searchPattern, searchPattern],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => NoteModel.fromMap(map).toEntity()).toList();
  }
}
