import '../entities/note.dart';
import '../repositories/note_repository.dart';

/// Use case for updating an existing note
class UpdateNoteUseCase {
  final NoteRepository _noteRepository;

  UpdateNoteUseCase(this._noteRepository);

  /// Execute the use case to update a note
  /// 
  /// Takes [UpdateNoteParams] and returns the updated note.
  /// Automatically updates the updatedAt timestamp.
  Future<Note> execute(UpdateNoteParams params) async {
    // Verify note exists
    final existingNote = await _noteRepository.getById(params.noteId);
    
    if (existingNote == null) {
      throw UpdateNoteException('Note with id ${params.noteId} not found');
    }

    // Create updated note with new timestamp
    final updatedNote = existingNote.copyWith(
      title: params.title ?? existingNote.title,
      content: params.content ?? existingNote.content,
      color: params.color ?? existingNote.color,
      updatedAt: DateTime.now(),
    );

    return await _noteRepository.update(updatedNote);
  }
}

/// Parameters for updating a note
class UpdateNoteParams {
  final int noteId;
  final String? title;
  final String? content;
  final String? color;

  UpdateNoteParams({
    required this.noteId,
    this.title,
    this.content,
    this.color,
  });
}

/// Exception thrown when note update fails
class UpdateNoteException implements Exception {
  final String message;

  UpdateNoteException(this.message);

  @override
  String toString() => 'UpdateNoteException: $message';
}
