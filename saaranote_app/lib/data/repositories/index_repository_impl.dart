import 'package:flutter/foundation.dart';
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
    final id = await db.insert('document_chunks', model.toMap());
    debugPrint(
      'Indexing: inserted chunk id=$id file=${chunk.fileMetadataId} index=${chunk.chunkIndex}',
    );
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

    List<Map<String, Object?>> results = [];
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
        ORDER BY score ASC
        LIMIT ?
      ''', [query, limit]);
      debugPrint('Retrieval: FTS results count=${results.length}');
    } on DatabaseException {
      debugPrint('Retrieval: FTS unavailable, using LIKE fallback');
      results = await _likeSearch(db, query, limit);
    }

    if (results.isEmpty) {
      debugPrint('Retrieval: FTS empty, using LIKE fallback');
      results = await _likeSearch(db, query, limit);
      debugPrint('Retrieval: LIKE results count=${results.length}');
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
            ? 1.0 / (1.0 + (row['score'] as num).abs())
            : 0.0;

      return RetrievalResult(
        chunk: chunk,
        score: score,
        method: RetrievalMethod.keyword,
      );
    }).toList();
  }

  Future<List<Map<String, Object?>>> _likeSearch(
    Database db,
    String query,
    int limit,
  ) async {
    final tokens = query
        .split(RegExp(r'\s+'))
      .where((token) => token.trim().isNotEmpty)
      .where((token) => token.toLowerCase() != 'or')
        .toList();

    if (tokens.isEmpty) return [];

    final whereClause = tokens.map((_) => 'content LIKE ?').join(' OR ');
    final args = tokens.map((token) => '%$token%').toList();

    return db.rawQuery('''
      SELECT 
        id,
        file_metadata_id,
        chunk_index,
        content,
        token_count,
        created_at
      FROM document_chunks
      WHERE $whereClause
      ORDER BY created_at DESC
      LIMIT ?
    ''', [...args, limit]);
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

  Future<int> getFtsCount() async {
    final db = await _databaseHelper.database;
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM document_chunks_fts',
      );
      return result.first['count'] as int? ?? 0;
    } on DatabaseException {
      return -1;
    }
  }

  Future<DebugSearchResult> debugSearch(String query, int limit) async {
    final db = await _databaseHelper.database;

    List<Map<String, Object?>> ftsResults = [];
    bool ftsAvailable = true;
    String? ftsError;

    try {
      ftsResults = await db.rawQuery('''
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
        ORDER BY score ASC
        LIMIT ?
      ''', [query, limit]);
    } on DatabaseException catch (e) {
      ftsAvailable = false;
      ftsError = e.toString();
    }

    final likeResults = await _likeSearch(db, query, limit);

    return DebugSearchResult(
      ftsResults: _mapRowsToResults(ftsResults),
      likeResults: _mapRowsToResults(likeResults),
      ftsAvailable: ftsAvailable,
      ftsError: ftsError,
    );
  }

  List<RetrievalResult> _mapRowsToResults(List<Map<String, Object?>> rows) {
    return rows.map((row) {
      final chunk = DocumentChunk(
        id: row['id'] as int,
        fileMetadataId: row['file_metadata_id'] as int,
        chunkIndex: row['chunk_index'] as int,
        content: row['content'] as String,
        tokenCount: row['token_count'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      );

      final score = row['score'] is num
          ? 1.0 / (1.0 + (row['score'] as num).abs())
          : 0.0;

      return RetrievalResult(
        chunk: chunk,
        score: score,
        method: RetrievalMethod.keyword,
      );
    }).toList();
  }
}

class DebugSearchResult {
  final List<RetrievalResult> ftsResults;
  final List<RetrievalResult> likeResults;
  final bool ftsAvailable;
  final String? ftsError;

  const DebugSearchResult({
    required this.ftsResults,
    required this.likeResults,
    required this.ftsAvailable,
    required this.ftsError,
  });
}
