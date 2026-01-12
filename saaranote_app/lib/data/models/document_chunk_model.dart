import '../../domain/entities/document_chunk.dart';

/// Data model for DocumentChunk with database serialization
class DocumentChunkModel extends DocumentChunk {
  const DocumentChunkModel({
    super.id,
    required super.fileMetadataId,
    required super.chunkIndex,
    required super.content,
    required super.tokenCount,
    required super.createdAt,
  });

  /// Create from entity
  factory DocumentChunkModel.fromEntity(DocumentChunk entity) {
    return DocumentChunkModel(
      id: entity.id,
      fileMetadataId: entity.fileMetadataId,
      chunkIndex: entity.chunkIndex,
      content: entity.content,
      tokenCount: entity.tokenCount,
      createdAt: entity.createdAt,
    );
  }

  /// Create from database map
  factory DocumentChunkModel.fromMap(Map<String, dynamic> map) {
    return DocumentChunkModel(
      id: map['id'] as int?,
      fileMetadataId: map['file_metadata_id'] as int,
      chunkIndex: map['chunk_index'] as int,
      content: map['content'] as String,
      tokenCount: map['token_count'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'file_metadata_id': fileMetadataId,
      'chunk_index': chunkIndex,
      'content': content,
      'token_count': tokenCount,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Convert to entity
  DocumentChunk toEntity() {
    return DocumentChunk(
      id: id,
      fileMetadataId: fileMetadataId,
      chunkIndex: chunkIndex,
      content: content,
      tokenCount: tokenCount,
      createdAt: createdAt,
    );
  }
}
