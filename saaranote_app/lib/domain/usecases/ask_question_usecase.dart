import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../../core/services/generation_service.dart';
import '../../core/services/retrieval_service.dart';
import '../entities/retrieval_result.dart';

/// Use case for asking a question in offline chat.
///
/// Stores the user message and a generated response in the chat repository.
class AskQuestionUseCase {
  final ChatRepository _chatRepository;
  final GenerationService _generationService;
  final QueryProcessor _queryProcessor;

  AskQuestionUseCase(
    this._chatRepository,
    this._generationService,
    this._queryProcessor,
  );

  Future<void> execute(AskQuestionParams params) async {
    final now = DateTime.now();

    final userMessage = ChatMessage(
      content: params.question,
      role: MessageRole.user,
      timestamp: now,
      status: MessageStatus.sent,
    );

    await _chatRepository.addMessage(userMessage, params.sessionId);

    final intent = _queryProcessor.classifyIntent(params.question);
    final response = await _generationService.generate(
      query: params.question,
      context: const <RetrievalResult>[],
      intent: intent,
    );

    final assistantMessage = ChatMessage(
      content: response.content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      sources: response.sources.isEmpty ? null : response.sources,
    );

    await _chatRepository.addMessage(assistantMessage, params.sessionId);
  }
}

class AskQuestionParams {
  final String question;
  final int sessionId;

  AskQuestionParams({
    required this.question,
    required this.sessionId,
  });
}
