class Summary {
  final int? id;
  final int noteId;
  final String summaryText;
  final DateTime createdAt;

  const Summary({
    this.id,
    required this.noteId,
    required this.summaryText,
    required this.createdAt,
  });

  Summary copyWith({
    int? id,
    int? noteId,
    String? summaryText,
    DateTime? createdAt,
  }) {
    return Summary(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      summaryText: summaryText ?? this.summaryText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
