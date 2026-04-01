import 'package:sqflite/sqflite.dart';

import '../../domain/entities/document_chunk.dart';
import '../../domain/entities/retrieval_result.dart';
import '../../domain/repositories/index_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/document_chunk_model.dart';

/// Implementation of IndexRepository using SQLite
class IndexRepositoryImpl implements IndexRepository {
  final DatabaseHelper _databaseHelper;

  IndexRepositoryImpl(this._databaseHelper);

  @override
  Future<void> addChunk(DocumentChunk chunk) async {
    final db = await _databaseHelper.database;
    final model = DocumentChunkModel.fromEntity(chunk);
    await db.insert('document_chunks', model.toMap());
  }

  @override
  Future<void> deleteChunksByFileId(int fileMetadataId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'document_chunks',
      where: 'file_metadata_id = ?',
      whereArgs: [fileMetadataId],
    );
  }

  @override
  Future<DocumentChunk?> getChunk(int id) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'document_chunks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return DocumentChunkModel.fromMap(results.first).toEntity();
  }

  @override
  Future<List<DocumentChunk>> getChunksByFileId(int fileMetadataId) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'document_chunks',
      where: 'file_metadata_id = ?',
      whereArgs: [fileMetadataId],
      orderBy: 'chunk_index ASC',
    );

    return results
        .map((map) => DocumentChunkModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<List<DocumentChunk>> getAllChunks() async {
    final db = await _databaseHelper.database;
    final results = await db.query('document_chunks');

    return results
        .map((map) => DocumentChunkModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<List<RetrievalResult>> keywordSearch(String query, int limit) async {
    final db = await _databaseHelper.database;

    List<Map<String, Object?>> results;
    try {
      results = await db.rawQuery('''
        SELECT 
          dc.id,
          dc.file_metadata_id,
          dc.chunk_index,
          dc.content,
          dc.token_count,
          dc.created_at,
          bm25(document_chunks_fts) as score
        FROM document_chunks_fts
        JOIN document_chunks dc ON document_chunks_fts.rowid = dc.id
        WHERE document_chunks_fts MATCH ?
        ORDER BY score DESC
        LIMIT ?
      ''', [query, limit]);
    } on DatabaseException {
      results = await db.rawQuery('''
        SELECT 
          id,
          file_metadata_id,
          chunk_index,
          content,
          token_count,
          created_at
        FROM document_chunks
        WHERE content LIKE ?
        ORDER BY created_at DESC
        LIMIT ?
      ''', ['%$query%', limit]);
    }

    return results.map((row) {
      final chunk = DocumentChunk(
        id: row['id'] as int,
        fileMetadataId: row['file_metadata_id'] as int,
        chunkIndex: row['chunk_index'] as int,
        content: row['content'] as String,
        tokenCount: row['token_count'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      );

        final score = row['score'] is num
          ? (row['score'] as num).toDouble().abs()
          : 0.0;

      return RetrievalResult(
        chunk: chunk,
        score: score,
        method: RetrievalMethod.keyword,
      );
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> getIndexStats() async {
    final db = await _databaseHelper.database;

    // Get total chunks
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM document_chunks',
    );
    final totalChunks = countResult.first['count'] as int? ?? 0;

    // Get chunks by file
    final fileResult = await db.rawQuery(
      'SELECT file_metadata_id, COUNT(*) as count FROM document_chunks GROUP BY file_metadata_id',
    );

    final chunksByFile = <int, int>{};
    for (final row in fileResult) {
      chunksByFile[row['file_metadata_id'] as int] = row['count'] as int;
    }

    return {
      'totalChunks': totalChunks,
      'chunksByFile': chunksByFile,
    };
  }
}
