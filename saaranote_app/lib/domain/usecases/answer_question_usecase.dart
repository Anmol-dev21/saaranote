import '../../core/services/offline_qa_service.dart';
import '../../core/services/generation_service.dart';

/// Use case for offline question answering
class AnswerQuestionUseCase {
  final OfflineQaService _offlineQaService;

  AnswerQuestionUseCase(this._offlineQaService);

  Future<GeneratedResponse> execute(AnswerQuestionParams params) async {
    try {
      return await _offlineQaService.answer(
        query: params.question,
        limit: params.limit,
        maxChars: params.maxChars,
      );
    } catch (_) {
      return const GeneratedResponse(
        content: 'Sorry, I encountered an error while answering.',
        sources: [],
        confidence: 0.0,
      );
    }
  }
}

class AnswerQuestionParams {
  final String question;
  final int limit;
  final int maxChars;

  const AnswerQuestionParams({
    required this.question,
    this.limit = 5,
    this.maxChars = 8000,
  });
}
