import 'text_processor.dart';

/// Rule-based text summarization utilities
class Summarizer {
  /// Generate a summary of the text using extractive summarization
  /// 
  /// Uses a simple scoring system based on:
  /// - Position (first sentences are important)
  /// - Length (very short or very long sentences are less important)
  /// - Keywords (sentences with important keywords score higher)
  /// - Sentence structure
  static String generateSummary(String text, {int maxSentences = 3}) {
    if (text.isEmpty) return '';

    final sentences = TextProcessor.splitIntoSentences(text);
    
    if (sentences.isEmpty) return '';
    if (sentences.length <= maxSentences) {
      return sentences.join(' ');
    }

    // Score each sentence
    final scoredSentences = <_ScoredSentence>[];
    
    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final score = _scoreSentence(sentence, i, sentences.length, text);
      scoredSentences.add(_ScoredSentence(sentence, score, i));
    }

    // Sort by score (descending) and take top sentences
    scoredSentences.sort((a, b) => b.score.compareTo(a.score));
    final topSentences = scoredSentences.take(maxSentences).toList();

    // Sort by original position to maintain flow
    topSentences.sort((a, b) => a.position.compareTo(b.position));

    // Join selected sentences
    return topSentences.map((s) => s.sentence).join(' ');
  }

  /// Generate a brief one-line summary
  static String generateBriefSummary(String text) {
    return generateSummary(text, maxSentences: 1);
  }

  /// Generate a detailed summary
  static String generateDetailedSummary(String text) {
    final wordCount = TextProcessor.countWords(text);
    final sentenceCount = TextProcessor.splitIntoSentences(text).length;
    
    // Calculate appropriate summary length based on content
    int maxSentences;
    if (wordCount < 100) {
      maxSentences = 2;
    } else if (wordCount < 300) {
      maxSentences = 3;
    } else if (wordCount < 600) {
      maxSentences = 5;
    } else {
      maxSentences = (sentenceCount * 0.3).ceil().clamp(5, 10);
    }
    
    return generateSummary(text, maxSentences: maxSentences);
  }

  /// Score a sentence based on various features
  static double _scoreSentence(
    String sentence,
    int position,
    int totalSentences,
    String fullText,
  ) {
    double score = 0.0;

    // Position score - first and last sentences are often important
    if (position == 0) {
      score += 3.0; // First sentence bonus
    } else if (position == totalSentences - 1) {
      score += 1.5; // Last sentence bonus
    } else if (position < 3) {
      score += 2.0; // Early sentences bonus
    }

    // Length score - prefer medium-length sentences
    final wordCount = TextProcessor.countWords(sentence);
    if (wordCount >= 10 && wordCount <= 30) {
      score += 2.0;
    } else if (wordCount >= 5 && wordCount <= 40) {
      score += 1.0;
    } else if (wordCount < 5) {
      score -= 1.0; // Penalize very short sentences
    }

    // Keyword score - sentences with important keywords
    final keywords = [
      'important', 'significant', 'key', 'essential', 'critical',
      'main', 'primary', 'major', 'fundamental', 'crucial',
      'therefore', 'thus', 'consequently', 'because', 'since',
      'however', 'although', 'despite', 'nevertheless',
      'first', 'second', 'third', 'finally', 'lastly',
      'define', 'definition', 'means', 'refers', 'describes',
      'shows', 'demonstrates', 'proves', 'indicates',
    ];

    final lowerSentence = sentence.toLowerCase();
    for (final keyword in keywords) {
      if (lowerSentence.contains(keyword)) {
        score += 1.0;
      }
    }

    // Question sentences might be important
    if (sentence.contains('?')) {
      score += 0.5;
    }

    // Sentences with numbers/data often contain important info
    if (RegExp(r'\d+').hasMatch(sentence)) {
      score += 1.0;
    }

    // Quoted text might be important
    if (sentence.contains('"') || sentence.contains("'")) {
      score += 0.5;
    }

    // Check for definition patterns
    if (RegExp(r'\b(is|are|means|refers to|defined as)\b', caseSensitive: false)
        .hasMatch(sentence)) {
      score += 1.5;
    }

    // Avoid sentences that are too similar to headings
    if (TextProcessor.isLikelyHeading(sentence)) {
      score -= 0.5;
    }

    return score;
  }
}

/// Internal class for scoring sentences
class _ScoredSentence {
  final String sentence;
  final double score;
  final int position;

  _ScoredSentence(this.sentence, this.score, this.position);
}
