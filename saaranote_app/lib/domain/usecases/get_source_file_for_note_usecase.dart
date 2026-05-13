import '../entities/file_metadata.dart';
import '../repositories/file_organization_repository.dart';

/// Use case for fetching the source file linked to a note.
class GetSourceFileForNoteUseCase {
  final FileOrganizationRepository _repository;

  GetSourceFileForNoteUseCase(this._repository);

  Future<FileMetadata?> execute(int noteId) async {
    return _repository.getFileByRelatedNoteId(noteId.toString());
  }
}
