import '../entities/note.dart';
import '../repositories/note_repository.dart';

/// Use case for retrieving all notes from the repository
class GetAllNotesUseCase {
  final NoteRepository _noteRepository;

  GetAllNotesUseCase(this._noteRepository);

  /// Execute the use case to retrieve all notes
  /// 
  /// Returns a list of all notes, optionally filtered and sorted.
  /// By default, returns active (non-archived) notes sorted by creation date.
  Future<List<Note>> execute({GetAllNotesParams? params}) async {
    final parameters = params ?? GetAllNotesParams();

    List<Note> notes;

    // Fetch notes based on filter
    switch (parameters.filter) {
      case NoteFilter.all:
        notes = await _noteRepository.getAll();
        break;
      case NoteFilter.active:
        notes = await _noteRepository.getActive();
        break;
      case NoteFilter.archived:
        notes = await _noteRepository.getArchived();
        break;
    }

    // Apply search query if provided
    if (parameters.searchQuery != null && parameters.searchQuery!.isNotEmpty) {
      final query = parameters.searchQuery!.toLowerCase();
      notes = notes.where((note) {
        return note.title.toLowerCase().contains(query) ||
               note.content.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    switch (parameters.sortBy) {
      case NoteSortBy.createdDateDesc:
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NoteSortBy.createdDateAsc:
        notes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case NoteSortBy.updatedDateDesc:
        notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case NoteSortBy.updatedDateAsc:
        notes.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case NoteSortBy.titleAsc:
        notes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case NoteSortBy.titleDesc:
        notes.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }

    return notes;
  }
}

/// Parameters for retrieving notes
class GetAllNotesParams {
  final NoteFilter filter;
  final NoteSortBy sortBy;
  final String? searchQuery;

  GetAllNotesParams({
    this.filter = NoteFilter.active,
    this.sortBy = NoteSortBy.createdDateDesc,
    this.searchQuery,
  });
}

/// Filter options for notes
enum NoteFilter {
  all,
  active,
  archived,
}

/// Sorting options for notes
enum NoteSortBy {
  createdDateDesc,
  createdDateAsc,
  updatedDateDesc,
  updatedDateAsc,
  titleAsc,
  titleDesc,
}
