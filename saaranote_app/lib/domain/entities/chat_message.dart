/// Entity representing a chat message in a conversation
class ChatMessage {
  final int? id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final List<CitedSource>? sources;
  final MessageStatus status;

  const ChatMessage({
    this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.sources,
    this.status = MessageStatus.sent,
  });

  ChatMessage copyWith({
    int? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    List<CitedSource>? sources,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      sources: sources ?? this.sources,
      status: status ?? this.status,
    );
  }
}

/// Role of the message sender
enum MessageRole {
  user,
  assistant,
}

/// Status of the message
enum MessageStatus {
  sending,
  sent,
  error,
}

/// Source citation for a message response
class CitedSource {
  final int fileMetadataId;
  final String fileName;
  final int chunkId;
  final String excerpt;
  final double relevanceScore;

  const CitedSource({
    required this.fileMetadataId,
    required this.fileName,
    required this.chunkId,
    required this.excerpt,
    required this.relevanceScore,
  });
}
