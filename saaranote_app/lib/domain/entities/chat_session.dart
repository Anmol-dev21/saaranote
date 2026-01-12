/// Entity representing a chat conversation session
class ChatSession {
  final int? id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? tags;

  const ChatSession({
    this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
  });

  ChatSession copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }
}
