import '../../domain/entities/file_metadata.dart';
import '../../domain/repositories/file_organization_repository.dart';

/// Use case for getting files by various criteria
class GetOrganizedFilesUseCase {
  final FileOrganizationRepository _repository;

  GetOrganizedFilesUseCase(this._repository);

  /// Get all files
  Future<List<FileMetadata>> execute() async {
    return await _repository.getAllFiles();
  }

  /// Get files by subject
  Future<List<FileMetadata>> bySubject(String subject) async {
    return await _repository.getFilesBySubject(subject);
  }

  /// Get files by type
  Future<List<FileMetadata>> byType(FileType type) async {
    return await _repository.getFilesByType(type);
  }

  /// Get files by date range
  Future<List<FileMetadata>> byDateRange(DateTime start, DateTime end) async {
    return await _repository.getFilesByDateRange(start, end);
  }

  /// Search files
  Future<List<FileMetadata>> search(String query) async {
    return await _repository.searchFiles(query);
  }

  /// Get all subjects
  Future<List<String>> getAllSubjects() async {
    return await _repository.getAllSubjects();
  }
}
