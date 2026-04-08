/// Document chunk entity for retrieval indexing
class DocumentChunk {
  final int? id;
  final int fileMetadataId;
  final int chunkIndex;
  final String content;
  final int tokenCount;
  final DateTime createdAt;

  const DocumentChunk({
    this.id,
    required this.fileMetadataId,
    required this.chunkIndex,
    required this.content,
    required this.tokenCount,
    required this.createdAt,
  });

  DocumentChunk copyWith({
    int? id,
    int? fileMetadataId,
    int? chunkIndex,
    String? content,
    int? tokenCount,
    DateTime? createdAt,
  }) {
    return DocumentChunk(
      id: id ?? this.id,
      fileMetadataId: fileMetadataId ?? this.fileMetadataId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      content: content ?? this.content,
      tokenCount: tokenCount ?? this.tokenCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
