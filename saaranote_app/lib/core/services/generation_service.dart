import '../../domain/entities/chat_message.dart';
import '../../domain/entities/query_intent.dart';
import '../../domain/entities/retrieval_result.dart';

/// Service for generating responses from retrieved context
class GenerationService {
  Future<GeneratedResponse> generate({
    required String query,
    required List<RetrievalResult> context,
    required QueryIntent intent,
  }) async {
    if (context.isEmpty) {
      return const GeneratedResponse(
        content: "I couldn't find any relevant information in your notes about this topic. Try rephrasing your question or adding more study materials.",
        sources: [],
        confidence: 0.0,
      );
    }

    String content;
    switch (intent) {
      case QueryIntent.questionAnswering:
        content = _answerQuestion(query, context);
        break;
      case QueryIntent.definition:
        content = _generateDefinition(context);
        break;
      case QueryIntent.listExtraction:
        content = _generateList(context);
        break;
      case QueryIntent.summarization:
        content = _generateSummary(context);
        break;
      case QueryIntent.comparison:
        content = _generateComparison(context);
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
  }

  String _answerQuestion(String question, List<RetrievalResult> context) {
    final sentences = context
        .expand((r) => _splitIntoSentences(r.chunk.content))
        .toList();

    if (sentences.isEmpty) {
      return 'No relevant information found.';
    }

    final scored = sentences.map((sentence) {
      final score = _calculateRelevance(question, sentence);
      return (sentence: sentence, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    final topSentences = scored.take(3).map((e) => e.sentence).toList();
    return topSentences.join(' ');
  }

  String _generateDefinition(List<RetrievalResult> context) {
    final sentences = context
        .expand((r) => _splitIntoSentences(r.chunk.content))
        .toList();

    final definitionPattern = RegExp(r'\b(is|are|means|refers to|defined as)\b', caseSensitive: false);
    final definitions = sentences.where((s) => definitionPattern.hasMatch(s)).toList();

    if (definitions.isEmpty) {
      return 'No clear definition found in your notes.';
    }

    return definitions.first;
  }

  String _generateList(List<RetrievalResult> context) {
    final items = <String>{};

    for (final result in context) {
      final lines = result.chunk.content.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();

        if (RegExp(r'^[\-\*•]\s+').hasMatch(trimmed) ||
            RegExp(r'^\d+[\.|\)]\s+').hasMatch(trimmed)) {
          items.add(trimmed.replaceFirst(RegExp(r'^[\-\*•\d\.|\)]+\s+'), ''));
        }
      }
    }

    if (items.isEmpty) {
      return 'No list items found in your notes.';
    }

    return items.map((item) => '• $item').join('\n');
  }

  String _generateSummary(List<RetrievalResult> context) {
    final summary = context.take(3).map((r) {
      final sentences = _splitIntoSentences(r.chunk.content);
      return sentences.isNotEmpty ? sentences.first : '';
    }).where((s) => s.isNotEmpty).join(' ');

    return summary.isNotEmpty ? summary : 'Unable to generate summary.';
  }

  String _generateComparison(List<RetrievalResult> context) {
    final sentences = context
        .expand((r) => _splitIntoSentences(r.chunk.content))
        .toList();

    final comparisonPattern = RegExp(
      r'\b(different|similar|unlike|whereas|while|compared to|than)\b',
      caseSensitive: false,
    );

    final comparisons = sentences.where((s) => comparisonPattern.hasMatch(s)).toList();

    if (comparisons.isEmpty) {
      return 'No comparison information found in your notes.';
    }

    return comparisons.take(2).join(' ');
  }

  List<String> _splitIntoSentences(String text) {
    return text
        .split(RegExp(r'[.!?]+\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  double _calculateRelevance(String query, String sentence) {
    final queryTokens = query.toLowerCase().split(RegExp(r'\s+'));
    final sentenceTokens = sentence.toLowerCase().split(RegExp(r'\s+'));

    final overlap = queryTokens.where((token) => sentenceTokens.contains(token)).length;
    return queryTokens.isEmpty ? 0.0 : overlap / queryTokens.length;
  }

  double _calculateConfidence(List<RetrievalResult> context) {
    if (context.isEmpty) return 0.0;

    final topScore = context.first.score;
    final avgScore = context.map((r) => r.score).reduce((a, b) => a + b) / context.length;
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
}

class GeneratedResponse {
  final String content;
  final List<CitedSource> sources;
  final double confidence;

  const GeneratedResponse({
    required this.content,
    required this.sources,
    required this.confidence,
  });
}
