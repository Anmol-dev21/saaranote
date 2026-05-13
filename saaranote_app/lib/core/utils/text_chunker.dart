import 'text_processor.dart';

class TextChunk {
  final String content;
  final int tokenCount;

  const TextChunk({
    required this.content,
    required this.tokenCount,
  });
}

/// Splits cleaned text into overlapping chunks for retrieval indexing.
class TextChunker {
  static List<TextChunk> chunkText(
    String text, {
    int maxWords = 140,
    int overlapWords = 24,
    int minWords = 20,
  }) {
    final tokens = text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return [];
    if (tokens.length <= maxWords) {
      return [TextChunk(content: tokens.join(' '), tokenCount: tokens.length)];
    }

    final safeOverlap = overlapWords.clamp(0, maxWords - 1);
    final step = (maxWords - safeOverlap) <= 0 ? maxWords : (maxWords - safeOverlap);

    final chunks = <TextChunk>[];
    int start = 0;

    while (start < tokens.length) {
      final end = (start + maxWords).clamp(0, tokens.length);
      final slice = tokens.sublist(start, end);
      if (slice.isEmpty) break;

      final content = slice.join(' ');
      chunks.add(TextChunk(content: content, tokenCount: slice.length));

      if (end >= tokens.length) break;
      start += step;
    }

    if (chunks.length >= 2 && chunks.last.tokenCount < minWords) {
      final last = chunks.removeLast();
      final merged = '${chunks.last.content} ${last.content}'.trim();
      final mergedTokens = TextProcessor.countWords(merged);
      chunks[chunks.length - 1] = TextChunk(content: merged, tokenCount: mergedTokens);
    }

    return chunks;
  }
}
