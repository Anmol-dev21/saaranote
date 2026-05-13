import '../repositories/note_repository.dart';
import '../repositories/summary_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../repositories/file_organization_repository.dart';
import '../repositories/index_repository.dart';

/// Use case for deleting a note and its associated data
class DeleteNoteUseCase {
  final NoteRepository _noteRepository;
  final SummaryRepository _summaryRepository;
  final FlashcardRepository _flashcardRepository;
  final FileOrganizationRepository? _fileOrganizationRepository;
  final IndexRepository? _indexRepository;

  DeleteNoteUseCase(
    this._noteRepository,
    this._summaryRepository,
    this._flashcardRepository, {
    FileOrganizationRepository? fileOrganizationRepository,
    IndexRepository? indexRepository,
  })  : _fileOrganizationRepository = fileOrganizationRepository,
        _indexRepository = indexRepository;

  /// Execute the use case to delete a note
  /// 
  /// Deletes the note and all associated summaries and flashcards.
  /// This is a cascading delete operation.
  Future<void> execute(int noteId) async {
    // Verify note exists
    final note = await _noteRepository.getById(noteId);
    
    if (note == null) {
      throw DeleteNoteException('Note with id $noteId not found');
    }

    // Delete associated retrieval metadata first
    final fileRepository = _fileOrganizationRepository;
    if (fileRepository != null) {
      try {
        final metadata = await fileRepository.getFileByRelatedNoteId(
          noteId.toString(),
        );
        if (metadata?.id != null) {
          final fileId = metadata!.id!;
          final indexRepository = _indexRepository;
          if (indexRepository != null) {
            await indexRepository.deleteChunksByFileId(fileId);
          }
          await fileRepository.deleteFile(fileId);
        }
      } catch (_) {
        // Avoid blocking note deletion if index cleanup fails.
      }
    }

    // Delete associated data first
    try {
      // Delete all summaries for this note
      await _summaryRepository.deleteByNoteId(noteId);
      
      // Delete all flashcards for this note
      await _flashcardRepository.deleteByNoteId(noteId);
      
      // Finally, delete the note itself
      await _noteRepository.delete(noteId);
    } catch (e) {
      throw DeleteNoteException('Failed to delete note: ${e.toString()}');
    }
  }
}

/// Exception thrown when note deletion fails
class DeleteNoteException implements Exception {
  final String message;

  DeleteNoteException(this.message);

  @override
  String toString() => 'DeleteNoteException: $message';
}
