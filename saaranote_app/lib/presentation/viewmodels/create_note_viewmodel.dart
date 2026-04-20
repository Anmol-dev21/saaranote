import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_summary.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/usecases/create_note_from_text_usecase.dart';
import '../../domain/usecases/create_note_from_image_usecase.dart';
import '../../domain/usecases/create_note_from_pdf_usecase.dart';
import '../../domain/entities/rich_text_content.dart' as domain;
import '../../domain/entities/drawing.dart';
import '../../data/datasources/local/drawing_local_data_source.dart';

/// ViewModel for creating notes from text, images, or PDF files
/// 
/// Uses MVVM pattern with ChangeNotifier for state management
class CreateNoteViewModel extends ChangeNotifier {
  final CreateNoteFromTextUseCase _createNoteFromTextUseCase;
  final CreateNoteFromImageUseCase _createNoteFromImageUseCase;
  final CreateNoteFromPdfUseCase _createNoteFromPdfUseCase;
  final DrawingLocalDataSource _drawingLocalDataSource;

  CreateNoteViewModel(
    this._createNoteFromTextUseCase,
    this._createNoteFromImageUseCase,
    this._createNoteFromPdfUseCase,
    this._drawingLocalDataSource,
  );

  // State
  bool _isLoading = false;
  String? _errorMessage;
  Note? _createdNote;
  NoteSummary? _createdSummary;
  List<Flashcard> _createdFlashcards = [];
  String? _extractedText;
  int? _wordCount;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  Note? get createdNote => _createdNote;
  NoteSummary? get createdSummary => _createdSummary;
  List<Flashcard> get createdFlashcards => _createdFlashcards;
  String? get extractedText => _extractedText;
  int? get wordCount => _wordCount;
  bool get hasCreatedNote => _createdNote != null;
  bool get hasCreatedSummary => _createdSummary != null;
  bool get hasCreatedFlashcards => _createdFlashcards.isNotEmpty;

  /// Create a note from text input
  Future<bool> createNoteFromText({
    required String title,
    required String content,
    String? color,
    bool generateSummary = true,
    bool useAiEnhancement = true,
    bool generateFlashcards = true,
    domain.RichTextContent? richContent,
    List<String>? drawingIds,
    ContentType? contentType,
    List<Drawing>? drawings,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _createdNote = null;
    _createdSummary = null;
    _createdFlashcards = [];
    _extractedText = null;
    _wordCount = null;
    notifyListeners();

    try {
      final params = CreateNoteFromTextParams(
        title: title,
        content: content,
        color: color,
        generateSummary: generateSummary,
        useAiEnhancement: useAiEnhancement,
        generateFlashcards: generateFlashcards,
        richContent: richContent,
        drawingIds: drawingIds,
        contentType: contentType,
      );

      final result = await _createNoteFromTextUseCase.execute(params);

      if (drawings != null && drawings.isNotEmpty && result.note.id != null) {
        try {
          for (final drawing in drawings) {
            await _drawingLocalDataSource.saveDrawing(drawing, result.note.id!);
          }
        } catch (_) {
          // Do not block note creation if drawing persistence fails
        }
      }

      _createdNote = result.note;
      _createdSummary = result.summary;
      _createdFlashcards = result.flashcards;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create note: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Create a note from an image using OCR
  Future<bool> createNoteFromImage({
    required File imageFile,
    String title = '',
    String? color,
    bool generateSummary = true,
    bool useAiEnhancement = true,
    bool generateFlashcards = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _createdNote = null;
    _createdSummary = null;
    _createdFlashcards = [];
    _extractedText = null;
    _wordCount = null;
    notifyListeners();

    try {
      final params = CreateNoteFromImageParams(
        imageFile: imageFile,
        title: title,
        color: color,
        generateSummary: generateSummary,
        useAiEnhancement: useAiEnhancement,
        generateFlashcards: generateFlashcards,
      );

      final result = await _createNoteFromImageUseCase.execute(params);

      _createdNote = result.note;
      _createdSummary = result.summary;
      _createdFlashcards = result.flashcards;
      _extractedText = result.extractedText;
      _wordCount = result.wordCount;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create note from image: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Create a note from a PDF file
  Future<bool> createNoteFromPdf({
    required File pdfFile,
    String title = '',
    String? color,
    bool generateSummary = true,
    bool useAiEnhancement = true,
    bool generateFlashcards = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _createdNote = null;
    _createdSummary = null;
    _createdFlashcards = [];
    _extractedText = null;
    _wordCount = null;
    notifyListeners();

    try {
      final params = CreateNoteFromPdfParams(
        pdfFile: pdfFile,
        title: title,
        color: color,
        generateSummary: generateSummary,
        useAiEnhancement: useAiEnhancement,
        generateFlashcards: generateFlashcards,
      );

      final result = await _createNoteFromPdfUseCase.execute(params);

      _createdNote = result.note;
      _createdSummary = result.summary;
      _createdFlashcards = result.flashcards;
      _extractedText = result.extractedText;
      _wordCount = result.wordCount;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create note from PDF: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Clear the current state
  void clear() {
    _isLoading = false;
    _errorMessage = null;
    _createdNote = null;
    _createdSummary = null;
    _createdFlashcards = [];
    _extractedText = null;
    _wordCount = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get creation statistics
  Map<String, dynamic> getCreationStats() {
    if (_createdNote == null) return {};

    return {
      'noteCreated': _createdNote != null,
      'summaryCreated': _createdSummary != null,
      'flashcardsCreated': _createdFlashcards.length,
      'wordCount': _wordCount,
      'extractedText': _extractedText != null,
    };
  }
}
