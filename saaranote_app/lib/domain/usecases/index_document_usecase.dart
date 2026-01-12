import '../entities/document_chunk.dart';
import '../repositories/index_repository.dart';
import '../../core/services/chunking_service.dart';

/// Use case for indexing a document for AI search
class IndexDocumentUseCase {
  final IndexRepository _indexRepository;
  final ChunkingService _chunkingService;

  IndexDocumentUseCase({
    required IndexRepository indexRepository,
    required ChunkingService chunkingService,
  })  : _indexRepository = indexRepository,
        _chunkingService = chunkingService;

  /// Execute the use case
  Future<void> execute(IndexDocumentParams params) async {
    // 1. Extract text content
    final text = params.textContent;

    if (text.isEmpty) {
      return; // Nothing to index
    }

    // 2. Chunk text
    final chunks = await _chunkingService.chunkText(
      text: text,
      chunkSize: 400,
      overlap: 50,
    );

    // 3. Store chunks in database
    for (int i = 0; i < chunks.length; i++) {
      final chunk = DocumentChunk(
        fileMetadataId: params.fileMetadataId,
        chunkIndex: i,
        content: chunks[i].content,
        tokenCount: chunks[i].tokenCount,
        createdAt: DateTime.now(),
      );

      await _indexRepository.addChunk(chunk);
    }
  }
}

/// Parameters for indexing a document
class IndexDocumentParams {
  final int fileMetadataId;
  final String textContent;

  const IndexDocumentParams({
    required this.fileMetadataId,
    required this.textContent,
  });
}
