import 'package:sqflite/sqflite.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/flashcard_model.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final DatabaseHelper _databaseHelper;

  FlashcardRepositoryImpl(this._databaseHelper);

  Future<Database> get _db async => await _databaseHelper.database;

  @override
  Future<Flashcard> create(Flashcard flashcard) async {
    final db = await _db;
    final model = FlashcardModel.fromEntity(flashcard);
    final id = await db.insert('flashcards', model.toMap());
    return model.copyWith(id: id).toEntity();
  }

  @override
  Future<Flashcard?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'flashcards',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return FlashcardModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<List<Flashcard>> getByNoteId(int noteId) async {
    final db = await _db;
    final maps = await db.query(
      'flashcards',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => FlashcardModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<Flashcard>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'flashcards',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => FlashcardModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<Flashcard>> getDueForReview() async {
    final db = await _db;
    // Get flashcards with low confidence level (0-2) or never reviewed
    final maps = await db.query(
      'flashcards',
      where: 'confidence_level < ?',
      whereArgs: [3],
      orderBy: 'last_reviewed_at ASC, created_at ASC',
    );

    return maps.map((map) => FlashcardModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<Flashcard> update(Flashcard flashcard) async {
    final db = await _db;
    final model = FlashcardModel.fromEntity(flashcard);
    
    await db.update(
      'flashcards',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );

    return model.toEntity();
  }

  @override
  Future<Flashcard> updateConfidenceLevel(int id, int confidenceLevel) async {
    final flashcard = await getById(id);
    if (flashcard == null) {
      throw Exception('Flashcard not found');
    }

    final updatedFlashcard = flashcard.copyWith(
      confidenceLevel: confidenceLevel,
      lastReviewedAt: DateTime.now(),
    );

    return await update(updatedFlashcard);
  }

  @override
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(
      'flashcards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteByNoteId(int noteId) async {
    final db = await _db;
    await db.delete(
      'flashcards',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }
}
