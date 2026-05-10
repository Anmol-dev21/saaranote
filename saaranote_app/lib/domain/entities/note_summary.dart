class NoteSummary {
  final int? id;
  final int noteId;
  final String summaryText;
  // Optional generation state as a string (e.g., 'aiEnhanced', 'invalidFormat')
  // This field is not yet persisted to the DB schema; it's used at runtime
  // to communicate the reason/state for the summary generation.
  final String? generationState;
  final DateTime createdAt;

  const NoteSummary({
    this.id,
    required this.noteId,
    required this.summaryText,
    this.generationState,
    required this.createdAt,
  });

  NoteSummary copyWith({
    int? id,
    int? noteId,
    String? summaryText,
    DateTime? createdAt,
    String? generationState,
  }) {
    return NoteSummary(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      summaryText: summaryText ?? this.summaryText,
      createdAt: createdAt ?? this.createdAt,
      generationState: generationState ?? this.generationState,
    );
  }
}
