/// Service for splitting text into manageable chunks for indexing
class ChunkingService {
  /// Split text into chunks with overlap
  Future<List<TextChunk>> chunkText({
    required String text,
    int chunkSize = 400,
    int overlap = 50,
  }) async {
    final sentences = _splitIntoSentences(text);
    final chunks = <TextChunk>[];

    int currentPosition = 0;
    List<String> currentChunk = [];
    int currentTokens = 0;

    for (final sentence in sentences) {
      final tokens = _estimateTokenCount(sentence);

      // If adding this sentence exceeds chunk size, save current chunk
      if (currentTokens + tokens > chunkSize && currentChunk.isNotEmpty) {
        chunks.add(TextChunk(
          content: currentChunk.join(' '),
          tokenCount: currentTokens,
          startPosition: currentPosition,
        ));

        // Start new chunk with overlap
        final overlapSentences = _getOverlapSentences(currentChunk, overlap);
        currentChunk = overlapSentences;
        currentTokens = overlapSentences
            .map((s) => _estimateTokenCount(s))
            .fold(0, (a, b) => a + b);
      }

      currentChunk.add(sentence);
      currentTokens += tokens;
      currentPosition++;
    }

    // Add final chunk
    if (currentChunk.isNotEmpty) {
      chunks.add(TextChunk(
        content: currentChunk.join(' '),
        tokenCount: currentTokens,
        startPosition: currentPosition,
      ));
    }

    return chunks;
  }

  /// Split text into sentences
  List<String> _splitIntoSentences(String text) {
    // Simple sentence splitting on common terminators
    final pattern = RegExp(r'[.!?]+\s+');
    final sentences = text.split(pattern).where((s) => s.trim().isNotEmpty).toList();
    return sentences;
  }

  /// Estimate token count (rough approximation: words + punctuation)
  int _estimateTokenCount(String text) {
    // Rough estimate: split on whitespace and punctuation
    final words = text.split(RegExp(r'\s+'));
    return words.length;
  }

  /// Get sentences for overlap from the end of current chunk
  List<String> _getOverlapSentences(List<String> sentences, int targetTokens) {
    final overlap = <String>[];
    int tokens = 0;

    for (int i = sentences.length - 1; i >= 0; i--) {
      final sentenceTokens = _estimateTokenCount(sentences[i]);
      if (tokens + sentenceTokens > targetTokens) break;

      overlap.insert(0, sentences[i]);
      tokens += sentenceTokens;
    }

    return overlap;
  }
}

/// Represents a text chunk
class TextChunk {
  final String content;
  final int tokenCount;
  final int startPosition;

  const TextChunk({
    required this.content,
    required this.tokenCount,
    required this.startPosition,
  });
}
