import '../entities/note.dart';
import '../entities/note_summary.dart';
import '../entities/flashcard.dart';
import '../repositories/note_repository.dart';
import '../repositories/summary_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../../core/utils/text_processor.dart';
import '../../core/utils/summarizer.dart';
import '../../core/utils/key_point_extractor.dart';

/// Use case for creating a note from text input with automatic summarization
/// and flashcard generation
class CreateNoteFromTextUseCase {
  final NoteRepository _noteRepository;
  final SummaryRepository _summaryRepository;
  final FlashcardRepository _flashcardRepository;

  CreateNoteFromTextUseCase(
    this._noteRepository,
    this._summaryRepository,
    this._flashcardRepository,
  );

  /// Execute the use case to create a note with summaries and flashcards
  /// 
  /// Takes a [CreateNoteFromTextParams] containing the note title and content,
  /// and returns a [CreateNoteResult] with the created note and associated data.
  /// 
  /// Process:
  /// 1. Clean and validate the input text
  /// 2. Create and save the note
  /// 3. Generate and save summaries
  /// 4. Generate and save flashcards
  Future<CreateNoteResult> execute(CreateNoteFromTextParams params) async {
    // Clean the input text
    final cleanedContent = TextProcessor.cleanText(params.content);
    
    if (cleanedContent.isEmpty) {
      throw CreateNoteException('Content cannot be empty');
    }

    // Create the note
    final now = DateTime.now();
    final note = Note(
      title: params.title.trim().isEmpty ? _generateTitle(cleanedContent) : params.title.trim(),
      content: cleanedContent,
      createdAt: now,
      updatedAt: now,
      color: params.color,
    );

    final createdNote = await _noteRepository.create(note);
    final noteId = createdNote.id!;

    // Generate and save summary if enabled
    NoteSummary? createdSummary;
    if (params.generateSummary) {
      try {
        final summaryText = Summarizer.generateDetailedSummary(cleanedContent);
        
        if (summaryText.isNotEmpty) {
          final summary = NoteSummary(
            noteId: noteId,
            summaryText: summaryText,
            createdAt: now,
          );
          createdSummary = await _summaryRepository.create(summary);
        }
      } catch (e) {
        // Continue even if summary generation fails
        // Log error in production
      }
    }

    // Generate and save flashcards if enabled
    final createdFlashcards = <Flashcard>[];
    if (params.generateFlashcards) {
      try {
        final flashcardPairs = KeyPointExtractor.extractFlashcardPairs(cleanedContent);
        
        for (final pair in flashcardPairs) {
          final flashcard = Flashcard(
            noteId: noteId,
            question: pair['question'] ?? '',
            answer: pair['answer'] ?? '',
            createdAt: now,
          );
          
          final created = await _flashcardRepository.create(flashcard);
          createdFlashcards.add(created);
        }
      } catch (e) {
        // Continue even if flashcard generation fails
        // Log error in production
      }
    }

    return CreateNoteResult(
      note: createdNote,
      summary: createdSummary,
      flashcards: createdFlashcards,
    );
  }

  /// Generate a title from the content if not provided
  String _generateTitle(String content) {
    final sentences = TextProcessor.splitIntoSentences(content);
    if (sentences.isEmpty) return 'Untitled Note';

    // Use the first sentence or first few words as title
    final firstSentence = sentences.first;
    final words = firstSentence.split(RegExp(r'\s+'));
    
    if (words.length <= 8) {
      return firstSentence.replaceAll(RegExp(r'[.!?]$'), '');
    }
    
    return '${words.take(8).join(' ')}...';
  }
}

/// Parameters for creating a note from text
class CreateNoteFromTextParams {
  final String title;
  final String content;
  final String? color;
  final bool generateSummary;
  final bool generateFlashcards;

  CreateNoteFromTextParams({
    required this.title,
    required this.content,
    this.color,
    this.generateSummary = true,
    this.generateFlashcards = true,
  });
}

/// Result of creating a note with summaries and flashcards
class CreateNoteResult {
  final Note note;
  final NoteSummary? summary;
  final List<Flashcard> flashcards;

  CreateNoteResult({
    required this.note,
    this.summary,
    required this.flashcards,
  });

  bool get hasSummary => summary != null;
  bool get hasFlashcards => flashcards.isNotEmpty;
  int get flashcardCount => flashcards.length;
}

/// Exception thrown when note creation fails
class CreateNoteException implements Exception {
  final String message;

  CreateNoteException(this.message);

  @override
  String toString() => 'CreateNoteException: $message';
}
