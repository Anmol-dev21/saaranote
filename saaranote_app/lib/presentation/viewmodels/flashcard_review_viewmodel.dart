import 'package:flutter/foundation.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/flashcard_repository.dart';

/// ViewModel for managing flashcard review sessions
/// 
/// Uses MVVM pattern with ChangeNotifier for state management
class FlashcardReviewViewModel extends ChangeNotifier {
  final FlashcardRepository _flashcardRepository;

  FlashcardReviewViewModel(this._flashcardRepository);

  // State
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showAnswer = false;
  final Map<int, int> _reviewedCards = {}; // flashcardId -> confidenceLevel

  // Getters
  List<Flashcard> get flashcards => _flashcards;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get showAnswer => _showAnswer;
  bool get hasFlashcards => _flashcards.isNotEmpty;
  int get totalFlashcards => _flashcards.length;
  int get reviewedCount => _reviewedCards.length;
  int get remainingCount => totalFlashcards - reviewedCount;
  bool get isComplete => reviewedCount == totalFlashcards && totalFlashcards > 0;
  double get progress => totalFlashcards > 0 ? reviewedCount / totalFlashcards : 0.0;

  Flashcard? get currentFlashcard {
    if (_currentIndex >= 0 && _currentIndex < _flashcards.length) {
      return _flashcards[_currentIndex];
    }
    return null;
  }

  bool get canGoNext => _currentIndex < _flashcards.length - 1;
  bool get canGoPrevious => _currentIndex > 0;

  /// Load flashcards for review (all due for review)
  Future<void> loadFlashcardsForReview() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _flashcards = await _flashcardRepository.getDueForReview();
      _currentIndex = 0;
      _showAnswer = false;
      _reviewedCards.clear();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load flashcards: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Load flashcards for a specific note
  Future<void> loadFlashcardsForNote(int noteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _flashcards = await _flashcardRepository.getByNoteId(noteId);
      _currentIndex = 0;
      _showAnswer = false;
      _reviewedCards.clear();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load flashcards: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Toggle answer visibility
  void toggleAnswer() {
    _showAnswer = !_showAnswer;
    notifyListeners();
  }

  /// Show the answer
  void showAnswerView() {
    _showAnswer = true;
    notifyListeners();
  }

  /// Hide the answer
  void hideAnswer() {
    _showAnswer = false;
    notifyListeners();
  }

  /// Move to next flashcard
  void nextCard() {
    if (canGoNext) {
      _currentIndex++;
      _showAnswer = false;
      notifyListeners();
    }
  }

  /// Move to previous flashcard
  void previousCard() {
    if (canGoPrevious) {
      _currentIndex--;
      _showAnswer = false;
      notifyListeners();
    }
  }

  /// Rate current flashcard and update confidence level
  Future<void> rateCard(int confidenceLevel) async {
    final card = currentFlashcard;
    if (card == null || card.id == null) return;

    try {
      // Update confidence level in repository
      await _flashcardRepository.updateConfidenceLevel(card.id!, confidenceLevel);

      // Track reviewed card
      _reviewedCards[card.id!] = confidenceLevel;

      // Move to next card if available
      if (canGoNext) {
        nextCard();
      } else {
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update flashcard: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Reset review session
  void resetSession() {
    _currentIndex = 0;
    _showAnswer = false;
    _reviewedCards.clear();
    notifyListeners();
  }

  /// Clear state
  void clear() {
    _flashcards = [];
    _currentIndex = 0;
    _isLoading = false;
    _errorMessage = null;
    _showAnswer = false;
    _reviewedCards.clear();
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get review statistics
  Map<String, dynamic> getReviewStats() {
    final stats = <String, dynamic>{
      'total': totalFlashcards,
      'reviewed': reviewedCount,
      'remaining': remainingCount,
      'progress': progress,
      'isComplete': isComplete,
    };

    // Calculate average confidence
    if (_reviewedCards.isNotEmpty) {
      final avgConfidence = _reviewedCards.values.reduce((a, b) => a + b) / _reviewedCards.length;
      stats['averageConfidence'] = avgConfidence;
    }

    return stats;
  }
}
