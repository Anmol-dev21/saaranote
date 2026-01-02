import '../entities/note.dart';
import '../repositories/note_repository.dart';

/// Use case for retrieving a single note by its ID
class GetNoteByIdUseCase {
  final NoteRepository _noteRepository;

  GetNoteByIdUseCase(this._noteRepository);

  /// Execute the use case to retrieve a note by ID
  /// 
  /// Returns the note if found, or throws an exception if not found.
  Future<Note> execute(int noteId) async {
    final note = await _noteRepository.getById(noteId);
    
    if (note == null) {
      throw NoteNotFoundException('Note with id $noteId not found');
    }
    
    return note;
  }
}

/// Exception thrown when a note is not found
class NoteNotFoundException implements Exception {
  final String message;

  NoteNotFoundException(this.message);

  @override
  String toString() => 'NoteNotFoundException: $message';
}
