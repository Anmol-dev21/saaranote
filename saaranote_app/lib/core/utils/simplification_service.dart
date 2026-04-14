/// Lightweight, dictionary-based simplifier for student-friendly language.
class SimplificationService {
  static const Map<String, String> _simpleMap = {
    'utilize': 'use',
    'approximately': 'about',
    'demonstrate': 'show',
    'commence': 'start',
    'terminate': 'end',
    'numerous': 'many',
    'facilitate': 'help',
    'sufficient': 'enough',
    'prior': 'before',
    'subsequent': 'after',
    'objective': 'goal',
    'methodology': 'method',
    'conceptual': 'idea-based',
    'comprehension': 'understanding',
    'fundamental': 'basic',
    'significant': 'important',
  };

  static final RegExp _pattern = RegExp(
    '\\b(${_simpleMap.keys.map(RegExp.escape).join('|')})\\b',
    caseSensitive: false,
  );

  static String simplify(String text) {
    if (text.isEmpty) return text;

    return text.replaceAllMapped(_pattern, (match) {
      final original = match.group(0) ?? '';
      if (original.isEmpty) return original;
      if (_isAllCaps(original)) return original;

      final replacement = _simpleMap[original.toLowerCase()];
      if (replacement == null) return original;

      if (_isCapitalized(original)) {
        final first = replacement[0].toUpperCase();
        return first + replacement.substring(1);
      }

      return replacement;
    });
  }

  static List<String> simplifyList(List<String> items) {
    if (items.isEmpty) return items;
    return items.map(simplify).toList();
  }

  static bool _isAllCaps(String token) {
    return token.length > 1 && token == token.toUpperCase();
  }

  static bool _isCapitalized(String token) {
    if (token.isEmpty) return false;
    final first = token[0];
    return first.toUpperCase() == first && token.substring(1) == token.substring(1).toLowerCase();
  }
}
