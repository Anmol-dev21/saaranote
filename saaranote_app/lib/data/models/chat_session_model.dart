import 'dart:convert';
import '../../domain/entities/chat_session.dart';

/// Data model for ChatSession with database serialization
class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    super.tags,
  });

  /// Create from entity
  factory ChatSessionModel.fromEntity(ChatSession entity) {
    return ChatSessionModel(
      id: entity.id,
      title: entity.title,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      tags: entity.tags,
    );
  }

  /// Create from database map
  factory ChatSessionModel.fromMap(Map<String, dynamic> map) {
    return ChatSessionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      tags: map['tags'] != null 
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      if (tags != null) 'tags': jsonEncode(tags),
    };
  }

  /// Convert to entity
  ChatSession toEntity() {
    return ChatSession(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tags: tags,
    );
  }
}
