import 'text_processor.dart';

/// Lightweight extractive sentence ranking for summaries and key points
class SentenceRanker {
  static List<String> rankSentences(
    String text, {
    int maxSentences = 3,
    List<String>? keywords,
    bool forKeyPoints = false,
  }) {
    if (text.isEmpty || maxSentences <= 0) return [];

    final sentences = TextProcessor.splitIntoSentences(text);
    if (sentences.isEmpty) return [];

    final keywordSet = (keywords ?? []).map((k) => k.toLowerCase()).toSet();

    final scored = <_ScoredSentence>[];
    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].trim();
      if (sentence.isEmpty) continue;

      final score = _scoreSentence(
        sentence,
        i,
        sentences.length,
        keywordSet,
        forKeyPoints: forKeyPoints,
      );
      scored.add(_ScoredSentence(sentence, score, i));
    }

    if (scored.isEmpty) return [];

    scored.sort((a, b) => b.score.compareTo(a.score));

    final selected = <_ScoredSentence>[];
    final selectedTokens = <Set<String>>[];

    for (final candidate in scored) {
      if (selected.length >= maxSentences) break;
      final tokens = _sentenceTokens(candidate.sentence);
      if (tokens.isEmpty) continue;

      bool tooSimilar = false;
      for (final existing in selectedTokens) {
        final similarity = _jaccard(tokens, existing);
        if (similarity >= 0.6) {
          tooSimilar = true;
          break;
        }
      }

      if (!tooSimilar) {
        selected.add(candidate);
        selectedTokens.add(tokens);
      }
    }

    if (selected.length < maxSentences) {
      for (final candidate in scored) {
        if (selected.length >= maxSentences) break;
        if (selected.contains(candidate)) continue;
        selected.add(candidate);
      }
    }

    selected.sort((a, b) => a.position.compareTo(b.position));
    return selected
        .map((s) => _cleanSentence(s.sentence))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static double _scoreSentence(
    String sentence,
    int position,
    int totalSentences,
    Set<String> keywords, {
    required bool forKeyPoints,
  }) {
    double score = 0.0;

    final wordCount = TextProcessor.countWords(sentence);
    if (wordCount >= 8 && wordCount <= 25) {
      score += 1.5;
    } else if (wordCount >= 5 && wordCount <= 40) {
      score += 0.5;
    } else if (wordCount < 5) {
      score -= 1.0;
    }

    if (position == 0) {
      score += 2.0;
    } else if (position == 1) {
      score += 1.0;
    } else if (position == totalSentences - 1) {
      score += 0.5;
    }

    if (TextProcessor.isLikelyHeading(sentence)) {
      score -= 1.0;
    }

    if (RegExp(r'\b(is|are|means|refers to|defined as)\b', caseSensitive: false)
        .hasMatch(sentence)) {
      score += forKeyPoints ? 2.5 : 1.5;
    }

    if (RegExp(r'\d+').hasMatch(sentence)) {
      score += 0.8;
    }

    if (sentence.contains('?')) {
      score += forKeyPoints ? 1.5 : 0.5;
    }

    if (RegExp(r'^(\d+\.|\d+\)|-|•|\*)').hasMatch(sentence.trim())) {
      score += forKeyPoints ? 2.0 : 0.8;
    }

    final lowerSentence = sentence.toLowerCase();
    if (lowerSentence.contains('however') ||
        lowerSentence.contains('therefore') ||
        lowerSentence.contains('thus') ||
        lowerSentence.contains('because')) {
      score += 0.6;
    }

    final tokens = _sentenceTokens(sentence);
    int keywordHits = 0;
    for (final token in tokens) {
      if (keywords.contains(token)) {
        keywordHits++;
      }
    }

    if (keywordHits > 0) {
      score += keywordHits * (forKeyPoints ? 1.2 : 1.0);
    }

    return score;
  }

  static Set<String> _sentenceTokens(String sentence) {
    final tokens = TextProcessor.tokenize(sentence);
    if (tokens.isEmpty) return <String>{};
    final filtered = TextProcessor.removeStopwords(tokens)
        .map(TextProcessor.stemToken)
        .where((t) => t.length >= 3)
        .toSet();
    return filtered;
  }

  static double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0.0 : intersection / union;
  }

  static String _cleanSentence(String sentence) {
    String cleaned = sentence.trim();
    cleaned = cleaned.replaceAll(RegExp(r'^(\d+\.|\d+\)|-|•|\*)\s*'), '');
    if (cleaned.isEmpty) return '';
    final first = cleaned[0].toUpperCase();
    cleaned = first + cleaned.substring(1);
    if (!RegExp(r'[.!?]$').hasMatch(cleaned)) {
      cleaned = '$cleaned.';
    }
    return cleaned;
  }
}

class _ScoredSentence {
  final String sentence;
  final double score;
  final int position;

  const _ScoredSentence(this.sentence, this.score, this.position);
}
