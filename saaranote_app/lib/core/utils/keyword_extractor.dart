import 'text_processor.dart';

/// Lightweight keyword extraction using term frequency and stopword filtering
class KeywordExtractor {
  static List<String> extractKeywords(
    String text, {
    int maxKeywords = 12,
    int maxChars = 8000,
  }) {
    final scores = extractKeywordScores(
      text,
      maxKeywords: maxKeywords,
      maxChars: maxChars,
    );
    return scores.map((s) => s.keyword).toList();
  }

  static List<KeywordScore> extractKeywordScores(
    String text, {
    int maxKeywords = 12,
    int maxChars = 8000,
  }) {
    if (text.isEmpty || maxKeywords <= 0) return [];

    final truncated = _truncate(text, maxChars);
    final tokens = TextProcessor.tokenize(truncated);
    if (tokens.isEmpty) return [];

    final limitedTokens = tokens.length > 2000 ? tokens.take(2000).toList() : tokens;
    final filtered = TextProcessor.removeStopwords(limitedTokens)
        .where((t) => t.length >= 3)
        .toList();

    if (filtered.isEmpty) return [];

    final stemCounts = <String, int>{};
    final stemToForms = <String, Map<String, int>>{};

    for (final token in filtered) {
      final stem = TextProcessor.stemToken(token);
      stemCounts[stem] = (stemCounts[stem] ?? 0) + 1;

      final forms = stemToForms.putIfAbsent(stem, () => <String, int>{});
      forms[token] = (forms[token] ?? 0) + 1;
    }

    final scores = <KeywordScore>[];
    stemCounts.forEach((stem, count) {
      final forms = stemToForms[stem] ?? {};
      final representative = _pickRepresentative(forms, stem);
      final lengthBoost = (representative.length / 6.0).clamp(0.5, 1.5);
      final score = count * lengthBoost;
      scores.add(KeywordScore(representative, score));
    });

    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores.take(maxKeywords).toList();
  }

  static String _pickRepresentative(Map<String, int> forms, String fallback) {
    if (forms.isEmpty) return fallback;
    String best = fallback;
    int bestCount = -1;
    forms.forEach((form, count) {
      if (count > bestCount) {
        best = form;
        bestCount = count;
      }
    });
    return best;
  }

  static String _truncate(String text, int maxChars) {
    if (maxChars <= 0 || text.length <= maxChars) return text;
    return text.substring(0, maxChars);
  }
}

class KeywordScore {
  final String keyword;
  final double score;

  const KeywordScore(this.keyword, this.score);
}
