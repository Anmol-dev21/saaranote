import '../entities/file_metadata.dart';
import '../repositories/note_repository.dart';
import '../../core/services/document_indexing_service.dart';

/// Use case for rebuilding retrieval index from existing notes.
class ReindexNotesUseCase {
  final NoteRepository _noteRepository;
  final DocumentIndexingService _indexingService;

  ReindexNotesUseCase(this._noteRepository, this._indexingService);

  Future<void> execute() async {
    final notes = await _noteRepository.getAll();
    for (final note in notes) {
      final noteId = note.id;
      if (noteId == null) continue;
      await _indexingService.indexNoteContent(
        noteId: noteId,
        title: note.title,
        content: note.content,
        fileType: FileType.note,
      );
    }
  }
}
