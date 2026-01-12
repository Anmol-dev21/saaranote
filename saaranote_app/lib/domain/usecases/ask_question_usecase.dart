import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../../core/services/generation_service.dart';
import '../../core/services/retrieval_service.dart';

/// Use case for asking a question to the AI assistant
class AskQuestionUseCase {
  final ChatRepository _chatRepository;
  final RetrievalService _retrievalService;
  final GenerationService _generationService;
  final QueryProcessor _queryProcessor;

  AskQuestionUseCase({
    required ChatRepository chatRepository,
    required RetrievalService retrievalService,
    required GenerationService generationService,
    required QueryProcessor queryProcessor,
  })  : _chatRepository = chatRepository,
        _retrievalService = retrievalService,
        _generationService = generationService,
        _queryProcessor = queryProcessor;

  /// Execute the use case
  Future<ChatMessage> execute(AskQuestionParams params) async {
    // 1. Save user message
    await _chatRepository.addMessage(
      ChatMessage(
        content: params.question,
        role: MessageRole.user,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      ),
      params.sessionId,
    );

    try {
      // 2. Classify query intent
      final intent = _queryProcessor.classifyIntent(params.question);

      // 3. Retrieve relevant context
      final retrievalResults = await _retrievalService.retrieve(
        query: params.question,
        limit: 5,
      );

      // 4. Generate response
      final response = await _generationService.generate(
        query: params.question,
        context: retrievalResults,
        intent: intent,
      );

      // 5. Save assistant message
      final assistantMessage = await _chatRepository.addMessage(
        ChatMessage(
          content: response.content,
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
          sources: response.sources,
        ),
        params.sessionId,
      );

      return assistantMessage;
    } catch (e) {
      // Error handling: save error message
      return await _chatRepository.addMessage(
        ChatMessage(
          content: "Sorry, I encountered an error: ${e.toString()}",
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          status: MessageStatus.error,
        ),
        params.sessionId,
      );
    }
  }
}

/// Parameters for asking a question
class AskQuestionParams {
  final String question;
  final int sessionId;

  const AskQuestionParams({
    required this.question,
    required this.sessionId,
  });
}
