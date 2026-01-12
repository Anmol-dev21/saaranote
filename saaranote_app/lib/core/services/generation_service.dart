import '../../domain/entities/chat_message.dart';
import '../../domain/entities/query_intent.dart';
import '../../domain/entities/retrieval_result.dart';

/// Service for generating responses from retrieved context
/// Uses extractive and template-based methods - NO LLMs
class GenerationService {
  /// Generate a response based on query and context
  Future<GeneratedResponse> generate({
    required String query,
    required List<RetrievalResult> context,
    required QueryIntent intent,
  }) async {
    // Anti-hallucination: NO context = NO answer
    if (context.isEmpty) {
      return GeneratedResponse(
        content: "I couldn't find any relevant information in your notes about this topic. "
            "Try rephrasing your question or adding more study materials.",
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
      fileName: 'Document', // Will be populated from DB
      chunkId: r.chunk.id!,
      excerpt: r.chunk.content.length > 150
          ? '${r.chunk.content.substring(0, 150)}...'
          : r.chunk.content,
      relevanceScore: r.score,
    )).toList();

    final confidence = _calculateConfidence(context);

    // Add confidence warning if low
    if (confidence < 0.5) {
      content = "⚠️ Low confidence answer:\n\n$content\n\nConsider reviewing the sources for accuracy.";
    }

    return GeneratedResponse(
      content: _formatWithCitations(content, sources),
      sources: sources,
      confidence: confidence,
    );
  }

  /// Extractive question answering
  String _answerQuestion(String question, List<RetrievalResult> context) {
    // Extract most relevant sentences
    final sentences = context
        .expand((r) => _splitIntoSentences(r.chunk.content))
        .toList();

    if (sentences.isEmpty) {
      return "No relevant information found.";
    }

    // Score sentences by relevance
    final scored = sentences.map((sentence) {
      final score = _calculateRelevance(question, sentence);
      return (sentence: sentence, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    // Take top 3 sentences
    final topSentences = scored.take(3).map((e) => e.sentence).toList();

    return topSentences.join(' ');
  }

  /// Generate definition from context
  String _generateDefinition(List<RetrievalResult> context) {
    // Look for sentences with definition keywords
    final sentences = context
        .expand((r) => _splitIntoSentences(r.chunk.content))
        .toList();

    final definitionPattern = RegExp(r'\b(is|are|means|refers to|defined as)\b', caseSensitive: false);

    final definitions = sentences.where((s) => definitionPattern.hasMatch(s)).toList();

    if (definitions.isEmpty) {
      return "No clear definition found in your notes.";
    }

    return definitions.first;
  }

  /// Generate list from context
  String _generateList(List<RetrievalResult> context) {
    final items = <String>{};

    for (final result in context) {
      // Extract bullet points and numbered items
      final lines = result.chunk.content.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();

        // Match bullet points or numbered lists
        if (RegExp(r'^[\-\*•]\s+').hasMatch(trimmed) ||
            RegExp(r'^\d+[\.\)]\s+').hasMatch(trimmed)) {
          items.add(trimmed.replaceFirst(RegExp(r'^[\-\*•\d\.\)]+\s+'), ''));
        }
      }
    }

    if (items.isEmpty) {
      return "No list items found in your notes.";
    }

    return items.map((item) => '• $item').join('\n');
  }

  /// Generate summary from context
  String _generateSummary(List<RetrievalResult> context) {
    // Simple extractive summary: take first sentence from top chunks
    final summary = context.take(3).map((r) {
      final sentences = _splitIntoSentences(r.chunk.content);
      return sentences.isNotEmpty ? sentences.first : '';
    }).where((s) => s.isNotEmpty).join(' ');

    return summary.isNotEmpty ? summary : "Unable to generate summary.";
  }

  /// Generate comparison
  String _generateComparison(List<RetrievalResult> context) {
    // Extract sentences with comparison keywords
    final sentences = context
        .expand((r) => _splitIntoSentences(r.chunk.content))
        .toList();

    final comparisonPattern = RegExp(
      r'\b(different|similar|unlike|whereas|while|compared to|than)\b',
      caseSensitive: false,
    );

    final comparisons = sentences.where((s) => comparisonPattern.hasMatch(s)).toList();

    if (comparisons.isEmpty) {
      return "No comparison information found in your notes.";
    }

    return comparisons.take(2).join(' ');
  }

  /// Split text into sentences
  List<String> _splitIntoSentences(String text) {
    return text
        .split(RegExp(r'[.!?]+\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  /// Calculate relevance between query and sentence
  double _calculateRelevance(String query, String sentence) {
    final queryTokens = query.toLowerCase().split(RegExp(r'\s+'));
    final sentenceTokens = sentence.toLowerCase().split(RegExp(r'\s+'));

    final overlap = queryTokens.where((token) => sentenceTokens.contains(token)).length;

    return queryTokens.isEmpty ? 0.0 : overlap / queryTokens.length;
  }

  /// Calculate confidence score
  double _calculateConfidence(List<RetrievalResult> context) {
    if (context.isEmpty) return 0.0;

    final topScore = context.first.score;
    final avgScore = context.map((r) => r.score).reduce((a, b) => a + b) / context.length;

    // High confidence if top score is significantly higher than average
    final confidence = topScore / (avgScore + 0.1);
    return confidence.clamp(0.0, 1.0);
  }

  /// Format response with citations
  String _formatWithCitations(String content, List<CitedSource> sources) {
    if (sources.isEmpty) return content;

    final citationNumbers = List.generate(sources.length, (i) => i + 1);
    final citedContent = '$content [${citationNumbers.join(',')}]';

    final sourceList = sources.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final source = entry.value;
      return '[$index] ${source.fileName}\n"${source.excerpt}"';
    }).join('\n\n');

    return '''
$citedContent

━━━━━━━━━━━━━━━━━━━━━━
📚 Sources

$sourceList
''';
  }
}

/// Generated response with metadata
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
