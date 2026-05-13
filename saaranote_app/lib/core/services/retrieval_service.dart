import 'package:flutter/foundation.dart';
import '../../domain/entities/query_intent.dart';
import '../../domain/entities/retrieval_result.dart';
import '../../domain/repositories/index_repository.dart';

/// Service for retrieving relevant document chunks based on queries
class RetrievalService {
  final IndexRepository _indexRepository;

  RetrievalService(this._indexRepository);

  Future<List<RetrievalResult>> retrieve({
    required String query,
    required int limit,
  }) async {
    final normalizedQuery = _normalizeQuery(query);
    if (normalizedQuery.isEmpty) {
      _logResults(query, normalizedQuery, const []);
      return [];
    }

    var results = await _keywordRetrieval(normalizedQuery, limit);

    if (results.isEmpty) {
      final orQuery = _buildOrQuery(normalizedQuery);
      if (orQuery != null) {
        debugPrint('Retrieval: FTS fallback OR query="$orQuery"');
        results = await _keywordRetrieval(orQuery, limit);
        debugPrint('Retrieval: OR results count=${results.length}');
      }
    }

    if (results.isEmpty) {
      final tokenResults = await _tokenFallbackSearch(normalizedQuery, limit);
      if (tokenResults.isNotEmpty) {
        debugPrint('Retrieval: token fallback results count=${tokenResults.length}');
        results = tokenResults;
      }
    }

    _logResults(query, normalizedQuery, results);
    return results;
  }

  Future<List<RetrievalResult>> _keywordRetrieval(
    String normalizedQuery,
    int limit,
  ) async {
    return await _indexRepository.keywordSearch(normalizedQuery, limit);
  }

  String _normalizeQuery(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _buildOrQuery(String normalizedQuery) {
    final tokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .toList();

    if (tokens.length < 2) return null;
    return tokens.join(' OR ');
  }

  Future<List<RetrievalResult>> _tokenFallbackSearch(
    String normalizedQuery,
    int limit,
  ) async {
    final tokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .toSet()
        .toList();

    if (tokens.length < 2) return [];

    final Map<int, RetrievalResult> merged = {};
    for (final token in tokens) {
      final results = await _indexRepository.keywordSearch(token, limit);
      for (final result in results) {
        final id = result.chunk.id;
        if (id == null) continue;
        final existing = merged[id];
        if (existing == null || result.score > existing.score) {
          merged[id] = result;
        }
      }
    }

    final mergedList = merged.values.toList();
    mergedList.sort((a, b) => b.score.compareTo(a.score));
    if (mergedList.length > limit) {
      return mergedList.take(limit).toList();
    }
    return mergedList;
  }

  void _logResults(
    String query,
    String normalizedQuery,
    List<RetrievalResult> results,
  ) {
    final topScores = results
        .take(3)
        .map((r) => r.score.toStringAsFixed(3))
        .join(', ');
    debugPrint(
      'Retrieval: query="$query" normalized="$normalizedQuery" '
      'count=${results.length} '
      'topScores=[${topScores.isEmpty ? 'n/a' : topScores}]',
    );
  }

  String debugNormalizeQuery(String query) => _normalizeQuery(query);

  String? debugOrQuery(String normalizedQuery) => _buildOrQuery(normalizedQuery);
}

/// Query processor for understanding user intent
class QueryProcessor {
  QueryIntent classifyIntent(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('summarize') ||
        lowerQuery.contains('summary') ||
        lowerQuery.contains('overview') ||
        lowerQuery.contains('give me an overview')) {
      return QueryIntent.summarization;
    }

    if (lowerQuery.startsWith('list') ||
        lowerQuery.contains('find all') ||
        lowerQuery.contains('show all') ||
        lowerQuery.contains('what are the')) {
      return QueryIntent.listExtraction;
    }

    if (lowerQuery.startsWith('define') ||
        lowerQuery.startsWith('what is') ||
        lowerQuery.startsWith('what does') ||
        lowerQuery.contains('meaning of')) {
      return QueryIntent.definition;
    }

    if (lowerQuery.contains('compare') ||
        lowerQuery.contains('difference between') ||
        lowerQuery.contains('vs') ||
        lowerQuery.contains('versus')) {
      return QueryIntent.comparison;
    }

    return QueryIntent.questionAnswering;
  }

  String normalizeQuery(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
