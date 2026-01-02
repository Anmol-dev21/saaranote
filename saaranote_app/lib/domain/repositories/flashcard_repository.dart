import '../entities/flashcard.dart';

abstract class FlashcardRepository {
  /// Create a new flashcard for a note
  Future<Flashcard> create(Flashcard flashcard);

  /// Get a flashcard by id
  Future<Flashcard?> getById(int id);

  /// Get all flashcards for a specific note
  Future<List<Flashcard>> getByNoteId(int noteId);

  /// Get all flashcards
  Future<List<Flashcard>> getAll();

  /// Get flashcards due for review (by confidence level)
  Future<List<Flashcard>> getDueForReview();

  /// Update an existing flashcard
  Future<Flashcard> update(Flashcard flashcard);

  /// Update the confidence level after review
  Future<Flashcard> updateConfidenceLevel(int id, int confidenceLevel);

  /// Delete a flashcard by id
  Future<void> delete(int id);

  /// Delete all flashcards for a specific note
  Future<void> deleteByNoteId(int noteId);
}
