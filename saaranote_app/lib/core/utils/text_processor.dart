/// Pure text processing utilities for cleaning and splitting text
class TextProcessor {
  /// Clean raw text by normalizing whitespace, punctuation, and formatting
  static String cleanText(String rawText) {
    if (rawText.isEmpty) return '';

    var cleaned = _normalizeLineEndings(rawText);

    // Strip control characters and zero-width noise, preserve newlines.
    cleaned = cleaned.replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
    cleaned = cleaned.replaceAll('\u00ad', '');

    cleaned = _removeOcrArtifacts(cleaned);

    cleaned = _removeDuplicateLines(cleaned);

    // De-hyphenate line breaks (e.g., exam-\nple -> example)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\w)[\-\u2010\u2011\u2013\u2014]\s*\n\s*(\w)'),
      (match) => '${match.group(1)}${match.group(2)}',
    );

    // Remove stray replacement characters from OCR.
    cleaned = cleaned.replaceAll('\uFFFD', '');

    // Merge lines inside paragraphs while preserving bullet lists.
    cleaned = _mergeLinesPreserveParagraphs(cleaned);

    // Normalize common punctuation issues
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\s+([.,!?;:])'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([.,!?;:]){2,}'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'[\-\u2010\u2013\u2014]{2,}'),
      (_) => '-',
    );

    // Add space after punctuation if missing
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([.,!?;:])([A-Za-z0-9])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // Add space between long letter/number boundaries when missing.
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([A-Za-z]{3,})(\d{2,})'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\d{2,})([A-Za-z]{3,})'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // Normalize quotes
    cleaned = cleaned.replaceAll(RegExp(r'[\u201C\u201D]'), '"');
    cleaned = cleaned.replaceAll(RegExp(r'[\u2018\u2019]'), "'");

    // Fix camelCase merge from PDF/OCR (e.g., "textMerge" -> "text Merge")
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([a-z]{3,})([A-Z][a-z]{2,})'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // Remove excessive whitespace (preserve paragraph breaks)
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r' *\n\n *'), '\n\n');

    return cleaned.trim();
  }

  static String _normalizeLineEndings(String text) {
    var normalized = text.replaceAll('\r\n', '\n');
    normalized = normalized.replaceAll('\r', '\n');
    return normalized;
  }

  static String _removeOcrArtifacts(String text) {
    var cleaned = text;

    // Remove common OCR/PDF artifacts.
    cleaned = cleaned.replaceAll(RegExp(r'\$\d+'), ' ');
    cleaned = cleaned.replaceAll('\u00a0', ' ');
    cleaned = cleaned.replaceAll('\f', ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[•·]{2,}'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[<>]{2,}'), ' ');

    // Remove lines that are only noise characters.
    cleaned = cleaned.replaceAll(
      RegExp(r'^[\s|_`~^=]+$', multiLine: true),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'[|_`~^=]{3,}'), ' ');
    cleaned = cleaned.replaceAll(
      RegExp(r'^[\s\-_=]{3,}$', multiLine: true),
      '',
    );

    return cleaned;
  }

  static String _removeDuplicateLines(String text) {
    final lines = _normalizeLineEndings(text).split('\n');
    final buffer = <String>[];
    String? lastNormalized;

    for (final line in lines) {
      final trimmed = line.trim();
      final normalized = trimmed.toLowerCase();
      if (trimmed.isEmpty) {
        buffer.add('');
        lastNormalized = null;
        continue;
      }

      if (normalized == lastNormalized) {
        continue;
      }

      buffer.add(trimmed);
      lastNormalized = normalized;
    }

    return buffer.join('\n');
  }

  static String _mergeLinesPreserveParagraphs(String text) {
    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    final merged = <String>[];

    for (final paragraph in paragraphs) {
      final lines = paragraph.split('\n');
      final nonEmptyLines = lines
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      final preserveLineBreaks = _shouldPreserveLines(nonEmptyLines);
      final buffer = <String>[];
      String? running;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (preserveLineBreaks) {
          if (_isListLine(trimmed)) {
            buffer.add(_normalizeListLine(trimmed));
          } else {
            buffer.add(trimmed);
          }
          continue;
        }

        if (_isListLine(trimmed)) {
          if (running != null && running.trim().isNotEmpty) {
            buffer.add(running.trim());
            running = null;
          }
          buffer.add(_normalizeListLine(trimmed));
          continue;
        }

        if (_isHeadingLine(trimmed)) {
          if (running != null && running.trim().isNotEmpty) {
            buffer.add(running.trim());
            running = null;
          }
          buffer.add(trimmed);
          continue;
        }

        if (running == null) {
          running = trimmed;
        } else {
          if (_shouldStartNewLine(running, trimmed)) {
            buffer.add(running.trim());
            running = trimmed;
            continue;
          }

          final needsSpace = !running.endsWith('-') && !running.endsWith('–');
          running = '${running.trim()}${needsSpace ? ' ' : ''}$trimmed';
        }
      }

      if (running != null && running.trim().isNotEmpty) {
        buffer.add(running.trim());
      }

      if (buffer.isNotEmpty) {
        merged.add(buffer.join('\n'));
      }
    }

    return merged.join('\n\n');
  }

  static bool _shouldPreserveLines(List<String> lines) {
    if (lines.length < 4) return false;
    final totalLength = lines.fold<int>(0, (sum, line) => sum + line.length);
    final averageLength = totalLength / lines.length;
    final punctuationLines = lines.where(_endsWithSentencePunctuation).length;
    final punctuationRatio = punctuationLines / lines.length;

    return averageLength <= 55 && punctuationRatio < 0.4;
  }

  static bool _shouldStartNewLine(String previous, String next) {
    if (_endsWithSentencePunctuation(previous) && _startsNewSentence(next)) {
      return true;
    }

    if (previous.length <= 40 && next.length <= 40 && _startsNewSentence(next)) {
      return true;
    }

    return false;
  }

  static bool _endsWithSentencePunctuation(String line) {
    return RegExp(r'[.!?;:]$').hasMatch(line);
  }

  static bool _startsNewSentence(String line) {
    return RegExp(r'^[A-Z0-9]').hasMatch(line);
  }

  static bool _isListLine(String line) {
    return RegExp(r'^(\d+[\.)]|[\-\*\u2022])\s+').hasMatch(line);
  }

  static bool _isHeadingLine(String line) {
    if (line.length > 80) return false;
    if (_isListLine(line)) return false;

    final wordCount = countWords(line);
    if (wordCount == 0 || wordCount > 10) return false;

    return isLikelyHeading(line);
  }

  static String _normalizeListLine(String line) {
    return line.replaceAllMapped(
      RegExp(r'^([\-\*\u2022])\s+'),
      (match) => '- ',
    );
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
    final parts = cleaned.split(RegExp(
      r'(?<=[.!?])\s+(?=[A-Z])|(?:\n\s*\n)|(?:\n(?=[\-\*\u2022]|\d+[\).]))',
    ));
    
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
