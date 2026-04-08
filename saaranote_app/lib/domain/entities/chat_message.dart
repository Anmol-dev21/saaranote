/// Chat message entity with optional source citations
class ChatMessage {
  final int? id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final MessageStatus status;
  final List<CitedSource>? sources;

  const ChatMessage({
    this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    required this.status,
    this.sources,
  });

  ChatMessage copyWith({
    int? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    MessageStatus? status,
    List<CitedSource>? sources,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      sources: sources ?? this.sources,
    );
  }
}

enum MessageRole {
  user,
  assistant,
}

enum MessageStatus {
  sending,
  sent,
  error,
}

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
