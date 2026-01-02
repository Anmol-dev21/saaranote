import '../entities/note.dart';

abstract class NoteRepository {
  /// Create a new note
  Future<Note> create(Note note);

  /// Get a note by id
  Future<Note?> getById(int id);

  /// Get all notes
  Future<List<Note>> getAll();

  /// Get all archived notes
  Future<List<Note>> getArchived();

  /// Get all active (non-archived) notes
  Future<List<Note>> getActive();

  /// Update an existing note
  Future<Note> update(Note note);

  /// Delete a note by id
  Future<void> delete(int id);

  /// Archive a note
  Future<Note> archive(int id);

  /// Unarchive a note
  Future<Note> unarchive(int id);

  /// Search notes by title or content
  Future<List<Note>> search(String query);
}
