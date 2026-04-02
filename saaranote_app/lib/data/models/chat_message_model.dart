import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    super.id,
    required super.content,
    required super.role,
    required super.timestamp,
    required super.status,
    super.sources,
  });

  factory ChatMessageModel.fromEntity(ChatMessage message) {
    return ChatMessageModel(
      id: message.id,
      content: message.content,
      role: message.role,
      timestamp: message.timestamp,
      status: message.status,
      sources: message.sources,
    );
  }

  ChatMessage toEntity() => this;

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as int?,
      content: map['content'] as String,
      role: _roleFromString(map['role'] as String),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: _statusFromString(map['status'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'role': role.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  static MessageRole _roleFromString(String value) {
    return MessageRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageRole.user,
    );
  }

  static MessageStatus _statusFromString(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageStatus.sent,
    );
  }
}
