import '../../domain/entities/document_chunk.dart';

class DocumentChunkModel extends DocumentChunk {
  const DocumentChunkModel({
    super.id,
    required super.fileMetadataId,
    required super.chunkIndex,
    required super.content,
    required super.tokenCount,
    required super.createdAt,
  });

  factory DocumentChunkModel.fromEntity(DocumentChunk chunk) {
    return DocumentChunkModel(
      id: chunk.id,
      fileMetadataId: chunk.fileMetadataId,
      chunkIndex: chunk.chunkIndex,
      content: chunk.content,
      tokenCount: chunk.tokenCount,
      createdAt: chunk.createdAt,
    );
  }

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

  DocumentChunk toEntity() => this;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_metadata_id': fileMetadataId,
      'chunk_index': chunkIndex,
      'content': content,
      'token_count': tokenCount,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
