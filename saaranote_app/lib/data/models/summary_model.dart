import '../../domain/entities/note_summary.dart';

class SummaryModel extends NoteSummary {
  const SummaryModel({
    super.id,
    required super.noteId,
    required super.summaryText,
    required super.createdAt,
    super.generationState,
  });

  /// Create SummaryModel from domain entity
  factory SummaryModel.fromEntity(NoteSummary summary) {
    return SummaryModel(
      id: summary.id,
      noteId: summary.noteId,
      summaryText: summary.summaryText,
      createdAt: summary.createdAt,
      generationState: summary.generationState,
    );
  }

  /// Create SummaryModel from SQLite map
  factory SummaryModel.fromMap(Map<String, dynamic> map) {
    return SummaryModel(
      id: map['id'] as int?,
      noteId: map['note_id'] as int,
      summaryText: map['summary_text'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Convert SummaryModel to SQLite map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'note_id': noteId,
      'summary_text': summaryText,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Convert SummaryModel to domain entity
  NoteSummary toEntity() {
    return NoteSummary(
      id: id,
      noteId: noteId,
      summaryText: summaryText,
      createdAt: createdAt,
      generationState: generationState,
    );
  }

  @override
  SummaryModel copyWith({
    int? id,
    int? noteId,
    String? summaryText,
    DateTime? createdAt,
    String? generationState,
  }) {
    return SummaryModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      summaryText: summaryText ?? this.summaryText,
      createdAt: createdAt ?? this.createdAt,
      generationState: generationState ?? this.generationState,
    );
  }
}
