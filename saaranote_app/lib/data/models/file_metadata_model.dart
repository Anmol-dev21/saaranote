import 'dart:convert';
import '../../domain/entities/file_metadata.dart';

/// Data model for FileMetadata with database serialization
class FileMetadataModel extends FileMetadata {
  const FileMetadataModel({
    super.id,
    required super.filePath,
    required super.fileName,
    required super.fileType,
    super.subject,
    required super.createdAt,
    super.lastModified,
    required super.fileSize,
    super.relatedNoteId,
    super.organizationStatus = OrganizationStatus.pending,
    super.customFolder,
    super.tags,
  });

  /// Create from entity
  factory FileMetadataModel.fromEntity(FileMetadata entity) {
    return FileMetadataModel(
      id: entity.id,
      filePath: entity.filePath,
      fileName: entity.fileName,
      fileType: entity.fileType,
      subject: entity.subject,
      createdAt: entity.createdAt,
      lastModified: entity.lastModified,
      fileSize: entity.fileSize,
      relatedNoteId: entity.relatedNoteId,
      organizationStatus: entity.organizationStatus,
      customFolder: entity.customFolder,
      tags: entity.tags,
    );
  }

  /// Create from database map
  factory FileMetadataModel.fromMap(Map<String, dynamic> map) {
    return FileMetadataModel(
      id: map['id'] as int?,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      fileType: FileType.values[map['file_type'] as int],
      subject: map['subject'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastModified: map['last_modified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_modified'] as int)
          : null,
      fileSize: map['file_size'] as int,
      relatedNoteId: map['related_note_id'] as String?,
      organizationStatus: OrganizationStatus.values[map['organization_status'] as int],
      customFolder: map['custom_folder'] as String?,
      tags: map['tags'] != null 
          ? Map<String, String>.from(jsonDecode(map['tags'] as String))
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'file_type': fileType.index,
      if (subject != null) 'subject': subject,
      'created_at': createdAt.millisecondsSinceEpoch,
      if (lastModified != null) 'last_modified': lastModified!.millisecondsSinceEpoch,
      'file_size': fileSize,
      if (relatedNoteId != null) 'related_note_id': relatedNoteId,
      'organization_status': organizationStatus.index,
      if (customFolder != null) 'custom_folder': customFolder,
      if (tags != null) 'tags': jsonEncode(tags),
    };
  }

  /// Convert to entity
  FileMetadata toEntity() {
    return FileMetadata(
      id: id,
      filePath: filePath,
      fileName: fileName,
      fileType: fileType,
      subject: subject,
      createdAt: createdAt,
      lastModified: lastModified,
      fileSize: fileSize,
      relatedNoteId: relatedNoteId,
      organizationStatus: organizationStatus,
      customFolder: customFolder,
      tags: tags,
    );
  }
}

/// Data model for OrganizationRule with database serialization
class OrganizationRuleModel extends OrganizationRule {
  const OrganizationRuleModel({
    required super.id,
    required super.name,
    super.subjectPattern,
    super.fileType,
    required super.targetFolder,
    super.priority = 0,
    super.isEnabled = true,
  });

  /// Create from entity
  factory OrganizationRuleModel.fromEntity(OrganizationRule entity) {
    return OrganizationRuleModel(
      id: entity.id,
      name: entity.name,
      subjectPattern: entity.subjectPattern,
      fileType: entity.fileType,
      targetFolder: entity.targetFolder,
      priority: entity.priority,
      isEnabled: entity.isEnabled,
    );
  }

  /// Create from database map
  factory OrganizationRuleModel.fromMap(Map<String, dynamic> map) {
    return OrganizationRuleModel(
      id: map['id'] as String,
      name: map['name'] as String,
      subjectPattern: map['subject_pattern'] as String?,
      fileType: map['file_type'] != null 
          ? FileType.values[map['file_type'] as int]
          : null,
      targetFolder: map['target_folder'] as String,
      priority: map['priority'] as int? ?? 0,
      isEnabled: (map['is_enabled'] as int) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (subjectPattern != null) 'subject_pattern': subjectPattern,
      if (fileType != null) 'file_type': fileType!.index,
      'target_folder': targetFolder,
      'priority': priority,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  /// Convert to entity
  OrganizationRule toEntity() {
    return OrganizationRule(
      id: id,
      name: name,
      subjectPattern: subjectPattern,
      fileType: fileType,
      targetFolder: targetFolder,
      priority: priority,
      isEnabled: isEnabled,
    );
  }
}
