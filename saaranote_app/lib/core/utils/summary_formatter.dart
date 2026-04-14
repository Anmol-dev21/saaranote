import '../ai_engine.dart';
import 'simplification_service.dart';

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
    final simplifiedTitle = simplify ? SimplificationService.simplify(title) : title;

    buffer.writeln('Title: $simplifiedTitle');

    if (summary.shortSummary.isNotEmpty) {
      buffer.writeln('\nShort Summary:');
      buffer.writeln(_maybeSimplify(summary.shortSummary, simplify));
    }

    if (summary.keyPoints.isNotEmpty) {
      buffer.writeln('\nKey Points:');
      for (final point in summary.keyPoints) {
        final simplifiedPoint = _maybeSimplify(point, simplify);
        buffer.writeln('- $simplifiedPoint');
      }
    }

    if (includeSections && summary.sections.isNotEmpty) {
      buffer.writeln('\nSections:');
      for (final section in summary.sections) {
        if (section.bullets.isEmpty) continue;
        final simplifiedHeading = _maybeSimplify(section.heading, simplify);
        buffer.writeln(simplifiedHeading);
        for (final bullet in section.bullets) {
          final simplifiedBullet = _maybeSimplify(bullet, simplify);
          buffer.writeln('- $simplifiedBullet');
        }
        buffer.writeln('');
      }
    }

    if (includeDetailed && summary.detailedSummary.isNotEmpty) {
      buffer.writeln('Detailed:');
      buffer.writeln(_maybeSimplify(summary.detailedSummary, simplify));
    }

    return buffer.toString().trim();
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
}
