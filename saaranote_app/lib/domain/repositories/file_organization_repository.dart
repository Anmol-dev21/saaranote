import '../entities/file_metadata.dart';

/// Repository interface for file organization and indexing
abstract class FileOrganizationRepository {
  /// Add a new file to the index
  Future<FileMetadata> addFile(FileMetadata file);

  /// Get file metadata by ID
  Future<FileMetadata?> getFileById(int id);

  /// Get file metadata by path
  Future<FileMetadata?> getFileByPath(String path);

  /// Get all files
  Future<List<FileMetadata>> getAllFiles();

  /// Get files by subject
  Future<List<FileMetadata>> getFilesBySubject(String subject);

  /// Get files by type
  Future<List<FileMetadata>> getFilesByType(FileType type);

  /// Get files by organization status
  Future<List<FileMetadata>> getFilesByStatus(OrganizationStatus status);

  /// Get files by date range
  Future<List<FileMetadata>> getFilesByDateRange(DateTime start, DateTime end);

  /// Update file metadata
  Future<FileMetadata> updateFile(FileMetadata file);

  /// Delete file from index
  Future<void> deleteFile(int id);

  /// Search files by filename or tags
  Future<List<FileMetadata>> searchFiles(String query);

  /// Get all subjects
  Future<List<String>> getAllSubjects();

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats();

  /// Add organization rule
  Future<OrganizationRule> addRule(OrganizationRule rule);

  /// Get all organization rules
  Future<List<OrganizationRule>> getAllRules();

  /// Update organization rule
  Future<OrganizationRule> updateRule(OrganizationRule rule);

  /// Delete organization rule
  Future<void> deleteRule(String ruleId);
}
