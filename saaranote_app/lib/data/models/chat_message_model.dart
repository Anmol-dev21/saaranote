import '../../domain/entities/chat_message.dart';

/// Data model for ChatMessage with database serialization
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    super.id,
    required super.content,
    required super.role,
    required super.timestamp,
    super.sources,
    super.status = MessageStatus.sent,
  });

  /// Create from entity
  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      content: entity.content,
      role: entity.role,
      timestamp: entity.timestamp,
      sources: entity.sources,
      status: entity.status,
    );
  }

  /// Create from database map
  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as int?,
      content: map['content'] as String,
      role: MessageRole.values.byName(map['role'] as String),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: MessageStatus.values.byName(map['status'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  /// Convert to entity
  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      content: content,
      role: role,
      timestamp: timestamp,
      sources: sources,
      status: status,
    );
  }
}
