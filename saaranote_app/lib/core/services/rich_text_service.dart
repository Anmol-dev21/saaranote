import 'dart:convert';
import '../../domain/entities/rich_text_content.dart';

/// Service for handling rich text operations
/// Provides serialization, parsing, and utilities for formatted text
class RichTextService {
  /// Serialize rich text content to JSON string
  String serialize(RichTextContent content) {
    final data = {
      'plainText': content.plainText,
      'spans': content.spans.map((span) => _serializeSpan(span)).toList(),
    };

    return jsonEncode(data);
  }

  /// Deserialize rich text content from JSON string
  RichTextContent? deserialize(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final spans = (data['spans'] as List)
          .map((spanData) => _deserializeSpan(spanData))
          .whereType<TextSpan>()
          .toList();

      return RichTextContent(
        plainText: data['plainText'] as String,
        spans: spans,
      );
    } catch (e) {
      return null; // Invalid JSON
    }
  }

  /// Convert rich text to plain text (strip formatting)
  String toPlainText(RichTextContent content) {
    return content.plainText;
  }

  /// Create rich text from plain text
  RichTextContent fromPlainText(String text) {
    return RichTextContent.plain(text);
  }

  /// Apply formatting to a range in the text
  RichTextContent applyFormatting(
    RichTextContent content,
    int start,
    int end,
    TextStyle style,
  ) {
    if (start < 0 || end > content.plainText.length || start >= end) {
      return content; // Invalid range
    }

    // Split and merge spans as needed
    final newSpans = <TextSpan>[];
    bool applied = false;
    
    for (final span in content.spans) {
      if (span.end <= start || span.start >= end) {
        // No overlap
        newSpans.add(span);
      } else if (span.start >= start && span.end <= end) {
        // Fully contained - apply new style
        newSpans.add(TextSpan(
          start: span.start,
          end: span.end,
          style: _mergeStyles(span.style, style),
        ));
        applied = true;
      } else if (span.start < start && span.end > end) {
        // Selection is inside span - split into 3
        newSpans.add(TextSpan(start: span.start, end: start, style: span.style));
        newSpans.add(TextSpan(start: start, end: end, style: _mergeStyles(span.style, style)));
        newSpans.add(TextSpan(start: end, end: span.end, style: span.style));
        applied = true;
      } else if (span.start < start) {
        // Overlap at start
        newSpans.add(TextSpan(start: span.start, end: start, style: span.style));
        newSpans.add(TextSpan(start: start, end: span.end, style: _mergeStyles(span.style, style)));
        applied = true;
      } else {
        // Overlap at end
        newSpans.add(TextSpan(start: span.start, end: end, style: _mergeStyles(span.style, style)));
        newSpans.add(TextSpan(start: end, end: span.end, style: span.style));
        applied = true;
      }
    }

    if (!applied) {
      newSpans.add(TextSpan(start: start, end: end, style: style));
    }

    return RichTextContent(
      plainText: content.plainText,
      spans: _mergeAdjacentSpans(newSpans),
    );
  }

  /// Merge adjacent spans with identical styles
  List<TextSpan> _mergeAdjacentSpans(List<TextSpan> spans) {
    if (spans.length <= 1) return spans;

    final merged = <TextSpan>[];
    TextSpan current = spans.first;

    for (int i = 1; i < spans.length; i++) {
      final next = spans[i];
      
      if (current.end == next.start && current.style == next.style) {
        // Merge
        current = TextSpan(
          start: current.start,
          end: next.end,
          style: current.style,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }
    
    merged.add(current);
    return merged;
  }

  /// Merge two text styles (new style takes precedence)
  TextStyle _mergeStyles(TextStyle base, TextStyle overlay) {
    return TextStyle(
      bold: overlay.bold || base.bold,
      italic: overlay.italic || base.italic,
      underline: overlay.underline || base.underline,
      fontSize: overlay.fontSize ?? base.fontSize,
      highlightColor: overlay.highlightColor ?? base.highlightColor,
      textColor: overlay.textColor ?? base.textColor,
    );
  }

  // Serialize span to map
  Map<String, dynamic> _serializeSpan(TextSpan span) {
    return {
      'start': span.start,
      'end': span.end,
      'style': _serializeStyle(span.style),
    };
  }

  // Deserialize span from map
  TextSpan? _deserializeSpan(dynamic data) {
    try {
      final spanData = data as Map<String, dynamic>;
      final style = _deserializeStyle(spanData['style']);
      
      if (style == null) return null;

      return TextSpan(
        start: spanData['start'] as int,
        end: spanData['end'] as int,
        style: style,
      );
    } catch (e) {
      return null;
    }
  }

  // Serialize style to map
  Map<String, dynamic> _serializeStyle(TextStyle style) {
    return {
      'bold': style.bold,
      'italic': style.italic,
      'underline': style.underline,
      if (style.fontSize != null) 'fontSize': style.fontSize,
      if (style.highlightColor != null) 'highlightColor': style.highlightColor,
      if (style.textColor != null) 'textColor': style.textColor,
    };
  }

  // Deserialize style from map
  TextStyle? _deserializeStyle(dynamic data) {
    try {
      final styleData = data as Map<String, dynamic>;
      return TextStyle(
        bold: styleData['bold'] as bool? ?? false,
        italic: styleData['italic'] as bool? ?? false,
        underline: styleData['underline'] as bool? ?? false,
        fontSize: styleData['fontSize'] != null 
            ? (styleData['fontSize'] as num).toDouble() 
            : null,
        highlightColor: styleData['highlightColor'] as String?,
        textColor: styleData['textColor'] as String?,
      );
    } catch (e) {
      return null;
    }
  }
}
