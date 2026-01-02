import '../../domain/entities/flashcard.dart';

class FlashcardModel extends Flashcard {
  const FlashcardModel({
    super.id,
    required super.noteId,
    required super.question,
    required super.answer,
    required super.createdAt,
    super.lastReviewedAt,
    super.confidenceLevel = 0,
  });

  /// Create FlashcardModel from domain entity
  factory FlashcardModel.fromEntity(Flashcard flashcard) {
    return FlashcardModel(
      id: flashcard.id,
      noteId: flashcard.noteId,
      question: flashcard.question,
      answer: flashcard.answer,
      createdAt: flashcard.createdAt,
      lastReviewedAt: flashcard.lastReviewedAt,
      confidenceLevel: flashcard.confidenceLevel,
    );
  }

  /// Create FlashcardModel from SQLite map
  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as int?,
      noteId: map['noteId'] as int,
      question: map['question'] as String,
      answer: map['answer'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastReviewedAt: map['lastReviewedAt'] != null
          ? DateTime.parse(map['lastReviewedAt'] as String)
          : null,
      confidenceLevel: map['confidenceLevel'] as int,
    );
  }

  /// Convert FlashcardModel to SQLite map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'noteId': noteId,
      'question': question,
      'answer': answer,
      'createdAt': createdAt.toIso8601String(),
      if (lastReviewedAt != null)
        'lastReviewedAt': lastReviewedAt!.toIso8601String(),
      'confidenceLevel': confidenceLevel,
    };
  }

  /// Convert FlashcardModel to domain entity
  Flashcard toEntity() {
    return Flashcard(
      id: id,
      noteId: noteId,
      question: question,
      answer: answer,
      createdAt: createdAt,
      lastReviewedAt: lastReviewedAt,
      confidenceLevel: confidenceLevel,
    );
  }

  @override
  FlashcardModel copyWith({
    int? id,
    int? noteId,
    String? question,
    String? answer,
    DateTime? createdAt,
    DateTime? lastReviewedAt,
    int? confidenceLevel,
  }) {
    return FlashcardModel(
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
