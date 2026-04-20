/// Parses structured summary output from the local LLM.
class SummaryParseResult {
  final String title;
  final String summary;
  final List<String> keyPoints;
  final bool isValid;

  const SummaryParseResult._({
    required this.title,
    required this.summary,
    required this.keyPoints,
    required this.isValid,
  });

  const SummaryParseResult.invalid()
      : title = '',
        summary = '',
        keyPoints = const [],
        isValid = false;
}

class SummaryParser {
  static SummaryParseResult parse(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    String? title;
    String summary = '';
    final keyPoints = <String>[];
    bool inSummary = false;
    bool inKeyPoints = false;

    for (final line in lines) {
      if (line.startsWith('Title:')) {
        title = line.substring('Title:'.length).trim();
        inSummary = false;
        inKeyPoints = false;
        continue;
      }
      if (line.startsWith('Summary:')) {
        summary = line.substring('Summary:'.length).trim();
        inSummary = true;
        inKeyPoints = false;
        continue;
      }
      if (line.startsWith('Key Points:')) {
        inSummary = false;
        inKeyPoints = true;
        continue;
      }

      if (inSummary) {
        summary = summary.isEmpty ? line : '$summary $line';
        continue;
      }

      if (inKeyPoints) {
        final cleaned = line.replaceFirst(RegExp(r'^-\s*'), '').trim();
        if (cleaned.isNotEmpty) {
          keyPoints.add(cleaned);
        }
      }
    }

    if (title == null || title.isEmpty || summary.isEmpty || keyPoints.isEmpty) {
      return const SummaryParseResult.invalid();
    }

    return SummaryParseResult._(
      title: title,
      summary: summary,
      keyPoints: keyPoints,
      isValid: true,
    );
  }
}
