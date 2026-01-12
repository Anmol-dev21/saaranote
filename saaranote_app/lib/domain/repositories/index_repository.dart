import '../entities/document_chunk.dart';
import '../entities/retrieval_result.dart';

/// Repository interface for document indexing and retrieval
abstract class IndexRepository {
  /// Add a chunk to the index
  Future<void> addChunk(DocumentChunk chunk);

  /// Delete all chunks for a specific file
  Future<void> deleteChunksByFileId(int fileMetadataId);

  /// Get a specific chunk by ID
  Future<DocumentChunk?> getChunk(int id);

  /// Get all chunks for a specific file
  Future<List<DocumentChunk>> getChunksByFileId(int fileMetadataId);

  /// Get all chunks
  Future<List<DocumentChunk>> getAllChunks();

  /// Perform keyword search using SQLite FTS5
  Future<List<RetrievalResult>> keywordSearch(String query, int limit);

  /// Get statistics about indexed content
  Future<Map<String, dynamic>> getIndexStats();
}
