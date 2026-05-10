import 'text_processor.dart';

/// Generates simple, student-friendly headings and titles.
class HeadingGenerator {
  static String generateTitle(
    String text, {
    List<String>? keywords,
    int maxWords = 6,
  }) {
    final sentences = TextProcessor.splitIntoSentences(text);
    if (sentences.isNotEmpty) {
      final first = sentences.first.trim();
      final leadTitle = _titleFromLeadSentence(first, maxWords: maxWords);
      if (leadTitle.isNotEmpty) {
        return leadTitle;
      }
    }

    final keywordTitle = _titleFromKeywords(keywords ?? [], maxWords: maxWords);
    return keywordTitle.isEmpty ? 'Summary' : keywordTitle;
  }

  static String generateHeading(
    List<String> keywords, {
    int maxWords = 4,
    String fallback = 'Overview',
  }) {
    final heading = _titleFromKeywords(keywords, maxWords: maxWords);
    return heading.isEmpty ? fallback : heading;
  }

  static String _titleFromKeywords(List<String> keywords, {int maxWords = 4}) {
    if (keywords.isEmpty) return '';
    final words = <String>[];

    for (final keyword in keywords) {
      if (words.length >= maxWords) break;
      final token = keyword.trim();
      if (token.isEmpty) continue;
      if (TextProcessor.isStopword(token.toLowerCase())) continue;
      if (words.contains(token)) continue;
      words.add(token);
    }

    if (words.isEmpty) return '';
    return _capitalizeWords(words).join(' ');
  }

  static String _titleFromLeadSentence(String sentence, {int maxWords = 6}) {
    if (sentence.isEmpty) return '';
    final tokens = sentence
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (tokens.isEmpty) return '';

    final verbIndex = _firstVerbIndex(tokens);
    final limit = verbIndex > 1 ? verbIndex : tokens.length;

    final words = <String>[];
    for (int i = 0; i < limit && words.length < maxWords; i++) {
      final token = tokens[i];
      final normalized = token.toLowerCase();
      if (TextProcessor.isStopword(normalized)) continue;
      words.add(token);
      if (words.length >= 2 && verbIndex == i + 1) break;
    }

    if (words.length >= 2) {
      return _capitalizeWords(words).join(' ');
    }

    return '';
  }

  static int _firstVerbIndex(List<String> tokens) {
    for (int i = 0; i < tokens.length; i++) {
      final word = tokens[i].toLowerCase();
      if (_verbStarters.contains(word)) {
        return i;
      }
    }
    return -1;
  }


  static List<String> _capitalizeWords(List<String> words) {
    return words.map((word) {
      if (word.isEmpty) return word;
      if (word.toUpperCase() == word) return word;
      final first = word[0].toUpperCase();
      return first + word.substring(1);
    }).toList();
  }

  static const Set<String> _verbStarters = {
    'is',
    'are',
    'was',
    'were',
    'means',
    'refers',
    'refers to',
    'enables',
    'allows',
    'uses',
    'includes',
    'involves',
    'describes',
    'covers',
    'supports',
  };
}
