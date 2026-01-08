import 'package:flutter/foundation.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/usecases/get_flashcards_for_note_usecase.dart';

/// ViewModel for managing flashcard display and navigation
/// 
/// Uses MVVM pattern with ChangeNotifier for state management
class FlashcardViewModel extends ChangeNotifier {
  final GetFlashcardsForNoteUseCase _getFlashcardsForNoteUseCase;

  FlashcardViewModel(this._getFlashcardsForNoteUseCase);

  // State
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Flashcard> get flashcards => _flashcards;
  int get currentIndex => _currentIndex;
  bool get showAnswer => _showAnswer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasFlashcards => _flashcards.isNotEmpty;
  int get totalFlashcards => _flashcards.length;

  /// Get current flashcard safely
  Flashcard? get currentFlashcard {
    if (_currentIndex >= 0 && _currentIndex < _flashcards.length) {
      return _flashcards[_currentIndex];
    }
    return null;
  }

  /// Check if can navigate to next card
  bool get canGoNext => _currentIndex < _flashcards.length - 1;

  /// Check if can navigate to previous card
  bool get canGoPrevious => _currentIndex > 0;

  /// Load flashcards for a specific note
  /// 
  /// [noteId] can be either String or int - will be converted appropriately
  Future<void> loadFlashcards(dynamic noteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Convert noteId to int if it's a String
      final int id = noteId is String ? int.parse(noteId) : noteId as int;
      
      _flashcards = await _getFlashcardsForNoteUseCase.execute(id);
      _currentIndex = 0;
      _showAnswer = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load flashcards: ${e.toString()}';
      _flashcards = [];
      notifyListeners();
    }
  }

  /// Move to next flashcard
  /// 
  /// Prevents index out-of-range by checking canGoNext
  void nextCard() {
    if (canGoNext) {
      _currentIndex++;
      _showAnswer = false; // Reset answer visibility
      notifyListeners();
    }
  }

  /// Move to previous flashcard
  /// 
  /// Prevents index out-of-range by checking canGoPrevious
  void previousCard() {
    if (canGoPrevious) {
      _currentIndex--;
      _showAnswer = false; // Reset answer visibility
      notifyListeners();
    }
  }

  /// Toggle answer visibility
  void toggleAnswer() {
    _showAnswer = !_showAnswer;
    notifyListeners();
  }

  /// Reset to first card
  void reset() {
    _currentIndex = 0;
    _showAnswer = false;
    notifyListeners();
  }

  /// Clear all state
  void clear() {
    _flashcards = [];
    _currentIndex = 0;
    _showAnswer = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
