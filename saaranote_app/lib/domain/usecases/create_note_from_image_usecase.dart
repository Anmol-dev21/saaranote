import 'dart:io';
import '../entities/note.dart';
import '../entities/summary.dart';
import '../entities/flashcard.dart';
import '../repositories/note_repository.dart';
import '../repositories/summary_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../../core/services/ocr_service.dart';
import '../../core/utils/text_processor.dart';
import '../../core/utils/summarizer.dart';
import '../../core/utils/key_point_extractor.dart';

/// Use case for creating a note from an image using OCR, with automatic
/// summarization and flashcard generation
class CreateNoteFromImageUseCase {
  final NoteRepository _noteRepository;
  final SummaryRepository _summaryRepository;
  final FlashcardRepository _flashcardRepository;
  final OcrService _ocrService;

  CreateNoteFromImageUseCase(
    this._noteRepository,
    this._summaryRepository,
    this._flashcardRepository,
    this._ocrService,
  );

  /// Execute the use case to create a note from an image
  /// 
  /// Takes a [CreateNoteFromImageParams] containing the image file and options,
  /// and returns a [CreateNoteFromImageResult] with the created note and
  /// associated data.
  /// 
  /// Process:
  /// 1. Extract text from image using OCR
  /// 2. Clean and validate the extracted text
  /// 3. Create and save the note
  /// 4. Generate and save summaries
  /// 5. Generate and save flashcards
  Future<CreateNoteFromImageResult> execute(CreateNoteFromImageParams params) async {
    // Extract text from image using OCR
    String extractedText;
    try {
      extractedText = await _ocrService.extractTextFromImage(params.imageFile);
    } catch (e) {
      throw CreateNoteFromImageException('Failed to extract text from image: ${e.toString()}');
    }

    // Clean and validate the extracted text
    final cleanedContent = TextProcessor.cleanText(extractedText);
    
    if (cleanedContent.isEmpty) {
      throw CreateNoteFromImageException('No text found in the image');
    }

    // Validate minimum content length
    final wordCount = TextProcessor.countWords(cleanedContent);
    if (wordCount < 3) {
      throw CreateNoteFromImageException('Insufficient text extracted from image');
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
    Summary? createdSummary;
    if (params.generateSummary) {
      try {
        final summaryText = Summarizer.generateDetailedSummary(cleanedContent);
        
        if (summaryText.isNotEmpty) {
          final summary = Summary(
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

    return CreateNoteFromImageResult(
      note: createdNote,
      summary: createdSummary,
      flashcards: createdFlashcards,
      extractedText: extractedText,
      wordCount: wordCount,
    );
  }

  /// Generate a title from the content if not provided
  String _generateTitle(String content) {
    final sentences = TextProcessor.splitIntoSentences(content);
    if (sentences.isEmpty) return 'Note from Image';

    // Use the first sentence or first few words as title
    final firstSentence = sentences.first;
    final words = firstSentence.split(RegExp(r'\s+'));
    
    if (words.length <= 8) {
      return firstSentence.replaceAll(RegExp(r'[.!?]$'), '');
    }
    
    return '${words.take(8).join(' ')}...';
  }
}

/// Parameters for creating a note from an image
class CreateNoteFromImageParams {
  final File imageFile;
  final String title;
  final String? color;
  final bool generateSummary;
  final bool generateFlashcards;

  CreateNoteFromImageParams({
    required this.imageFile,
    this.title = '',
    this.color,
    this.generateSummary = true,
    this.generateFlashcards = true,
  });
}

/// Result of creating a note from an image
class CreateNoteFromImageResult {
  final Note note;
  final Summary? summary;
  final List<Flashcard> flashcards;
  final String extractedText;
  final int wordCount;

  CreateNoteFromImageResult({
    required this.note,
    this.summary,
    required this.flashcards,
    required this.extractedText,
    required this.wordCount,
  });

  bool get hasSummary => summary != null;
  bool get hasFlashcards => flashcards.isNotEmpty;
  int get flashcardCount => flashcards.length;
}

/// Exception thrown when note creation from image fails
class CreateNoteFromImageException implements Exception {
  final String message;

  CreateNoteFromImageException(this.message);

  @override
  String toString() => 'CreateNoteFromImageException: $message';
}
