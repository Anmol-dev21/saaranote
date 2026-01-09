import '../../domain/entities/file_metadata.dart';
import '../../domain/repositories/file_organization_repository.dart';
import '../../core/services/file_organization_service.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Use case for organizing a file automatically
class OrganizeFileUseCase {
  final FileOrganizationRepository _repository;
  final FileOrganizationService _service;

  OrganizeFileUseCase(this._repository, this._service);

  Future<FileMetadata> execute(OrganizeFileParams params) async {
    // Get file info
    final file = File(params.filePath);
    if (!await file.exists()) {
      throw Exception('File not found: ${params.filePath}');
    }

    final fileName = path.basename(params.filePath);
    final extension = path.extension(fileName).replaceFirst('.', '');
    final fileType = FileType.fromExtension(extension);
    final fileSize = await _service.getFileSize(params.filePath);

    // Detect subject if not provided
    String? subject = params.subject;
    if (subject == null && params.autoDetectSubject) {
      subject = await _service.detectSubject(fileName);
    }

    // Create metadata
    var metadata = FileMetadata(
      filePath: params.filePath,
      fileName: fileName,
      fileType: fileType,
      subject: subject,
      createdAt: params.createdAt ?? DateTime.now(),
      fileSize: fileSize,
      relatedNoteId: params.relatedNoteId,
      organizationStatus: OrganizationStatus.pending,
      customFolder: params.customFolder,
      tags: params.tags,
    );

    // Check if file already indexed
    final existing = await _repository.getFileByPath(params.filePath);
    if (existing != null) {
      metadata = existing;
    }

    try {
      // Organize the file
      final newPath = await _service.organizeFile(metadata);

      // Update metadata with new path
      metadata = metadata.copyWith(
        filePath: newPath,
        organizationStatus: OrganizationStatus.organized,
        lastModified: DateTime.now(),
      );

      // Save or update in repository
      if (existing != null) {
        return await _repository.updateFile(metadata);
      } else {
        return await _repository.addFile(metadata);
      }
    } catch (e) {
      // Mark as failed
      metadata = metadata.copyWith(
        organizationStatus: OrganizationStatus.failed,
      );

      if (existing != null) {
        await _repository.updateFile(metadata);
      } else {
        await _repository.addFile(metadata);
      }

      rethrow;
    }
  }
}

class OrganizeFileParams {
  final String filePath;
  final String? subject;
  final bool autoDetectSubject;
  final DateTime? createdAt;
  final String? relatedNoteId;
  final String? customFolder;
  final Map<String, String>? tags;

  OrganizeFileParams({
    required this.filePath,
    this.subject,
    this.autoDetectSubject = true,
    this.createdAt,
    this.relatedNoteId,
    this.customFolder,
    this.tags,
  });
}
