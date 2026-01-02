import '../entities/summary.dart';
import '../repositories/summary_repository.dart';

/// Use case for retrieving summaries for a specific note
class GetSummariesForNoteUseCase {
  final SummaryRepository _summaryRepository;

  GetSummariesForNoteUseCase(this._summaryRepository);

  /// Execute the use case to retrieve summaries for a note
  /// 
  /// Returns a list of summaries for the specified note ID.
  Future<List<Summary>> execute(int noteId) async {
    return await _summaryRepository.getByNoteId(noteId);
  }
}
