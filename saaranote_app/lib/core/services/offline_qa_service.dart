import '../../domain/entities/chat_message.dart';
import '../../domain/entities/query_intent.dart';
import '../../domain/entities/retrieval_result.dart';
import '../utils/keyword_extractor.dart';
import '../utils/sentence_ranker.dart';
import '../utils/text_processor.dart';
import '../utils/summary_formatter.dart';
import '../ai_engine.dart';
import 'generation_service.dart';
import 'retrieval_service.dart';

/// Offline-first QA service with lightweight retrieval reranking
class OfflineQaService {
  final RetrievalService _retrievalService;
  final QueryProcessor _queryProcessor;
  final AIEngine? _aiEngine;

  OfflineQaService({
    required RetrievalService retrievalService,
    required QueryProcessor queryProcessor,
    AIEngine? aiEngine,
  })  : _retrievalService = retrievalService,
        _queryProcessor = queryProcessor,
        _aiEngine = aiEngine;

  Future<GeneratedResponse> answer({
    required String query,
    int limit = 5,
    int maxChars = 8000,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return const GeneratedResponse(
          content: 'Please enter a question.',
          sources: [],
          confidence: 0.0,
        );
      }

      final intent = _queryProcessor.classifyIntent(query);
      final expandedQuery = _expandQuery(query);

      final candidates = await _retrievalService.retrieve(
        query: expandedQuery,
        limit: limit * 2,
      );

      final reranked = _rerankResults(query, candidates, maxChars: maxChars);
      final context = reranked.take(limit).toList();

      if (context.isEmpty) {
        return const GeneratedResponse(
          content: 'No relevant information found in your notes.',
          sources: [],
          confidence: 0.0,
        );
      }

      String content;
      switch (intent) {
        case QueryIntent.questionAnswering:
          content = _answerQuestion(query, context, maxChars: maxChars);
          break;
        case QueryIntent.definition:
          content = _generateDefinition(context, query, maxChars: maxChars);
          break;
        case QueryIntent.listExtraction:
          content = _generateList(context, maxChars: maxChars);
          break;
        case QueryIntent.summarization:
          content = await _generateSummary(context, maxChars: maxChars);
          break;
        case QueryIntent.comparison:
          content = _generateComparison(context, maxChars: maxChars);
          break;
      }

      final sources = context.map((r) => CitedSource(
        fileMetadataId: r.chunk.fileMetadataId,
        fileName: 'Document',
        chunkId: r.chunk.id!,
        excerpt: r.chunk.content.length > 150
            ? '${r.chunk.content.substring(0, 150)}...'
            : r.chunk.content,
        relevanceScore: r.score,
      )).toList();

      final confidence = _calculateConfidence(context);
      if (confidence < 0.5) {
        content = 'LOW CONFIDENCE:\n\n$content';
      }

      return GeneratedResponse(
        content: _formatWithCitations(content, sources),
        sources: sources,
        confidence: confidence,
      );
    } catch (_) {
      return const GeneratedResponse(
        content: 'Sorry, I encountered an error while answering.',
        sources: [],
        confidence: 0.0,
      );
    }
  }

  String _expandQuery(String query) {
    final tokens = TextProcessor.tokenize(query);
    if (tokens.isEmpty) return query;

    final expanded = <String>{};
    for (final token in tokens) {
      expanded.add(token);
      final stem = TextProcessor.stemToken(token);
      expanded.add(stem);
      final synonyms = _synonyms[stem];
      if (synonyms != null) {
        expanded.addAll(synonyms);
      }
    }

    return expanded.join(' ');
  }

  List<RetrievalResult> _rerankResults(
    String query,
    List<RetrievalResult> results, {
    required int maxChars,
  }) {
    if (results.isEmpty) return [];

    final queryTokens = TextProcessor.removeStopwords(
      TextProcessor.tokenize(query).map(TextProcessor.stemToken).toList(),
    ).toSet();

    final queryBigrams = _buildBigrams(queryTokens.toList());

    final reranked = results.map((result) {
      final content = _truncate(result.chunk.content, maxChars);
      final chunkTokens = TextProcessor.removeStopwords(
        TextProcessor.tokenize(content).map(TextProcessor.stemToken).toList(),
      ).toSet();

      final overlap = queryTokens.intersection(chunkTokens).length;
      final coverage = queryTokens.isEmpty ? 0.0 : overlap / queryTokens.length;

      final normalizedContent = TextProcessor.normalizeForScoring(content);
      int phraseHits = 0;
      for (final bigram in queryBigrams) {
        if (normalizedContent.contains(bigram)) {
          phraseHits++;
        }
      }

      final lengthPenalty = content.length > 1200 ? 0.9 : 1.0;
      final score = (coverage * 2.0 + phraseHits * 0.3 + result.score) * lengthPenalty;

      return result.copyWith(
        score: score,
        method: result.method == RetrievalMethod.keyword
            ? RetrievalMethod.hybrid
            : result.method,
      );
    }).toList();

    reranked.sort((a, b) => b.score.compareTo(a.score));
    return reranked;
  }

  String _answerQuestion(
    String query,
    List<RetrievalResult> context, {
    required int maxChars,
  }) {
    final sentences = <String>[];
    for (final result in context) {
      final content = _truncate(result.chunk.content, maxChars);
      sentences.addAll(TextProcessor.splitIntoSentences(content));
    }

    if (sentences.isEmpty) return 'No relevant information found.';

    final queryTokens = TextProcessor.removeStopwords(
      TextProcessor.tokenize(query).map(TextProcessor.stemToken).toList(),
    ).toSet();

    final scored = sentences.map((sentence) {
      final tokens = TextProcessor.removeStopwords(
        TextProcessor.tokenize(sentence).map(TextProcessor.stemToken).toList(),
      ).toSet();

      final overlap = queryTokens.intersection(tokens).length;
      final coverage = queryTokens.isEmpty ? 0.0 : overlap / queryTokens.length;
      final lengthScore = TextProcessor.countWords(sentence) >= 6 ? 0.4 : 0.0;
      final score = coverage + lengthScore;
      return (sentence: sentence, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    final picked = <String>[];
    for (final item in scored) {
      if (picked.length >= 3) break;
      final sentence = item.sentence.trim();
      if (sentence.isEmpty) continue;
      picked.add(sentence);
    }

    return picked.join(' ');
  }

  String _generateDefinition(
    List<RetrievalResult> context,
    String query, {
    required int maxChars,
  }) {
    final sentences = <String>[];
    for (final result in context) {
      sentences.addAll(
        TextProcessor.splitIntoSentences(_truncate(result.chunk.content, maxChars)),
      );
    }

    final definitionPattern =
        RegExp(r'\b(is|are|means|refers to|defined as)\b', caseSensitive: false);

    final candidates = sentences.where((s) => definitionPattern.hasMatch(s)).toList();
    if (candidates.isEmpty) return 'No clear definition found in your notes.';

    final keywords = KeywordExtractor.extractKeywords(query, maxKeywords: 6);
    final ranked = SentenceRanker.rankSentences(
      candidates.join(' '),
      maxSentences: 1,
      keywords: keywords,
      forKeyPoints: true,
    );

    return ranked.isEmpty ? candidates.first : ranked.first;
  }

  String _generateList(List<RetrievalResult> context, {required int maxChars}) {
    final items = <String>{};

    for (final result in context) {
      final lines = _truncate(result.chunk.content, maxChars).split('\n');

      for (final line in lines) {
        final trimmed = line.trim();
        if (RegExp(r'^[\-\*•]\s+').hasMatch(trimmed) ||
            RegExp(r'^\d+[\.|\)]\s+').hasMatch(trimmed)) {
          items.add(trimmed.replaceFirst(RegExp(r'^[\-\*•\d\.|\)]+\s+'), ''));
        }
      }
    }

    if (items.isEmpty) return 'No list items found in your notes.';
    return items.map((item) => '- $item').join('\n');
  }

  Future<String> _generateSummary(List<RetrievalResult> context, {required int maxChars}) async {
    final combined = context
        .map((r) => _truncate(r.chunk.content, maxChars))
        .join(' ');

    if (_aiEngine != null) {
      final structured = await _buildStructuredSummary(combined, maxChars: maxChars);
      if (structured.trim().isNotEmpty) {
        return structured;
      }
    }

    final keywords = KeywordExtractor.extractKeywords(combined, maxKeywords: 8);
    final sentences = SentenceRanker.rankSentences(
      combined,
      maxSentences: 3,
      keywords: keywords,
    );

    return sentences.isEmpty ? 'Unable to generate summary.' : sentences.join(' ');
  }

  Future<String> _buildStructuredSummary(String text, {required int maxChars}) async {
    if (_aiEngine == null) return text;
    final truncated = _truncate(text, maxChars);
    final result = await _aiEngine.generateSummary(text: truncated);
    return SummaryFormatter.formatStructuredSummary(
      result.structured,
      includeSections: true,
      includeDetailed: result.structured.detailedSummary.isNotEmpty,
      simplify: true,
    );
  }

  String _generateComparison(List<RetrievalResult> context, {required int maxChars}) {
    final sentences = <String>[];
    for (final result in context) {
      sentences.addAll(
        TextProcessor.splitIntoSentences(_truncate(result.chunk.content, maxChars)),
      );
    }

    final comparisonPattern = RegExp(
      r'\b(different|similar|unlike|whereas|while|compared to|than)\b',
      caseSensitive: false,
    );

    final comparisons = sentences.where((s) => comparisonPattern.hasMatch(s)).toList();
    if (comparisons.isEmpty) return 'No comparison information found in your notes.';

    return comparisons.take(2).join(' ');
  }

  double _calculateConfidence(List<RetrievalResult> context) {
    if (context.isEmpty) return 0.0;
    final topScore = context.first.score;
    final avgScore = context
        .map((r) => r.score)
        .reduce((a, b) => a + b) /
        context.length;
    final confidence = topScore / (avgScore + 0.1);
    return confidence.clamp(0.0, 1.0);
  }

  String _formatWithCitations(String content, List<CitedSource> sources) {
    if (sources.isEmpty) return content;

    final citationNumbers = List.generate(sources.length, (i) => i + 1);
    final citedContent = '$content [${citationNumbers.join(',')}]';

    final sourceList = sources.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final source = entry.value;
      return '[$index] ${source.fileName}\n"${source.excerpt}"';
    }).join('\n\n');

    return '$citedContent\n\nSOURCES\n\n$sourceList';
  }

  List<String> _buildBigrams(List<String> tokens) {
    if (tokens.length < 2) return [];
    final bigrams = <String>[];
    for (int i = 0; i < tokens.length - 1; i++) {
      bigrams.add('${tokens[i]} ${tokens[i + 1]}');
    }
    return bigrams;
  }

  String _truncate(String text, int maxChars) {
    if (maxChars <= 0 || text.length <= maxChars) return text;
    return text.substring(0, maxChars);
  }

  static const Map<String, List<String>> _synonyms = {
    'define': ['definition', 'meaning', 'explain'],
    'summar': ['summary', 'overview', 'recap'],
    'difference': ['compare', 'contrast'],
    'cause': ['reason', 'because'],
    'benefit': ['advantage', 'pros'],
    'problem': ['issue', 'challenge'],
    'method': ['approach', 'technique'],
  };
}

/// Generated response with metadata
