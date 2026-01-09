/// File metadata entity for organizing study materials
/// Tracks files (PDFs, images, notes) with automatic categorization
class FileMetadata {
  final int? id;
  final String filePath;
  final String fileName;
  final FileType fileType;
  final String? subject;
  final DateTime createdAt;
  final DateTime? lastModified;
  final int fileSize;
  final String? relatedNoteId; // Link to note if created from note
  final OrganizationStatus organizationStatus;
  final String? customFolder; // Manual override path
  final Map<String, String>? tags; // Custom tags for filtering

  const FileMetadata({
    this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    this.subject,
    required this.createdAt,
    this.lastModified,
    required this.fileSize,
    this.relatedNoteId,
    this.organizationStatus = OrganizationStatus.pending,
    this.customFolder,
    this.tags,
  });

  /// Check if file has been organized
  bool get isOrganized => organizationStatus == OrganizationStatus.organized;

  /// Check if file has manual override
  bool get hasManualOverride => customFolder != null;

  /// Get the target folder path based on organization rules
  String getTargetFolder() {
    // Manual override takes precedence
    if (customFolder != null) return customFolder!;

    // Auto-generate folder structure: subject/date/type
    final subject = this.subject ?? 'Uncategorized';
    final date = _formatDate(createdAt);
    final type = fileType.folderName;

    return '$subject/$date/$type';
  }

  /// Get file extension
  String get extension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is a study material type
  bool get isStudyMaterial {
    return fileType == FileType.pdf ||
        fileType == FileType.image ||
        fileType == FileType.note;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  FileMetadata copyWith({
    int? id,
    String? filePath,
    String? fileName,
    FileType? fileType,
    String? subject,
    DateTime? createdAt,
    DateTime? lastModified,
    int? fileSize,
    String? relatedNoteId,
    OrganizationStatus? organizationStatus,
    String? customFolder,
    Map<String, String>? tags,
    bool clearCustomFolder = false,
  }) {
    return FileMetadata(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      subject: subject ?? this.subject,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      fileSize: fileSize ?? this.fileSize,
      relatedNoteId: relatedNoteId ?? this.relatedNoteId,
      organizationStatus: organizationStatus ?? this.organizationStatus,
      customFolder: clearCustomFolder ? null : (customFolder ?? this.customFolder),
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filePath == other.filePath;

  @override
  int get hashCode => id.hashCode ^ filePath.hashCode;
}

/// File types supported by the organization system
enum FileType {
  pdf,
  image,
  note,
  other;

  String get folderName {
    switch (this) {
      case FileType.pdf:
        return 'PDFs';
      case FileType.image:
        return 'Images';
      case FileType.note:
        return 'Notes';
      case FileType.other:
        return 'Other';
    }
  }

  static FileType fromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return FileType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return FileType.image;
      case 'txt':
      case 'md':
      case 'doc':
      case 'docx':
        return FileType.note;
      default:
        return FileType.other;
    }
  }
}

/// Organization status of a file
enum OrganizationStatus {
  pending,    // Not yet organized
  organized,  // Successfully organized
  failed,     // Organization failed
  manual,     // Manually organized by user
}

/// Organization rule for automatic categorization
class OrganizationRule {
  final String id;
  final String name;
  final String? subjectPattern; // Regex or keyword for subject detection
  final FileType? fileType;
  final String targetFolder;
  final int priority; // Higher priority rules apply first
  final bool isEnabled;

  const OrganizationRule({
    required this.id,
    required this.name,
    this.subjectPattern,
    this.fileType,
    required this.targetFolder,
    this.priority = 0,
    this.isEnabled = true,
  });

  /// Check if rule matches the given file
  bool matches(FileMetadata file) {
    if (!isEnabled) return false;

    // Check file type match
    if (fileType != null && file.fileType != fileType) {
      return false;
    }

    // Check subject pattern match
    if (subjectPattern != null && file.subject != null) {
      final pattern = RegExp(subjectPattern!, caseSensitive: false);
      return pattern.hasMatch(file.subject!);
    }

    return true;
  }

  OrganizationRule copyWith({
    String? id,
    String? name,
    String? subjectPattern,
    FileType? fileType,
    String? targetFolder,
    int? priority,
    bool? isEnabled,
  }) {
    return OrganizationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      subjectPattern: subjectPattern ?? this.subjectPattern,
      fileType: fileType ?? this.fileType,
      targetFolder: targetFolder ?? this.targetFolder,
      priority: priority ?? this.priority,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
