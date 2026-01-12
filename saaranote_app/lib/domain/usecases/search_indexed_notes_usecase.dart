import '../entities/retrieval_result.dart';
import '../../core/services/retrieval_service.dart';

/// Use case for searching through indexed notes
class SearchIndexedNotesUseCase {
  final RetrievalService _retrievalService;

  SearchIndexedNotesUseCase({
    required RetrievalService retrievalService,
  }) : _retrievalService = retrievalService;

  /// Execute the search
  Future<List<RetrievalResult>> execute(String query) async {
    return await _retrievalService.retrieve(
      query: query,
      limit: 20,
    );
  }
}
