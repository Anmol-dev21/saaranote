/// Pure text processing utilities for cleaning and splitting text
class TextProcessor {
  /// Clean raw text by normalizing whitespace, punctuation, and formatting
  static String cleanText(String rawText) {
    if (rawText.isEmpty) return '';

    String cleaned = rawText;

    // Normalize line endings
    cleaned = cleaned.replaceAll('\r\n', '\n');
    cleaned = cleaned.replaceAll('\r', '\n');

    // Remove common extraction artifacts (PDF/OCR)
    cleaned = cleaned.replaceAll(RegExp(r'\$1'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\$\d+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\f'), ' ');

    // De-hyphenate line breaks (e.g., exam-\nple -> example)
    cleaned = cleaned.replaceAll(RegExp(r'(\w)-\n(\w)'), r'$1$2');

    // Merge broken lines when a sentence continues on the next line
    cleaned = cleaned.replaceAll(RegExp(r'([^\n.!?])\n(?=[a-z])'), r'$1 ');

    // Normalize line breaks while preserving paragraph boundaries
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    cleaned = cleaned.replaceAll('\n\n', ' __PARA_BREAK__ ');
    cleaned = cleaned.replaceAll('\n', ' ');
    cleaned = cleaned.replaceAll('__PARA_BREAK__', '\n\n');

    // Remove excessive whitespace (preserve paragraph breaks)
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r' *\n\n *'), '\n\n');

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
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r' *\n\n *'), '\n\n');

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

  /// Normalize text for lightweight scoring and matching
  static String normalizeForScoring(String text) {
    if (text.isEmpty) return '';
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Tokenize into lowercase words
  static List<String> tokenize(String text) {
    if (text.isEmpty) return [];
    final normalized = normalizeForScoring(text);
    if (normalized.isEmpty) return [];
    return normalized.split(' ').where((t) => t.isNotEmpty).toList();
  }

  /// Simple suffix stripping for lightweight stemming
  static String stemToken(String token) {
    if (token.length <= 3) return token;
    if (token.endsWith('ing') && token.length > 5) {
      return token.substring(0, token.length - 3);
    }
    if (token.endsWith('ed') && token.length > 4) {
      return token.substring(0, token.length - 2);
    }
    if (token.endsWith('es') && token.length > 4) {
      return token.substring(0, token.length - 2);
    }
    if (token.endsWith('s') && token.length > 3) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }

  /// Remove common stopwords for lightweight NLP
  static List<String> removeStopwords(List<String> tokens) {
    if (tokens.isEmpty) return [];
    return tokens.where((token) => !_stopwords.contains(token)).toList();
  }

  /// True if token is a stopword
  static bool isStopword(String token) => _stopwords.contains(token);

  static const Set<String> _stopwords = {
    'a','an','the','and','or','but','if','then','else','when','while','to','of','in','on','for','with','by','from','as','at','be','is','are','was','were','been','being','it','this','that','these','those','i','you','he','she','we','they','them','their','our','your','my','me','him','her','its','do','does','did','doing','have','has','had','having','not','no','yes','can','could','should','would','may','might','will','just','so','than','too','very','about','into','over','after','before','between','through','during','without','within','also','such','some','most','more','many','much','each','few','other','another','same','any','all','both','either','neither','own','because','therefore','thus','however','although','despite'
  };
}
