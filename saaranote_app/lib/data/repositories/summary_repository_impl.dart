import 'package:sqflite/sqflite.dart';
import '../../domain/entities/note_summary.dart';
import '../../domain/repositories/summary_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/summary_model.dart';

class SummaryRepositoryImpl implements SummaryRepository {
  final DatabaseHelper _databaseHelper;

  SummaryRepositoryImpl(this._databaseHelper);

  Future<Database> get _db async => await _databaseHelper.database;

  @override
  Future<NoteSummary> create(NoteSummary summary) async {
    final db = await _db;
    final model = SummaryModel.fromEntity(summary);
    final id = await db.insert('summaries', model.toMap());
    return model.copyWith(id: id).toEntity();
  }

  @override
  Future<NoteSummary?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'summaries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return SummaryModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<List<NoteSummary>> getByNoteId(int noteId) async {
    final db = await _db;
    final maps = await db.query(
      'summaries',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => SummaryModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<NoteSummary>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'summaries',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => SummaryModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<NoteSummary> update(NoteSummary summary) async {
    final db = await _db;
    final model = SummaryModel.fromEntity(summary);
    
    await db.update(
      'summaries',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [summary.id],
    );

    return model.toEntity();
  }

  @override
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(
      'summaries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteByNoteId(int noteId) async {
    final db = await _db;
    await db.delete(
      'summaries',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }
}
