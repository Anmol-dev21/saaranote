import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_summary.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/entities/drawing.dart';
import '../../domain/entities/file_metadata.dart';
import '../../domain/usecases/get_note_by_id_usecase.dart';
import '../../domain/usecases/get_summaries_for_note_usecase.dart';
import '../../domain/usecases/get_flashcards_for_note_usecase.dart';
import '../../domain/usecases/get_source_file_for_note_usecase.dart';
import '../../core/services/pdf_export_service.dart';
import '../../data/datasources/local/drawing_local_data_source.dart';

/// ViewModel for viewing a single note with its details
/// 
/// Uses MVVM pattern with ChangeNotifier for state management
class NoteDetailViewModel extends ChangeNotifier {
  final GetNoteByIdUseCase _getNoteByIdUseCase;
  final GetSummariesForNoteUseCase _getSummariesForNoteUseCase;
  final GetFlashcardsForNoteUseCase _getFlashcardsForNoteUseCase;
  final GetSourceFileForNoteUseCase _getSourceFileForNoteUseCase;
  final PdfExportService _pdfExportService;
  final DrawingLocalDataSource _drawingLocalDataSource;

  NoteDetailViewModel(
    this._getNoteByIdUseCase,
    this._getSummariesForNoteUseCase,
    this._getFlashcardsForNoteUseCase,
    this._getSourceFileForNoteUseCase,
    this._pdfExportService,
    this._drawingLocalDataSource,
  );

  // State
  Note? _note;
  List<NoteSummary> _summaries = [];
  List<Flashcard> _flashcards = [];
  List<Drawing> _drawings = [];
  FileMetadata? _sourceFile;
  bool _isLoading = false;
  String? _errorMessage;
  File? _exportedPdfFile;
  bool _isExporting = false;
  bool _isDisposed = false;

  // Getters
  Note? get note => _note;
  List<NoteSummary> get summaries => _summaries;
  List<Flashcard> get flashcards => _flashcards;
  List<Drawing> get drawings => _drawings;
  FileMetadata? get sourceFile => _sourceFile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasNote => _note != null;
  bool get hasSummaries => _summaries.isNotEmpty;
  bool get hasFlashcards => _flashcards.isNotEmpty;
  bool get hasDrawings => _drawings.isNotEmpty;
  bool get hasSourceFile => _sourceFile != null;
  int get summaryCount => _summaries.length;
  int get flashcardCount => _flashcards.length;
  File? get exportedPdfFile => _exportedPdfFile;
  bool get isExporting => _isExporting;
  bool get hasPdfExport => _exportedPdfFile != null;

  /// Load note details including summaries and flashcards
  Future<void> loadNoteDetails(int noteId) async {
    _isLoading = true;
    _errorMessage = null;
    _sourceFile = null;
    _notifySafely();

    try {
      // Load note
      _note = await _getNoteByIdUseCase.execute(noteId);
      if (_note == null) {
        _isLoading = false;
        _errorMessage = 'Note not found';
        _notifySafely();
        return;
      }

        // Load linked source file (image/pdf) if available
        _sourceFile = _note?.id != null
          ? await _getSourceFileForNoteUseCase.execute(_note!.id!)
          : null;

      // Load summaries
      _summaries = await _getSummariesForNoteUseCase.execute(noteId);

      // Load flashcards
      _flashcards = await _getFlashcardsForNoteUseCase.execute(noteId);

      // Load drawings
      if (_note?.drawingIds != null && _note!.drawingIds!.isNotEmpty) {
        _drawings = await _drawingLocalDataSource.getDrawingsByIds(_note!.drawingIds!);
      } else {
        _drawings = await _drawingLocalDataSource.getDrawingsByNoteId(noteId);
      }

      _isLoading = false;
      _notifySafely();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load note details: ${e.toString()}';
      _notifySafely();
    }
  }

  /// Refresh note details
  Future<void> refresh() async {
    if (_note != null) {
      await loadNoteDetails(_note!.id!);
    }
  }

  /// Get the most recent summary
  NoteSummary? get latestSummary {
    if (_summaries.isEmpty) return null;
    return _summaries.first;
  }

  /// Clear current state
  void clear() {
    _note = null;
    _summaries = [];
    _flashcards = [];
    _drawings = [];
    _sourceFile = null;
    _isLoading = false;
    _errorMessage = null;
    _exportedPdfFile = null;
    _isExporting = false;
    _notifySafely();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    _notifySafely();
  }

  /// Export the current note as PDF
  Future<void> exportNoteAsPdf() async {
    if (_note == null) {
      _errorMessage = 'No note loaded to export';
      notifyListeners();
      return;
    }

    _isExporting = true;
    _errorMessage = null;
    _exportedPdfFile = null;
    notifyListeners();

    try {
      // Get the latest summary if available
      final summary = latestSummary;

      // Export note to PDF
      _exportedPdfFile = await _pdfExportService.exportNoteToPdf(
        _note!,
        summary: summary,
        flashcards: _flashcards.isNotEmpty ? _flashcards : null,
      );

      _isExporting = false;
      _notifySafely();
    } catch (e) {
      _isExporting = false;
      _errorMessage = 'Failed to export PDF: ${e.toString()}';
      _exportedPdfFile = null;
      _notifySafely();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifySafely() {
    if (_isDisposed) return;
    notifyListeners();
  }

  /// Get note statistics
  Map<String, dynamic> getNoteStats() {
    if (_note == null) return {};

    return {
      'title': _note!.title,
      'wordCount': _note!.content.split(RegExp(r'\s+')).length,
      'characterCount': _note!.content.length,
      'summaryCount': _summaries.length,
      'flashcardCount': _flashcards.length,
      'createdAt': _note!.createdAt,
      'updatedAt': _note!.updatedAt,
      'isArchived': _note!.isArchived,
    };
  }
}
