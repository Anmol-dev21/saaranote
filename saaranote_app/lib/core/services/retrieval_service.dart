import '../../domain/entities/query_intent.dart';
import '../../domain/entities/retrieval_result.dart';
import '../../domain/repositories/index_repository.dart';

/// Service for retrieving relevant document chunks based on queries
class RetrievalService {
  final IndexRepository _indexRepository;

  RetrievalService(this._indexRepository);

  /// Retrieve relevant chunks for a query
  Future<List<RetrievalResult>> retrieve({
    required String query,
    required int limit,
  }) async {
    // For MVP, use keyword-only retrieval (FTS5)
    // Future: Add semantic search and hybrid fusion
    return await _keywordRetrieval(query, limit);
  }

  /// Keyword-based retrieval using SQLite FTS5
  Future<List<RetrievalResult>> _keywordRetrieval(
    String query,
    int limit,
  ) async {
    // Normalize query
    final normalizedQuery = _normalizeQuery(query);

    // Use FTS5 search
    return await _indexRepository.keywordSearch(normalizedQuery, limit);
  }

  /// Normalize query for better search
  String _normalizeQuery(String query) {
    // Remove special characters, lowercase
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// Query processor for understanding user intent
class QueryProcessor {
  /// Classify query intent
  QueryIntent classifyIntent(String query) {
    final lowerQuery = query.toLowerCase();

    // Summarization keywords
    if (lowerQuery.contains('summarize') ||
        lowerQuery.contains('summary') ||
        lowerQuery.contains('overview') ||
        lowerQuery.contains('give me an overview')) {
      return QueryIntent.summarization;
    }

    // List extraction keywords
    if (lowerQuery.startsWith('list') ||
        lowerQuery.contains('find all') ||
        lowerQuery.contains('show all') ||
        lowerQuery.contains('what are the')) {
      return QueryIntent.listExtraction;
    }

    // Definition keywords
    if (lowerQuery.startsWith('define') ||
        lowerQuery.startsWith('what is') ||
        lowerQuery.startsWith('what does') ||
        lowerQuery.contains('meaning of')) {
      return QueryIntent.definition;
    }

    // Comparison keywords
    if (lowerQuery.contains('compare') ||
        lowerQuery.contains('difference between') ||
        lowerQuery.contains('vs') ||
        lowerQuery.contains('versus')) {
      return QueryIntent.comparison;
    }

    // Default to question answering
    return QueryIntent.questionAnswering;
  }

  /// Normalize query text
  String normalizeQuery(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
