import '../../domain/entities/file_metadata.dart';
import '../../domain/repositories/file_organization_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/file_metadata_model.dart';

/// Implementation of FileOrganizationRepository using SQLite
class FileOrganizationRepositoryImpl implements FileOrganizationRepository {
  final DatabaseHelper _databaseHelper;

  FileOrganizationRepositoryImpl(this._databaseHelper);

  @override
  Future<FileMetadata> addFile(FileMetadata file) async {
    final db = await _databaseHelper.database;
    final model = FileMetadataModel.fromEntity(file);
    final id = await db.insert('file_metadata', model.toMap());
    return file.copyWith(id: id);
  }

  @override
  Future<FileMetadata?> getFileById(int id) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'file_metadata',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return FileMetadataModel.fromMap(results.first).toEntity();
  }

  @override
  Future<FileMetadata?> getFileByPath(String path) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'file_metadata',
      where: 'file_path = ?',
      whereArgs: [path],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return FileMetadataModel.fromMap(results.first).toEntity();
  }

  @override
  Future<FileMetadata?> getFileByRelatedNoteId(String relatedNoteId) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'file_metadata',
      where: 'related_note_id = ?',
      whereArgs: [relatedNoteId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return FileMetadataModel.fromMap(results.first).toEntity();
  }

  @override
  Future<List<FileMetadata>> getAllFiles() async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'file_metadata',
      orderBy: 'created_at DESC',
    );

    return results
        .map((map) => FileMetadataModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<List<FileMetadata>> getFilesBySubject(String subject) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'file_metadata',
      where: 'subject = ?',
      whereArgs: [subject],
      orderBy: 'created_at DESC',
    );

    return results
        .map((map) => FileMetadataModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<List<FileMetadata>> getFilesByType(FileType type) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'file_metadata',
      where: 'file_type = ?',
      whereArgs: [type.index],
      orderBy: 'created_at DESC',
    );

    return results
        .map((map) => FileMetadataModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<List<FileMetadata>> getFilesByStatus(OrganizationStatus status) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'file_metadata',
      where: 'organization_status = ?',
      whereArgs: [status.index],
      orderBy: 'created_at DESC',
    );

    return results
        .map((map) => FileMetadataModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<List<FileMetadata>> getFilesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'file_metadata',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'created_at DESC',
    );

    return results
        .map((map) => FileMetadataModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<List<FileMetadata>> searchFiles(String query) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'file_metadata',
      where: 'file_name LIKE ? OR subject LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );

    return results
        .map((map) => FileMetadataModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<FileMetadata> updateFile(FileMetadata file) async {
    final db = await _databaseHelper.database;
    final model = FileMetadataModel.fromEntity(file);
    await db.update(
      'file_metadata',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [file.id],
    );
    return file;
  }

  @override
  Future<void> deleteFile(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'file_metadata',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Map<String, dynamic>> getStorageStats() async {
    final db = await _databaseHelper.database;

    // Get total count and size
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(file_size) as total_size FROM file_metadata',
    );
    final totalCount = totalResult.first['count'] as int? ?? 0;
    final totalSize = totalResult.first['total_size'] as int? ?? 0;

    // Get files by type
    final typeResult = await db.rawQuery(
      'SELECT file_type, COUNT(*) as count, SUM(file_size) as size FROM file_metadata GROUP BY file_type',
    );
    final Map<String, dynamic> filesByType = {};
    for (final row in typeResult) {
      final type = FileType.values[row['file_type'] as int];
      filesByType[type.name] = {
        'count': row['count'],
        'size': row['size'],
      };
    }

    // Get files by subject
    final subjectResult = await db.rawQuery(
      'SELECT subject, COUNT(*) as count, SUM(file_size) as size FROM file_metadata WHERE subject IS NOT NULL GROUP BY subject',
    );
    final Map<String, dynamic> filesBySubject = {};
    for (final row in subjectResult) {
      final subject = row['subject'] as String;
      filesBySubject[subject] = {
        'count': row['count'],
        'size': row['size'],
      };
    }

    return {
      'totalFiles': totalCount,
      'totalSize': totalSize,
      'filesByType': filesByType,
      'filesBySubject': filesBySubject,
    };
  }

  @override
  Future<List<String>> getAllSubjects() async {
    final db = await _databaseHelper.database;
    final results = await db.rawQuery(
      'SELECT DISTINCT subject FROM file_metadata WHERE subject IS NOT NULL ORDER BY subject',
    );

    return results
        .map((row) => row['subject'] as String)
        .toList();
  }

  @override
  Future<OrganizationRule> addRule(OrganizationRule rule) async {
    final db = await _databaseHelper.database;
    final model = OrganizationRuleModel.fromEntity(rule);
    await db.insert('organization_rules', model.toMap());
    return rule;
  }

  @override
  Future<List<OrganizationRule>> getAllRules() async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'organization_rules',
      where: 'is_enabled = 1',
      orderBy: 'priority DESC',
    );

    return results
        .map((map) => OrganizationRuleModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<OrganizationRule> updateRule(OrganizationRule rule) async {
    final db = await _databaseHelper.database;
    final model = OrganizationRuleModel.fromEntity(rule);
    await db.update(
      'organization_rules',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
    return rule;
  }

  @override
  Future<void> deleteRule(String ruleId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'organization_rules',
      where: 'id = ?',
      whereArgs: [ruleId],
    );
  }
}
