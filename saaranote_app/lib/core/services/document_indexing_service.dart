import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../../domain/entities/document_chunk.dart';
import '../../domain/entities/file_metadata.dart';
import '../../domain/repositories/file_organization_repository.dart';
import '../../domain/repositories/index_repository.dart';
import '../utils/text_chunker.dart';
import '../utils/text_processor.dart';

/// Builds and stores document chunks for offline retrieval.
class DocumentIndexingService {
  final IndexRepository _indexRepository;
  final FileOrganizationRepository _fileRepository;

  DocumentIndexingService(this._indexRepository, this._fileRepository);

  Future<void> indexNoteContent({
    required int noteId,
    required String title,
    required String content,
    String? sourceFilePath,
    FileType fileType = FileType.note,
  }) async {
    final cleaned = TextProcessor.cleanText(content);
    if (cleaned.isEmpty) {
      debugPrint('Indexing: skip note $noteId (cleaned content empty)');
      return;
    }

    debugPrint(
      'Indexing: start note $noteId type=${fileType.name} '
      'contentLength=${cleaned.length}',
    );

    final fileMetadata = await _ensureFileMetadata(
      noteId: noteId,
      title: title,
      sourceFilePath: sourceFilePath,
      fileType: fileType,
    );

    if (fileMetadata?.id == null) return;
    final fileMetadataId = fileMetadata!.id!;

    debugPrint(
      'Indexing: fileMetadataId=$fileMetadataId noteId=$noteId path=${fileMetadata.filePath}',
    );

    await _indexRepository.deleteChunksByFileId(fileMetadataId);

    final titlePrefix = title.trim().isNotEmpty ? '${title.trim()}.\n\n' : '';
    final combined = '$titlePrefix$cleaned'.trim();
    final chunks = TextChunker.chunkText(combined);

    if (chunks.isEmpty) {
      debugPrint('Indexing: no chunks generated for note $noteId');
      return;
    }

    debugPrint('Indexing: note $noteId chunkCount=${chunks.length}');

    final now = DateTime.now();
    for (int i = 0; i < chunks.length; i++) {
      if (i < 3) {
        debugPrint(
          'Indexing: chunk[$i] tokens=${chunks[i].tokenCount} '
          'preview="${_previewChunk(chunks[i].content)}"',
        );
      }
      final chunk = DocumentChunk(
        fileMetadataId: fileMetadataId,
        chunkIndex: i,
        content: chunks[i].content,
        tokenCount: chunks[i].tokenCount,
        createdAt: now,
      );
      await _indexRepository.addChunk(chunk);
    }

    debugPrint('Indexing: finished note $noteId');
  }

  String _previewChunk(String text) {
    final trimmed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed.length <= 80) return trimmed;
    return '${trimmed.substring(0, 80)}...';
  }

  Future<FileMetadata?> _ensureFileMetadata({
    required int noteId,
    required String title,
    String? sourceFilePath,
    required FileType fileType,
  }) async {
    final relatedNoteId = noteId.toString();
    FileMetadata? existing;

    if (sourceFilePath != null) {
      existing = await _fileRepository.getFileByPath(sourceFilePath);
    }
    existing ??= await _fileRepository.getFileByRelatedNoteId(relatedNoteId);
    if (existing != null) return existing;

    final resolvedPath = sourceFilePath ?? 'note://$relatedNoteId';
    final fileName = sourceFilePath != null
        ? path.basename(sourceFilePath)
        : (title.trim().isEmpty ? 'Note $relatedNoteId' : title.trim());

    final type = sourceFilePath != null
        ? FileType.fromExtension(path.extension(fileName).replaceFirst('.', ''))
        : fileType;

    int fileSize = 0;
    if (sourceFilePath != null) {
      final file = File(sourceFilePath);
      if (await file.exists()) {
        fileSize = await file.length();
      }
    }

    final metadata = FileMetadata(
      filePath: resolvedPath,
      fileName: fileName,
      fileType: type,
      createdAt: DateTime.now(),
      fileSize: fileSize,
      relatedNoteId: relatedNoteId,
      organizationStatus: OrganizationStatus.pending,
    );

    return await _fileRepository.addFile(metadata);
  }
}
