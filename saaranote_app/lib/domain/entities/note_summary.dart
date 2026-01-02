class NoteSummary {
  final int? id;
  final int noteId;
  final String summaryText;
  final DateTime createdAt;

  const NoteSummary({
    this.id,
    required this.noteId,
    required this.summaryText,
    required this.createdAt,
  });

  NoteSummary copyWith({
    int? id,
    int? noteId,
    String? summaryText,
    DateTime? createdAt,
  }) {
    return NoteSummary(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      summaryText: summaryText ?? this.summaryText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
