import '../entities/note_summary.dart';

abstract class SummaryRepository {
  /// Create a new summary for a note
  Future<NoteSummary> create(NoteSummary summary);

  /// Get a summary by id
  Future<NoteSummary?> getById(int id);

  /// Get all summaries for a specific note
  Future<List<NoteSummary>> getByNoteId(int noteId);

  /// Get all summaries
  Future<List<NoteSummary>> getAll();

  /// Update an existing summary
  Future<NoteSummary> update(NoteSummary summary);

  /// Delete a summary by id
  Future<void> delete(int id);

  /// Delete all summaries for a specific note
  Future<void> deleteByNoteId(int noteId);
}
