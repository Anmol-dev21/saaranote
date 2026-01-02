import 'package:flutter/foundation.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/get_all_notes_usecase.dart';
import '../../domain/usecases/get_note_by_id_usecase.dart';
import '../../domain/usecases/update_note_usecase.dart';
import '../../domain/usecases/delete_note_usecase.dart';

/// ViewModel for managing notes list and operations
/// 
/// Uses MVVM pattern with ChangeNotifier for state management
class NoteViewModel extends ChangeNotifier {
  final GetAllNotesUseCase _getAllNotesUseCase;
  final GetNoteByIdUseCase _getNoteByIdUseCase;
  final UpdateNoteUseCase _updateNoteUseCase;
  final DeleteNoteUseCase _deleteNoteUseCase;

  NoteViewModel(
    this._getAllNotesUseCase,
    this._getNoteByIdUseCase,
    this._updateNoteUseCase,
    this._deleteNoteUseCase,
  );

  // State
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;
  NoteFilter _currentFilter = NoteFilter.active;
  NoteSortBy _currentSort = NoteSortBy.createdDateDesc;
  String? _searchQuery;

  // Getters
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasNotes => _notes.isNotEmpty;
  int get noteCount => _notes.length;
  NoteFilter get currentFilter => _currentFilter;
  NoteSortBy get currentSort => _currentSort;
  String? get searchQuery => _searchQuery;

  /// Fetch all notes with current filter and sort settings
  Future<void> fetchNotes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final params = GetAllNotesParams(
        filter: _currentFilter,
        sortBy: _currentSort,
        searchQuery: _searchQuery,
      );

      _notes = await _getAllNotesUseCase.execute(params: params);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load notes: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Refresh notes list
  Future<void> refresh() async {
    await fetchNotes();
  }

  /// Set filter and reload notes
  Future<void> setFilter(NoteFilter filter) async {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      await fetchNotes();
    }
  }

  /// Set sort order and reload notes
  Future<void> setSortBy(NoteSortBy sortBy) async {
    if (_currentSort != sortBy) {
      _currentSort = sortBy;
      await fetchNotes();
    }
  }

  /// Set search query and reload notes
  Future<void> search(String? query) async {
    _searchQuery = query?.trim();
    await fetchNotes();
  }

  /// Clear search query
  Future<void> clearSearch() async {
    if (_searchQuery != null) {
      _searchQuery = null;
      await fetchNotes();
    }
  }

  /// Get a specific note by ID
  Future<Note?> getNoteById(int id) async {
    try {
      return await _getNoteByIdUseCase.execute(id);
    } catch (e) {
      _errorMessage = 'Failed to load note: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Update a note
  Future<bool> updateNote({
    required int noteId,
    String? title,
    String? content,
    String? color,
  }) async {
    try {
      final params = UpdateNoteParams(
        noteId: noteId,
        title: title,
        content: content,
        color: color,
      );

      await _updateNoteUseCase.execute(params);
      
      // Refresh the notes list
      await fetchNotes();
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update note: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Delete a note
  Future<bool> deleteNote(int noteId) async {
    try {
      await _deleteNoteUseCase.execute(noteId);
      
      // Remove from local list immediately for better UX
      _notes.removeWhere((note) => note.id == noteId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete note: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Archive a note
  Future<bool> archiveNote(int noteId) async {
    final note = _notes.firstWhere(
      (n) => n.id == noteId,
      orElse: () => throw Exception('Note not found'),
    );

    return await updateNote(
      noteId: noteId,
      title: note.title,
      content: note.content,
    );
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get statistics about notes
  Map<String, int> getStatistics() {
    return {
      'total': _notes.length,
      'archived': _notes.where((n) => n.isArchived).length,
      'active': _notes.where((n) => !n.isArchived).length,
    };
  }
}
