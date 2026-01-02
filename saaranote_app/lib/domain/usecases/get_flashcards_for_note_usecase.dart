import '../entities/flashcard.dart';
import '../repositories/flashcard_repository.dart';

/// Use case for retrieving flashcards for a specific note
class GetFlashcardsForNoteUseCase {
  final FlashcardRepository _flashcardRepository;

  GetFlashcardsForNoteUseCase(this._flashcardRepository);

  /// Execute the use case to retrieve flashcards for a note
  /// 
  /// Returns a list of flashcards for the specified note ID.
  Future<List<Flashcard>> execute(int noteId) async {
    return await _flashcardRepository.getByNoteId(noteId);
  }
}
