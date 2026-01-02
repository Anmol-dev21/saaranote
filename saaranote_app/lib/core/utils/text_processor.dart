/// Pure text processing utilities for cleaning and splitting text
class TextProcessor {
  /// Clean raw text by normalizing whitespace, punctuation, and formatting
  static String cleanText(String rawText) {
    if (rawText.isEmpty) return '';

    String cleaned = rawText;

    // Remove excessive whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Normalize line breaks
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Remove leading/trailing whitespace
    cleaned = cleaned.trim();

    // Normalize common punctuation issues
    cleaned = cleaned.replaceAll(RegExp(r'\s+([.,!?;:])'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'([.,!?;:])+'), r'$1');

    // Add space after punctuation if missing
    cleaned = cleaned.replaceAll(RegExp(r'([.,!?;:])([A-Za-z])'), r'$1 $2');

    // Normalize quotes
    cleaned = cleaned.replaceAll(RegExp(r'["""]'), '"');
    cleaned = cleaned.replaceAll(RegExp(r"[''']"), "'");

    // Remove multiple spaces again after transformations
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned.trim();
  }

  /// Split text into sentences using punctuation and capitalization rules
  static List<String> splitIntoSentences(String text) {
    if (text.isEmpty) return [];

    // First, clean the text
    final cleaned = cleanText(text);

    // Split by sentence-ending punctuation followed by space and capital letter
    // or by newlines (paragraph boundaries)
    final List<String> sentences = [];
    
    // Split by common sentence boundaries
    final parts = cleaned.split(RegExp(r'(?<=[.!?])\s+(?=[A-Z])|(?:\n\s*\n)'));
    
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      // Further split if multiple sentences are still together
      final subParts = trimmed.split(RegExp(r'(?<=[.!?])\s+(?=[A-Z])'));
      
      for (final subPart in subParts) {
        final sentence = subPart.trim();
        if (sentence.isNotEmpty) {
          sentences.add(sentence);
        }
      }
    }

    // Handle cases where text doesn't end with punctuation
    if (sentences.isEmpty && cleaned.isNotEmpty) {
      sentences.add(cleaned);
    }

    return sentences;
  }

  /// Count words in text
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    final words = text.split(RegExp(r'\s+'));
    return words.where((word) => word.isNotEmpty).length;
  }

  /// Get reading time estimate in minutes
  static int estimateReadingTime(String text) {
    final wordCount = countWords(text);
    const wordsPerMinute = 200;
    final minutes = (wordCount / wordsPerMinute).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  /// Check if sentence is likely a heading or title
  static bool isLikelyHeading(String sentence) {
    // Headings are typically short and may not end with punctuation
    if (sentence.length > 100) return false;
    
    // Check if it ends without punctuation (common for headings)
    final hasEndPunctuation = RegExp(r'[.!?]$').hasMatch(sentence);
    
    // Check if it's all caps or title case
    final isAllCaps = sentence == sentence.toUpperCase() && 
                      sentence.contains(RegExp(r'[A-Z]'));
    
    return !hasEndPunctuation || isAllCaps;
  }

  /// Extract text statistics
  static Map<String, dynamic> getTextStats(String text) {
    final cleaned = cleanText(text);
    final sentences = splitIntoSentences(cleaned);
    final wordCount = countWords(cleaned);
    final charCount = cleaned.length;
    final readingTime = estimateReadingTime(cleaned);

    return {
      'wordCount': wordCount,
      'characterCount': charCount,
      'sentenceCount': sentences.length,
      'readingTime': readingTime,
      'averageWordsPerSentence': 
          sentences.isEmpty ? 0 : (wordCount / sentences.length).round(),
    };
  }
}
