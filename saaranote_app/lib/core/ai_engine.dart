import 'utils/keyword_extractor.dart';
import 'utils/sentence_ranker.dart';
import 'utils/text_processor.dart';
import 'utils/heading_generator.dart';

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

      final structured = _buildStructuredSummary(
        text: truncated,
        keywords: keywords,
        shortSummarySentences: shortSummarySentences,
        detailedSummarySentences: detailedSummarySentences,
        keyPointSentences: keyPoints,
        maxKeyPoints: keyPointMax,
      );

      return SummaryResult(
        shortSummary: shortSummarySentences.join(' '),
        keyPoints: keyPoints,
        detailedSummary: detailedSummarySentences.join(' '),
        keywords: keywords,
        structured: structured,
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

  StructuredSummary _buildStructuredSummary({
    required String text,
    required List<String> keywords,
    required List<String> shortSummarySentences,
    required List<String> detailedSummarySentences,
    required List<String> keyPointSentences,
    required int maxKeyPoints,
  }) {
    final sentences = TextProcessor.splitIntoSentences(text);
    if (sentences.isEmpty) return const StructuredSummary.empty();

    final wordCount = TextProcessor.countWords(text);
    final title = HeadingGenerator.generateTitle(text, keywords: keywords);
    final shortSummary = shortSummarySentences.join(' ');
    final detailedSummary = detailedSummarySentences.join(' ');

    final usedTokens = <Set<String>>[];
    final shortTokens = _tokensForSimilarity(shortSummary);
    if (shortTokens.isNotEmpty) {
      usedTokens.add(shortTokens);
    }
    final keyPoints = _buildBullets(
      keyPointSentences,
      maxBullets: maxKeyPoints,
      usedTokens: usedTokens,
    );

    final includeSections = wordCount >= 140 || sentences.length >= 8;
    final includeDetailed = wordCount >= 160;

    final sections = includeSections
        ? _buildSections(
            sentences: sentences,
            keywords: keywords,
            usedTokens: usedTokens,
          )
        : <SummarySection>[];

    return StructuredSummary(
      title: title,
      shortSummary: shortSummary,
      keyPoints: keyPoints,
      sections: sections,
      detailedSummary: includeDetailed ? detailedSummary : '',
    );
  }

  List<SummarySection> _buildSections({
    required List<String> sentences,
    required List<String> keywords,
    required List<Set<String>> usedTokens,
  }) {
    const maxSections = 4;
    const maxSectionBullets = 3;
    const maxSentencesForSections = 120;

    final limitedSentences = sentences.length > maxSentencesForSections
        ? sentences.take(maxSentencesForSections).toList()
        : sentences;

    final topicSeeds = keywords.take(maxSections).toList();
    final seedStems = topicSeeds
        .map((k) => TextProcessor.stemToken(k.toLowerCase()))
        .toList();

    final buckets = <String, List<String>>{};
    for (final seed in topicSeeds) {
      buckets[seed] = [];
    }
    buckets['General'] = [];

    for (final sentence in limitedSentences) {
      final tokens = _tokensForSimilarity(sentence);
      String? matched;
      for (int i = 0; i < seedStems.length; i++) {
        if (tokens.contains(seedStems[i])) {
          matched = topicSeeds[i];
          break;
        }
      }
      buckets[matched ?? 'General']!.add(sentence);
    }

    final sections = <SummarySection>[];
    final usedHeadings = <String>{};

    for (final entry in buckets.entries) {
      if (sections.length >= maxSections) break;
      if (entry.value.length < 2) continue;

      final bucketText = entry.value.join(' ');
      final bucketKeywords = KeywordExtractor.extractKeywords(
        bucketText,
        maxKeywords: 4,
      );

      final heading = HeadingGenerator.generateHeading(
        bucketKeywords.isNotEmpty ? bucketKeywords : [entry.key],
      );
      if (heading.isEmpty || usedHeadings.contains(heading)) continue;

      final ranked = SentenceRanker.rankSentences(
        bucketText,
        maxSentences: maxSectionBullets,
        keywords: bucketKeywords,
        forKeyPoints: true,
      );

      final bullets = _buildBullets(
        ranked,
        maxBullets: maxSectionBullets,
        usedTokens: usedTokens,
      );

      if (bullets.isEmpty) continue;
      usedHeadings.add(heading);
      sections.add(SummarySection(heading: heading, bullets: bullets));
    }

    return sections;
  }

  List<String> _buildBullets(
    List<String> sentences, {
    required int maxBullets,
    required List<Set<String>> usedTokens,
  }) {
    if (sentences.isEmpty || maxBullets <= 0) return [];

    final bullets = <String>[];
    for (final sentence in sentences) {
      if (bullets.length >= maxBullets) break;
      final bullet = _toBullet(sentence);
      if (bullet.isEmpty) continue;

      final tokens = _tokensForSimilarity(bullet);
      if (tokens.isEmpty) continue;

      bool tooSimilar = false;
      for (final existing in usedTokens) {
        if (_jaccard(tokens, existing) >= 0.6) {
          tooSimilar = true;
          break;
        }
      }

      if (tooSimilar) continue;
      bullets.add(bullet);
      usedTokens.add(tokens);
    }

    return bullets;
  }

  String _toBullet(String sentence) {
    String cleaned = sentence.trim();
    cleaned = cleaned.replaceAll(RegExp(r'^(\d+\.|\d+\)|-|\*)\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return '';

    final splitters = [' such as ', ' for example ', ' including ', ';', ' - ', '--', ':'];
    for (final splitter in splitters) {
      final index = cleaned.toLowerCase().indexOf(splitter);
      if (index > 0) {
        cleaned = cleaned.substring(0, index).trim();
        break;
      }
    }

    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length > 16) {
      cleaned = words.take(16).join(' ');
    }

    cleaned = cleaned.replaceAll(RegExp(r'[.!?]+$'), '');
    if (cleaned.isEmpty) return '';

    final first = cleaned[0].toUpperCase();
    cleaned = first + cleaned.substring(1);
    return cleaned;
  }

  Set<String> _tokensForSimilarity(String text) {
    final tokens = TextProcessor.tokenize(text)
        .map(TextProcessor.stemToken)
        .where((t) => t.length >= 3)
        .toList();
    final filtered = TextProcessor.removeStopwords(tokens).toSet();
    return filtered;
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0.0 : intersection / union;
  }
}

class SummaryResult {
  final String shortSummary;
  final List<String> keyPoints;
  final String detailedSummary;
  final List<String> keywords;
  final StructuredSummary structured;

  const SummaryResult({
    required this.shortSummary,
    required this.keyPoints,
    required this.detailedSummary,
    required this.keywords,
    this.structured = const StructuredSummary.empty(),
  });

  factory SummaryResult.empty() => const SummaryResult(
        shortSummary: '',
        keyPoints: [],
        detailedSummary: '',
        keywords: [],
      );
}

class StructuredSummary {
  final String title;
  final String shortSummary;
  final List<String> keyPoints;
  final List<SummarySection> sections;
  final String detailedSummary;

  const StructuredSummary({
    required this.title,
    required this.shortSummary,
    required this.keyPoints,
    required this.sections,
    required this.detailedSummary,
  });

  const StructuredSummary.empty()
      : title = '',
        shortSummary = '',
        keyPoints = const [],
        sections = const [],
        detailedSummary = '';
}

class SummarySection {
  final String heading;
  final List<String> bullets;

  const SummarySection({
    required this.heading,
    required this.bullets,
  });
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
