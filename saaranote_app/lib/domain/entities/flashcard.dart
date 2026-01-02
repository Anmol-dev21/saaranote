class Flashcard {
  final int? id;
  final int noteId;
  final String question;
  final String answer;
  final DateTime createdAt;
  final DateTime? lastReviewedAt;
  final int confidenceLevel;

  const Flashcard({
    this.id,
    required this.noteId,
    required this.question,
    required this.answer,
    required this.createdAt,
    this.lastReviewedAt,
    this.confidenceLevel = 0,
  });

  Flashcard copyWith({
    int? id,
    int? noteId,
    String? question,
    String? answer,
    DateTime? createdAt,
    DateTime? lastReviewedAt,
    int? confidenceLevel,
  }) {
    return Flashcard(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      createdAt: createdAt ?? this.createdAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
    );
  }
}
