import 'dart:io';
import '../entities/note.dart';
import '../entities/note_summary.dart';
import '../entities/flashcard.dart';
import '../repositories/note_repository.dart';
import '../repositories/summary_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../../core/services/pdf_text_service.dart';
import '../../core/utils/text_processor.dart';
import '../../core/utils/summarizer.dart';
import '../../core/utils/key_point_extractor.dart';
import '../../core/utils/summary_formatter.dart';
import '../../core/ai_engine.dart';

/// Use case for creating a note from a PDF file with automatic
/// summarization and flashcard generation
class CreateNoteFromPdfUseCase {
  final NoteRepository _noteRepository;
  final SummaryRepository _summaryRepository;
  final FlashcardRepository _flashcardRepository;
  final PdfTextService _pdfTextService;
  final AIEngine? _aiEngine;

  CreateNoteFromPdfUseCase(
    this._noteRepository,
    this._summaryRepository,
    this._flashcardRepository,
    this._pdfTextService,
    this._aiEngine,
  );

  /// Execute the use case to create a note from a PDF file
  /// 
  /// Takes a [CreateNoteFromPdfParams] containing the PDF file and options,
  /// and returns a [CreateNoteFromPdfResult] with the created note and
  /// associated data.
  /// 
  /// Process:
  /// 1. Extract text from PDF
  /// 2. Clean and validate the extracted text
  /// 3. Create and save the note
  /// 4. Generate and save summaries
  /// 5. Generate and save flashcards
  Future<CreateNoteFromPdfResult> execute(CreateNoteFromPdfParams params) async {
    // Extract text from PDF
    String extractedText;
    try {
      extractedText = await _pdfTextService.extractTextFromPdf(params.pdfFile);
    } catch (e) {
      throw CreateNoteFromPdfException('Failed to extract text from PDF: ${e.toString()}');
    }

    // Clean and validate the extracted text
    final cleanedContent = TextProcessor.cleanText(extractedText);
    
    if (cleanedContent.isEmpty) {
      throw CreateNoteFromPdfException(
        'No text found in the PDF. If this is a scanned PDF, try image import/OCR.',
      );
    }

    // Validate minimum content length
    final wordCount = TextProcessor.countWords(cleanedContent);
    if (wordCount < 5) {
      throw CreateNoteFromPdfException('Insufficient text extracted from PDF');
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
        final summaryText = await _generateSummaryText(cleanedContent);
        
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
            question: pair['question']!,
            answer: pair['answer']!,
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

    return CreateNoteFromPdfResult(
      note: createdNote,
      summary: createdSummary,
      flashcards: createdFlashcards,
      extractedText: extractedText,
      wordCount: wordCount,
    );
  }

  Future<String> _generateSummaryText(String content) async {
    if (_aiEngine == null) {
      return Summarizer.generateDetailedSummary(content);
    }

    final result = await _aiEngine.generateSummary(text: content);
    final structuredText = SummaryFormatter.formatStructuredSummary(
      result.structured,
      includeSections: true,
      includeDetailed: result.structured.detailedSummary.isNotEmpty,
    );
    if (structuredText.isNotEmpty) return structuredText;

    return result.detailedSummary.isNotEmpty
        ? result.detailedSummary
        : Summarizer.generateDetailedSummary(content);
  }

  /// Generate a title from the content
  String _generateTitle(String content) {
    final words = content.split(' ').where((w) => w.isNotEmpty).take(5).toList();
    String title = words.join(' ');
    
    if (title.length > 50) {
      title = '${title.substring(0, 47)}...';
    }
    
    return title.isEmpty ? 'Untitled PDF Note' : title;
  }
}

/// Parameters for creating a note from a PDF
class CreateNoteFromPdfParams {
  final File pdfFile;
  final String title;
  final bool generateSummary;
  final bool generateFlashcards;
  final String? color;

  CreateNoteFromPdfParams({
    required this.pdfFile,
    this.title = '',
    this.generateSummary = true,
    this.generateFlashcards = true,
    this.color,
  });
}

/// Result of creating a note from a PDF
class CreateNoteFromPdfResult {
  final Note note;
  final NoteSummary? summary;
  final List<Flashcard> flashcards;
  final String extractedText;
  final int wordCount;

  CreateNoteFromPdfResult({
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

/// Exception thrown when note creation from PDF fails
class CreateNoteFromPdfException implements Exception {
  final String message;

  CreateNoteFromPdfException(this.message);

  @override
  String toString() => 'CreateNoteFromPdfException: $message';
}
