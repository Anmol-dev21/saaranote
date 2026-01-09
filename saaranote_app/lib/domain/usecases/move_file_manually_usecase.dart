import '../../domain/entities/file_metadata.dart';
import '../../domain/repositories/file_organization_repository.dart';
import '../../core/services/file_organization_service.dart';

/// Use case for manually moving a file to a custom location
class MoveFileManuallyUseCase {
  final FileOrganizationRepository _repository;
  final FileOrganizationService _service;

  MoveFileManuallyUseCase(this._repository, this._service);

  Future<FileMetadata> execute(MoveFileParams params) async {
    // Get existing metadata
    final existing = await _repository.getFileById(params.fileId);
    if (existing == null) {
      throw Exception('File metadata not found');
    }

    // Move file to custom location
    final newPath = await _service.moveFileManually(
      existing.filePath,
      params.targetFolder,
      params.newFileName ?? existing.fileName,
    );

    // Update metadata
    final updated = existing.copyWith(
      filePath: newPath,
      fileName: params.newFileName ?? existing.fileName,
      customFolder: params.targetFolder,
      organizationStatus: OrganizationStatus.manual,
      lastModified: DateTime.now(),
    );

    return await _repository.updateFile(updated);
  }
}

class MoveFileParams {
  final int fileId;
  final String targetFolder;
  final String? newFileName;

  MoveFileParams({
    required this.fileId,
    required this.targetFolder,
    this.newFileName,
  });
}
