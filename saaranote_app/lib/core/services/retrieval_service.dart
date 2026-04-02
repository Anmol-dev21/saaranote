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
    return await _keywordRetrieval(query, limit);
  }

  Future<List<RetrievalResult>> _keywordRetrieval(
    String query,
    int limit,
  ) async {
    final normalizedQuery = _normalizeQuery(query);
    return await _indexRepository.keywordSearch(normalizedQuery, limit);
  }

  String _normalizeQuery(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
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
