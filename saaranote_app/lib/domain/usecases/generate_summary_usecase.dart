import '../../core/ai_engine.dart';

/// Use case for generating structured summaries from text
class GenerateSummaryUseCase {
  final AIEngine _aiEngine;

  GenerateSummaryUseCase(this._aiEngine);

  Future<SummaryResult> execute(GenerateSummaryParams params) async {
    try {
      return await _aiEngine.generateSummary(
        text: params.text,
        maxChars: params.maxChars,
        shortMaxSentences: params.shortMaxSentences,
        detailedMaxSentences: params.detailedMaxSentences,
        keyPointMax: params.keyPointMax,
        maxKeywords: params.maxKeywords,
      );
    } catch (_) {
      return SummaryResult.empty();
    }
  }
}

class GenerateSummaryParams {
  final String text;
  final int maxChars;
  final int shortMaxSentences;
  final int detailedMaxSentences;
  final int keyPointMax;
  final int maxKeywords;

  const GenerateSummaryParams({
    required this.text,
    this.maxChars = 8000,
    this.shortMaxSentences = 2,
    this.detailedMaxSentences = 6,
    this.keyPointMax = 7,
    this.maxKeywords = 12,
  });
}
