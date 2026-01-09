import '../../domain/entities/file_metadata.dart';
import '../../domain/repositories/file_organization_repository.dart';
import '../../core/services/file_organization_service.dart';

/// Use case for batch organizing multiple files
class BatchOrganizeFilesUseCase {
  final FileOrganizationRepository _repository;
  final FileOrganizationService _service;

  BatchOrganizeFilesUseCase(this._repository, this._service);

  Future<BatchOrganizeResult> execute(List<String> filePaths) async {
    final results = <FileMetadata>[];
    final errors = <String, String>{};

    for (final filePath in filePaths) {
      try {
        final fileName = filePath.split('/').last;
        final extension = fileName.split('.').last;
        final fileType = FileType.fromExtension(extension);
        final fileSize = await _service.getFileSize(filePath);

        // Auto-detect subject
        final subject = await _service.detectSubject(fileName);

        var metadata = FileMetadata(
          filePath: filePath,
          fileName: fileName,
          fileType: fileType,
          subject: subject,
          createdAt: DateTime.now(),
          fileSize: fileSize,
          organizationStatus: OrganizationStatus.pending,
        );

        // Organize file
        final newPath = await _service.organizeFile(metadata);

        metadata = metadata.copyWith(
          filePath: newPath,
          organizationStatus: OrganizationStatus.organized,
        );

        // Save to repository
        final saved = await _repository.addFile(metadata);
        results.add(saved);
      } catch (e) {
        errors[filePath] = e.toString();
      }
    }

    return BatchOrganizeResult(
      organized: results,
      errors: errors,
    );
  }
}

class BatchOrganizeResult {
  final List<FileMetadata> organized;
  final Map<String, String> errors;

  BatchOrganizeResult({
    required this.organized,
    required this.errors,
  });

  int get successCount => organized.length;
  int get errorCount => errors.length;
  int get totalCount => successCount + errorCount;

  bool get hasErrors => errors.isNotEmpty;
  bool get allSucceeded => errorCount == 0;
}
