import 'rich_text_content.dart';

class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final String? color;
  
  // Advanced content support (optional, nullable for backward compatibility)
  final RichTextContent? richContent;
  final List<String>? drawingIds; // References to drawing data stored separately
  final ContentType contentType;

  const Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.color,
    this.richContent,
    this.drawingIds,
    this.contentType = ContentType.plain,
  });

  /// Check if note has rich text formatting
  bool get hasRichContent => richContent != null && richContent!.hasFormatting;

  /// Check if note has drawings
  bool get hasDrawings => drawingIds != null && drawingIds!.isNotEmpty;

  /// Check if note is hybrid (text + drawings)
  bool get isHybrid => hasDrawings && (content.isNotEmpty || hasRichContent);

  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    String? color,
    RichTextContent? richContent,
    List<String>? drawingIds,
    ContentType? contentType,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      color: color ?? this.color,
      richContent: richContent ?? this.richContent,
      drawingIds: drawingIds ?? this.drawingIds,
      contentType: contentType ?? this.contentType,
    );
  }
}

/// Type of note content
enum ContentType {
  plain,      // Plain text only (backward compatible)
  rich,       // Rich formatted text
  drawing,    // Drawing only
  hybrid,     // Text + drawing
}
