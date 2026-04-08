import '../../domain/entities/chat_session.dart';

class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    super.tags,
  });

  factory ChatSessionModel.fromEntity(ChatSession session) {
    return ChatSessionModel(
      id: session.id,
      title: session.title,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      tags: session.tags,
    );
  }

  ChatSession toEntity() => this;

  factory ChatSessionModel.fromMap(Map<String, dynamic> map) {
    return ChatSessionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      tags: map['tags'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'tags': tags,
    };
  }
}
