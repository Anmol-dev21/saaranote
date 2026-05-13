import '../ai_engine.dart';
import 'simplification_service.dart';
import 'text_processor.dart';

/// Formats structured summaries into a readable, student-friendly layout.
class SummaryFormatter {
  static String formatStructuredSummary(
    StructuredSummary summary, {
    bool includeSections = true,
    bool includeDetailed = true,
    bool simplify = true,
  }) {
    if (_isEmpty(summary)) return '';

    final buffer = StringBuffer();
    final title = summary.title.isNotEmpty ? summary.title : 'Summary';
    final sanitizedTitle = _sanitizeLine(title);
    final simplifiedTitle = simplify
        ? SimplificationService.simplify(sanitizedTitle)
        : sanitizedTitle;

    buffer.writeln('Title: $simplifiedTitle');

    final summaryText = summary.shortSummary.isNotEmpty
        ? summary.shortSummary
        : summary.detailedSummary;
    final sanitizedSummary = _limitSummary(_sanitizeParagraph(summaryText));
    buffer.writeln('\nSummary:');
    if (sanitizedSummary.isNotEmpty) {
      buffer.writeln(_maybeSimplify(sanitizedSummary, simplify));
    }

    final keyPoints = _normalizeKeyPoints(
      summary.keyPoints,
      fallbackText: sanitizedSummary,
      maxPoints: 4,
    );
    buffer.writeln('\nKey Points:');
    for (final point in keyPoints) {
      final simplifiedPoint = _maybeSimplify(point, simplify);
      buffer.writeln('- $simplifiedPoint');
    }

    if (includeSections && summary.sections.isNotEmpty) {
      buffer.writeln('\nSections:');
      for (final section in summary.sections) {
        if (section.bullets.isEmpty) continue;
        final simplifiedHeading = _maybeSimplify(
          _sanitizeLine(section.heading),
          simplify,
        );
        buffer.writeln(simplifiedHeading);
        for (final bullet in section.bullets) {
          final simplifiedBullet = _maybeSimplify(
            _limitWords(_sanitizeLine(bullet), 18),
            simplify,
          );
          buffer.writeln('- $simplifiedBullet');
        }
        buffer.writeln('');
      }
    }

    if (includeDetailed && summary.detailedSummary.isNotEmpty &&
        summary.detailedSummary != summaryText) {
      buffer.writeln('\nDetailed:');
      buffer.writeln(_maybeSimplify(summary.detailedSummary, simplify));
    }

    return buffer.toString().trim();
  }

  static String ensureStructuredText(
    String text, {
    String fallbackTitle = 'Summary',
  }) {
    final cleaned = _stripMarkdown(text).trim();
    if (cleaned.isEmpty) return '';

    final parsed = _parseStructuredText(cleaned);
    if (parsed != null) {
      final structured = StructuredSummary(
        title: parsed.title,
        shortSummary: parsed.summary,
        keyPoints: parsed.keyPoints,
        sections: const [],
        detailedSummary: '',
      );
      return formatStructuredSummary(
        structured,
        includeSections: false,
        includeDetailed: false,
        simplify: true,
      );
    }

    final derivedTitle = _deriveTitle(cleaned, fallbackTitle);
    final derivedSummary = _limitSummary(_sanitizeParagraph(cleaned));
    final derivedKeyPoints = _normalizeKeyPoints(
      const [],
      fallbackText: derivedSummary,
      maxPoints: 3,
    );

    final structured = StructuredSummary(
      title: derivedTitle,
      shortSummary: derivedSummary,
      keyPoints: derivedKeyPoints,
      sections: const [],
      detailedSummary: '',
    );

    return formatStructuredSummary(
      structured,
      includeSections: false,
      includeDetailed: false,
      simplify: true,
    );
  }

  static bool _isEmpty(StructuredSummary summary) {
    return summary.title.isEmpty &&
        summary.shortSummary.isEmpty &&
        summary.keyPoints.isEmpty &&
        summary.sections.isEmpty &&
        summary.detailedSummary.isEmpty;
  }

  static String _maybeSimplify(String text, bool simplify) {
    return simplify ? SimplificationService.simplify(text) : text;
  }

