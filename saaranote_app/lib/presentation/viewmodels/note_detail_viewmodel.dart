import 'package:flutter/foundation.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/summary.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/usecases/get_note_by_id_usecase.dart';
import '../../domain/usecases/get_summaries_for_note_usecase.dart';
import '../../domain/usecases/get_flashcards_for_note_usecase.dart';

/// ViewModel for viewing a single note with its details
/// 
/// Uses MVVM pattern with ChangeNotifier for state management
class NoteDetailViewModel extends ChangeNotifier {
  final GetNoteByIdUseCase _getNoteByIdUseCase;
  final GetSummariesForNoteUseCase _getSummariesForNoteUseCase;
  final GetFlashcardsForNoteUseCase _getFlashcardsForNoteUseCase;

  NoteDetailViewModel(
    this._getNoteByIdUseCase,
    this._getSummariesForNoteUseCase,
    this._getFlashcardsForNoteUseCase,
  );

  // State
  Note? _note;
  List<Summary> _summaries = [];
  List<Flashcard> _flashcards = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Note? get note => _note;
  List<Summary> get summaries => _summaries;
  List<Flashcard> get flashcards => _flashcards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasNote => _note != null;
  bool get hasSummaries => _summaries.isNotEmpty;
  bool get hasFlashcards => _flashcards.isNotEmpty;
  int get summaryCount => _summaries.length;
  int get flashcardCount => _flashcards.length;

  /// Load note details including summaries and flashcards
  Future<void> loadNoteDetails(int noteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load note
      _note = await _getNoteByIdUseCase.execute(noteId);

      // Load summaries
      _summaries = await _getSummariesForNoteUseCase.execute(noteId);

      // Load flashcards
      _flashcards = await _getFlashcardsForNoteUseCase.execute(noteId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load note details: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Refresh note details
  Future<void> refresh() async {
    if (_note != null) {
      await loadNoteDetails(_note!.id!);
    }
  }

  /// Get the most recent summary
  Summary? get latestSummary {
    if (_summaries.isEmpty) return null;
    return _summaries.first;
  }

  /// Clear current state
  void clear() {
    _note = null;
    _summaries = [];
    _flashcards = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
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
