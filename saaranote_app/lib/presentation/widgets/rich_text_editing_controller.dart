import 'package:flutter/material.dart';
import '../../domain/entities/rich_text_content.dart' as domain;

class RichTextEditingController extends TextEditingController {
  List<domain.TextSpan> _spans = const [];

  RichTextEditingController({super.text});

  void updateSpans(List<domain.TextSpan> spans) {
    if (identical(spans, _spans)) {
      return;
    }
    _spans = spans;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    BuildContext? context,
    TextStyle? style,
    bool withComposing = false,
  }) {
    final baseStyle = style ?? const TextStyle();
    final plainText = text;

    if (plainText.isEmpty || _spans.isEmpty) {
      return TextSpan(text: plainText, style: baseStyle);
    }

    final spans = <TextSpan>[];
    int current = 0;
    final length = plainText.length;

    for (final span in _spans) {
      final start = span.start.clamp(0, length);
      final end = span.end.clamp(0, length);
      if (end <= start) continue;

      if (start > current) {
        spans.add(TextSpan(
          text: plainText.substring(current, start),
          style: baseStyle,
        ));
      }

      spans.add(TextSpan(
        text: plainText.substring(start, end),
        style: _buildTextStyle(span.style, baseStyle),
      ));
      current = end;
    }

    if (current < length) {
      spans.add(TextSpan(
        text: plainText.substring(current),
        style: baseStyle,
      ));
    }

    return TextSpan(style: baseStyle, children: spans);
  }

  TextStyle _buildTextStyle(domain.TextStyle style, TextStyle baseStyle) {
    final textColor =
        style.textColor != null ? _parseHexColor(style.textColor!) : baseStyle.color;

    return baseStyle.copyWith(
      fontWeight: style.bold ? FontWeight.w700 : baseStyle.fontWeight,
      fontStyle: style.italic ? FontStyle.italic : baseStyle.fontStyle,
      decoration: style.underline ? TextDecoration.underline : TextDecoration.none,
      decorationColor: style.underline ? textColor : baseStyle.decorationColor,
      decorationThickness: style.underline ? 1.6 : baseStyle.decorationThickness,
      fontSize: style.fontSize ?? baseStyle.fontSize,
      color: textColor,
      backgroundColor: style.highlightColor != null
          ? _parseHexColor(style.highlightColor!)
          : baseStyle.backgroundColor,
    );
  }

  Color _parseHexColor(String value) {
    final hex = value.replaceFirst('#', '');
    final colorValue = int.parse(hex, radix: 16);
    return Color(0xFF000000 | colorValue);
  }
}
