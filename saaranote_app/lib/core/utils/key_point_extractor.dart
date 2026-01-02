import 'text_processor.dart';

/// Extract key points from text for revision notes and flashcards
class KeyPointExtractor {
  /// Extract key points from text as a list of bullet points
  /// 
  /// Identifies important sentences and facts based on:
  /// - Keywords and phrases
  /// - Definitions
  /// - Lists and enumerations
  /// - Questions and answers
  static List<String> extractKeyPoints(String text, {int maxPoints = 10}) {
    if (text.isEmpty) return [];

    final sentences = TextProcessor.splitIntoSentences(text);
    if (sentences.isEmpty) return [];

    final keyPoints = <_KeyPoint>[];

    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final score = _scoreKeyPoint(sentence, i, sentences.length);
      
      if (score > 1.0) {
        // Clean up the key point
        final cleanedPoint = _cleanKeyPoint(sentence);
        keyPoints.add(_KeyPoint(cleanedPoint, score));
      }
    }

    // Sort by score and take top points
    keyPoints.sort((a, b) => b.score.compareTo(a.score));
    final topPoints = keyPoints.take(maxPoints).toList();

    return topPoints.map((p) => p.point).toList();
  }

  /// Extract key points formatted as a bullet list string
  static String extractKeyPointsAsString(String text, {int maxPoints = 10}) {
    final points = extractKeyPoints(text, maxPoints: maxPoints);
    if (points.isEmpty) return '';
    
    return points.map((point) => '• $point').join('\n');
  }

  /// Extract potential flashcard pairs (question/concept and answer/explanation)
  static List<Map<String, String>> extractFlashcardPairs(String text) {
    if (text.isEmpty) return [];

    final sentences = TextProcessor.splitIntoSentences(text);
    final flashcards = <Map<String, String>>[];

    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      
      // Extract definition-based flashcards
      final definitionCards = _extractDefinitionFlashcards(sentence);
      flashcards.addAll(definitionCards);

      // Extract question-based flashcards
      if (sentence.contains('?') && i + 1 < sentences.length) {
        final question = sentence;
        final answer = sentences[i + 1];
        
        if (!answer.contains('?') && TextProcessor.countWords(answer) >= 3) {
          flashcards.add({
            'question': _cleanKeyPoint(question),
            'answer': _cleanKeyPoint(answer),
          });
        }
      }

      // Extract comparison/contrast flashcards
      final comparisonCards = _extractComparisonFlashcards(sentence);
      flashcards.addAll(comparisonCards);
    }

    return flashcards.take(20).toList(); // Limit to prevent overwhelming output
  }

  /// Score a sentence for key point extraction
  static double _scoreKeyPoint(String sentence, int position, int totalSentences) {
    double score = 0.0;
    final lowerSentence = sentence.toLowerCase();

    // Definition indicators - highly important
    final definitionPatterns = [
      r'\b(is|are|means|refers to|defined as|definition of)\b',
      r'\b(called|known as|termed)\b',
    ];
    for (final pattern in definitionPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(sentence)) {
        score += 3.0;
      }
    }

    // Key concept indicators
    final keyPhrases = [
      'important', 'key', 'essential', 'critical', 'crucial',
      'significant', 'main', 'primary', 'fundamental', 'major',
      'note that', 'remember', 'keep in mind', 'it is important',
    ];
    for (final phrase in keyPhrases) {
      if (lowerSentence.contains(phrase)) {
        score += 2.0;
      }
    }

    // List indicators (numbered or bulleted items)
    if (RegExp(r'^(\d+\.|\d+\)|-|•|\*)').hasMatch(sentence.trim())) {
      score += 1.5;
    }

    // Causal relationships
    final causalWords = ['because', 'since', 'therefore', 'thus', 'hence', 'consequently'];
    for (final word in causalWords) {
      if (lowerSentence.contains(word)) {
        score += 1.5;
      }
    }

    // Contrast and comparison
    final contrastWords = ['however', 'although', 'despite', 'while', 'whereas', 'unlike'];
    for (final word in contrastWords) {
      if (lowerSentence.contains(word)) {
        score += 1.0;
      }
    }

    // Examples often highlight key concepts
    if (lowerSentence.contains('example') || lowerSentence.contains('such as') ||
        lowerSentence.contains('for instance')) {
      score += 1.0;
    }

    // Contains numerical data or facts
    if (RegExp(r'\d+\s*(percent|%|years?|days?|times?)').hasMatch(lowerSentence)) {
      score += 1.5;
    }

    // Questions are often key points
    if (sentence.contains('?')) {
      score += 1.5;
    }

    // Length considerations
    final wordCount = TextProcessor.countWords(sentence);
    if (wordCount >= 8 && wordCount <= 35) {
      score += 1.0;
    } else if (wordCount < 5) {
      score -= 1.0;
    }

    // Position bonus for early sentences
    if (position < 3) {
      score += 0.5;
    }

    return score;
  }

  /// Clean and format a key point
  static String _cleanKeyPoint(String point) {
    String cleaned = point.trim();
    
    // Remove leading bullets or numbers
    cleaned = cleaned.replaceAll(RegExp(r'^(\d+\.|\d+\)|-|•|\*)\s*'), '');
    
    // Ensure first letter is capitalized
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    // Ensure ends with punctuation
    if (!RegExp(r'[.!?]$').hasMatch(cleaned)) {
      cleaned += '.';
    }
    
    return cleaned;
  }

  /// Extract flashcards from definition patterns
  static List<Map<String, String>> _extractDefinitionFlashcards(String sentence) {
    final flashcards = <Map<String, String>>[];
    
    // Pattern: "X is Y" or "X means Y" or "X refers to Y"
    final patterns = [
      RegExp(r'^(.+?)\s+(is|are|means|refers to|defined as)\s+(.+)[.!?]?$',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(sentence);
      if (match != null && match.groupCount >= 3) {
        final concept = match.group(1)?.trim();
        final definition = match.group(3)?.trim();
        
        if (concept != null && definition != null &&
            TextProcessor.countWords(concept) <= 8 &&
            TextProcessor.countWords(definition) >= 3) {
          flashcards.add({
            'question': 'What is $concept?',
            'answer': definition.replaceAll(RegExp(r'[.!?]$'), '') + '.',
          });
        }
      }
    }

    return flashcards;
  }

  /// Extract flashcards from comparison/contrast patterns
  static List<Map<String, String>> _extractComparisonFlashcards(String sentence) {
    final flashcards = <Map<String, String>>[];
    final lowerSentence = sentence.toLowerCase();

    // Look for difference patterns
    if (lowerSentence.contains('difference between') ||
        lowerSentence.contains('differs from') ||
        lowerSentence.contains('unlike')) {
      
      if (TextProcessor.countWords(sentence) <= 40) {
        // Extract the concepts being compared
        final words = sentence.split(RegExp(r'\s+'));
        if (words.length >= 5) {
          flashcards.add({
            'question': 'What is the difference mentioned in: ${sentence.substring(0, sentence.length > 50 ? 50 : sentence.length)}...?',
            'answer': _cleanKeyPoint(sentence),
          });
        }
      }
    }

    return flashcards;
  }
}

/// Internal class for scoring key points
class _KeyPoint {
  final String point;
  final double score;

  _KeyPoint(this.point, this.score);
}
