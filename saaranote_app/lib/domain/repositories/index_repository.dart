import '../entities/document_chunk.dart';
import '../entities/retrieval_result.dart';

abstract class IndexRepository {
  Future<void> addChunk(DocumentChunk chunk);
  Future<void> deleteChunksByFileId(int fileMetadataId);
  Future<DocumentChunk?> getChunk(int id);
  Future<List<DocumentChunk>> getChunksByFileId(int fileMetadataId);
  Future<List<DocumentChunk>> getAllChunks();
  Future<List<RetrievalResult>> keywordSearch(String query, int limit);
  Future<Map<String, dynamic>> getIndexStats();
}
