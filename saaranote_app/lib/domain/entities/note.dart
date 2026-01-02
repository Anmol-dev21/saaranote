class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final String? color;

  const Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.color,
  });

  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    String? color,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      color: color ?? this.color,
    );
  }
}