  static String _stripMarkdown(String text) {
    var cleaned = text;
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\*\*|__|`'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^>+\s?', multiLine: true), '');
    return cleaned;
  }

  static String _sanitizeLine(String text) {
    final cleaned = _stripMarkdown(text);
    return _removeRepeatedWords(
      cleaned.replaceAll(RegExp(r'\s+'), ' ').trim(),
    );
  }

  static String _sanitizeParagraph(String text) {
    final cleaned = _stripMarkdown(text);
    return _removeRepeatedWords(
      cleaned.replaceAll(RegExp(r'\s+'), ' ').trim(),
    );
  }

  static String _limitSummary(String text) {
    if (text.isEmpty) return '';
    final limited = _limitSentences(text, 2);
    return _limitWords(limited, 60);
  }

  static String _limitSentences(String text, int maxSentences) {
    final sentences = TextProcessor.splitIntoSentences(text);
    if (sentences.isEmpty) return text;
    return sentences.take(maxSentences).join(' ');
  }

  static String _limitWords(String text, int maxWords) {
    if (text.isEmpty) return '';
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= maxWords) return text;
    return words.take(maxWords).join(' ');
  }

  static List<String> _normalizeKeyPoints(
    List<String> keyPoints, {
    required String fallbackText,
    required int maxPoints,
  }) {
    final sanitized = keyPoints
        .map(_sanitizeLine)
        .where((point) => point.isNotEmpty)
        .toList();

    final candidates = sanitized.isNotEmpty
        ? sanitized
        : TextProcessor.splitIntoSentences(fallbackText)
            .map(_sanitizeLine)
            .where((line) => line.isNotEmpty)
            .toList();

    final deduped = <String>[];
    final seen = <String>{};
    for (final point in candidates) {
      final trimmed = _limitWords(point, 18);
      final normalized = trimmed.toLowerCase();
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      deduped.add(trimmed);
      seen.add(normalized);
      if (deduped.length >= maxPoints) break;
    }

    return deduped;
  }

  static String _deriveTitle(String text, String fallbackTitle) {
    final sentences = TextProcessor.splitIntoSentences(text);
    if (sentences.isEmpty) return fallbackTitle;

    final words = sentences.first
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(5)
        .toList();
    if (words.isEmpty) return fallbackTitle;
    return words.join(' ');
  }

  static _ParsedSummary? _parseStructuredText(String text) {
    final lines = text.split('\n');
    String? title;
    final summaryLines = <String>[];
    final keyPointLines = <String>[];
    String? section;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.toLowerCase().startsWith('title:')) {
        title = line.substring('title:'.length).trim();
        section = null;
        continue;
      }

      if (line.toLowerCase().startsWith('summary:')) {
        section = 'summary';
        final after = line.substring('summary:'.length).trim();
        if (after.isNotEmpty) summaryLines.add(after);
        continue;
      }

      if (line.toLowerCase().startsWith('key points:')) {
        section = 'keyPoints';
        final after = line.substring('key points:'.length).trim();
        if (after.isNotEmpty) keyPointLines.add(after);
        continue;
      }

      if (section == 'summary') {
        summaryLines.add(line);
      } else if (section == 'keyPoints') {
        keyPointLines.add(line);
      }
    }

    if (title == null || summaryLines.isEmpty || keyPointLines.isEmpty) {
      return null;
    }

    final sanitizedTitle = _sanitizeLine(title);
    final sanitizedSummary = _sanitizeParagraph(summaryLines.join(' '));
    final keyPoints = keyPointLines
        .map(_stripBulletPrefix)
        .map(_sanitizeLine)
        .where((line) => line.isNotEmpty)
        .toList();

    return _ParsedSummary(
      title: sanitizedTitle,
      summary: sanitizedSummary,
      keyPoints: keyPoints,
    );
  }

  static String _stripBulletPrefix(String line) {
    return line.replaceAll(RegExp(r'^[\-\*\u2022\d\.\)\s]+'), '').trim();
  }

  static String _removeRepeatedWords(String text) {
    if (text.isEmpty) return text;
    return text.replaceAllMapped(
      RegExp(r'\b(\w+)(\s+\1\b){2,}', caseSensitive: false),
      (match) => match.group(1) ?? '',
    );
  }
}

class _ParsedSummary {
  final String title;
  final String summary;
  final List<String> keyPoints;

  const _ParsedSummary({
    required this.title,
    required this.summary,
    required this.keyPoints,
  });
}
