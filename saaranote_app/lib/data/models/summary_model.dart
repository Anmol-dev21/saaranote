import '../../domain/entities/summary.dart';

class SummaryModel extends Summary {
  const SummaryModel({
    super.id,
    required super.noteId,
    required super.summaryText,
    required super.createdAt,
  });

  /// Create SummaryModel from domain entity
  factory SummaryModel.fromEntity(Summary summary) {
    return SummaryModel(
      id: summary.id,
      noteId: summary.noteId,
      summaryText: summary.summaryText,
      createdAt: summary.createdAt,
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
  Summary toEntity() {
    return Summary(
      id: id,
      noteId: noteId,
      summaryText: summaryText,
      createdAt: createdAt,
    );
  }

  @override
  SummaryModel copyWith({
    int? id,
    int? noteId,
    String? summaryText,
    DateTime? createdAt,
  }) {
    return SummaryModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      summaryText: summaryText ?? this.summaryText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
