/// Rich text content with formatting
/// Supports bold, italic, font size, highlights, and other text styling
class RichTextContent {
  final String plainText;
  final List<TextSpan> spans;

  const RichTextContent({
    required this.plainText,
    required this.spans,
  });

  /// Create plain text content (no formatting)
  factory RichTextContent.plain(String text) {
    return RichTextContent(
      plainText: text,
      spans: [
        TextSpan(
          start: 0,
          end: text.length,
          style: TextStyle(),
        ),
      ],
    );
  }

  /// Check if content has any formatting
  bool get hasFormatting => spans.any((span) => span.style.hasFormatting);

  /// Get plain text without formatting
  String get text => plainText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RichTextContent &&
          runtimeType == other.runtimeType &&
          plainText == other.plainText &&
          _spansEqual(spans, other.spans);

  @override
  int get hashCode => plainText.hashCode ^ spans.hashCode;

  bool _spansEqual(List<TextSpan> a, List<TextSpan> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Text span with position and styling
class TextSpan {
  final int start;
  final int end;
  final TextStyle style;

  const TextSpan({
    required this.start,
    required this.end,
    required this.style,
  });

  /// Length of this span
  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSpan &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          style == other.style;

  @override
  int get hashCode => start.hashCode ^ end.hashCode ^ style.hashCode;
}

/// Text styling information
class TextStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final double? fontSize;
  final String? highlightColor; // Hex color string
  final String? textColor; // Hex color string

  const TextStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.fontSize,
    this.highlightColor,
    this.textColor,
  });

  /// Check if style has any formatting
  bool get hasFormatting =>
      bold ||
      italic ||
      underline ||
      fontSize != null ||
      highlightColor != null ||
      textColor != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextStyle &&
          runtimeType == other.runtimeType &&
          bold == other.bold &&
          italic == other.italic &&
          underline == other.underline &&
          fontSize == other.fontSize &&
          highlightColor == other.highlightColor &&
          textColor == other.textColor;

  @override
  int get hashCode =>
      bold.hashCode ^
      italic.hashCode ^
      underline.hashCode ^
      fontSize.hashCode ^
      highlightColor.hashCode ^
      textColor.hashCode;
}
