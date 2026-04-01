import 'utils/keyword_extractor.dart';
import 'utils/sentence_ranker.dart';
import 'utils/text_processor.dart';

/// Offline-first AI engine for deterministic summarization and key points
class AIEngine {
  Future<SummaryResult> generateSummary({
    required String text,
    int maxChars = 8000,
    int shortMaxSentences = 2,
    int detailedMaxSentences = 6,
    int keyPointMax = 7,
    int maxKeywords = 12,
  }) async {
    try {
      final cleaned = TextProcessor.cleanText(text);
      if (cleaned.isEmpty) return SummaryResult.empty();

      final truncated = _truncate(cleaned, maxChars);
      final keywords = KeywordExtractor.extractKeywords(
        truncated,
        maxKeywords: maxKeywords,
        maxChars: maxChars,
      );

      final shortSummarySentences = SentenceRanker.rankSentences(
        truncated,
        maxSentences: shortMaxSentences,
        keywords: keywords,
      );

      final detailedSummarySentences = SentenceRanker.rankSentences(
        truncated,
        maxSentences: detailedMaxSentences,
        keywords: keywords,
      );

      final keyPoints = SentenceRanker.rankSentences(
        truncated,
        maxSentences: keyPointMax,
        keywords: keywords,
        forKeyPoints: true,
      );

      return SummaryResult(
        shortSummary: shortSummarySentences.join(' '),
        keyPoints: keyPoints,
        detailedSummary: detailedSummarySentences.join(' '),
        keywords: keywords,
      );
    } catch (_) {
      return SummaryResult.empty();
    }
  }

  Future<KeyPointsResult> extractKeyPoints({
    required String text,
    int maxChars = 8000,
    int maxPoints = 10,
    int maxKeywords = 12,
  }) async {
    try {
      final cleaned = TextProcessor.cleanText(text);
      if (cleaned.isEmpty) return KeyPointsResult.empty();

      final truncated = _truncate(cleaned, maxChars);
      final keywords = KeywordExtractor.extractKeywords(
        truncated,
        maxKeywords: maxKeywords,
        maxChars: maxChars,
      );

      final points = SentenceRanker.rankSentences(
        truncated,
        maxSentences: maxPoints,
        keywords: keywords,
        forKeyPoints: true,
      );

      return KeyPointsResult(
        points: points,
        keywords: keywords,
      );
    } catch (_) {
      return KeyPointsResult.empty();
    }
  }

  String _truncate(String text, int maxChars) {
    if (maxChars <= 0 || text.length <= maxChars) return text;
    return text.substring(0, maxChars);
  }
}

class SummaryResult {
  final String shortSummary;
  final List<String> keyPoints;
  final String detailedSummary;
  final List<String> keywords;

  const SummaryResult({
    required this.shortSummary,
    required this.keyPoints,
    required this.detailedSummary,
    required this.keywords,
  });

  factory SummaryResult.empty() => const SummaryResult(
        shortSummary: '',
        keyPoints: [],
        detailedSummary: '',
        keywords: [],
      );
}

class KeyPointsResult {
  final List<String> points;
  final List<String> keywords;

  const KeyPointsResult({
    required this.points,
    required this.keywords,
  });

  factory KeyPointsResult.empty() => const KeyPointsResult(
        points: [],
        keywords: [],
      );
}
