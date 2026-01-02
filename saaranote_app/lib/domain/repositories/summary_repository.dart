import '../entities/summary.dart';

abstract class SummaryRepository {
  /// Create a new summary for a note
  Future<Summary> create(Summary summary);

  /// Get a summary by id
  Future<Summary?> getById(int id);

  /// Get all summaries for a specific note
  Future<List<Summary>> getByNoteId(int noteId);

  /// Get all summaries
  Future<List<Summary>> getAll();

  /// Update an existing summary
  Future<Summary> update(Summary summary);

  /// Delete a summary by id
  Future<void> delete(int id);

  /// Delete all summaries for a specific note
  Future<void> deleteByNoteId(int noteId);
}
