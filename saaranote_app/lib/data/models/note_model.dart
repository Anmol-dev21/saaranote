import 'dart:convert';
import '../../domain/entities/note.dart';
import '../../core/services/rich_text_service.dart';

class NoteModel extends Note {
  const NoteModel({
    super.id,
    required super.title,
    required super.content,
    required super.createdAt,
    required super.updatedAt,
    super.isArchived = false,
    super.color,
    super.richContent,
    super.drawingIds,
    super.contentType = ContentType.plain,
  });

  /// Create NoteModel from domain entity
  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isArchived: note.isArchived,
      color: note.color,
      richContent: note.richContent,
      drawingIds: note.drawingIds,
      contentType: note.contentType,
    );
  }

  /// Create NoteModel from SQLite map
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    // Parse rich content if present
    final richTextService = RichTextService();
    final richContentJson = map['rich_content'] as String?;
    final richContent = richContentJson != null 
        ? richTextService.deserialize(richContentJson)
        : null;

    // Parse drawing IDs if present
    final drawingIdsJson = map['drawing_ids'] as String?;
    final drawingIds = drawingIdsJson != null
        ? (jsonDecode(drawingIdsJson) as List).cast<String>()
        : null;

    // Parse content type
    final contentTypeStr = map['content_type'] as String?;
    final contentType = contentTypeStr != null
        ? ContentType.values.firstWhere(
            (e) => e.name == contentTypeStr,
            orElse: () => ContentType.plain,
          )
        : ContentType.plain;

    return NoteModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isArchived: (map['is_archived'] as int) == 1,
      color: map['color'] as String?,
      richContent: richContent,
      drawingIds: drawingIds,
      contentType: contentType,
    );
  }

  /// Convert NoteModel to SQLite map
  Map<String, dynamic> toMap() {
    final richTextService = RichTextService();
    
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_archived': isArchived ? 1 : 0,
      if (color != null) 'color': color,
      if (richContent != null) 'rich_content': richTextService.serialize(richContent!),
      if (drawingIds != null) 'drawing_ids': jsonEncode(drawingIds),
      'content_type': contentType.name,
    };
  }

  /// Convert NoteModel to domain entity
  Note toEntity() {
    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isArchived: isArchived,
      color: color,
      richContent: richContent,
      drawingIds: drawingIds,
      contentType: contentType,
    );
  }

  @override
  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    String? color,
    bool clearRichContent = false,
    dynamic richContent,
    bool clearDrawingIds = false,
    List<String>? drawingIds,
    ContentType? contentType,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      color: color ?? this.color,
      richContent: clearRichContent ? null : (richContent ?? this.richContent),
      drawingIds: clearDrawingIds ? null : (drawingIds ?? this.drawingIds),
      contentType: contentType ?? this.contentType,
    );
  }
}
