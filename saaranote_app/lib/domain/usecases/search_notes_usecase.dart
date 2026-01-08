import '../entities/note.dart';
import '../repositories/note_repository.dart';

/// Use case for searching notes by query string
class SearchNotesUseCase {
  final NoteRepository _noteRepository;

  SearchNotesUseCase(this._noteRepository);

  /// Execute the use case to search notes
  /// 
  /// [query] - The search query string to match against note titles and content
  /// 
  /// Returns a list of notes that match the search query.
  /// Returns an empty list if no matches are found or if the query is empty.
  Future<List<Note>> execute(String query) async {
    // Return empty list for empty queries
    if (query.trim().isEmpty) {
      return [];
    }

    // Delegate search to repository
    return await _noteRepository.searchNotes(query);
  }
}
