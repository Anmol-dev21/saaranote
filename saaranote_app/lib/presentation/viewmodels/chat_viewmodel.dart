import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/usecases/ask_question_usecase.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/index_document_usecase.dart';

/// ViewModel for managing AI chat interface
/// 
/// Uses MVVM pattern with ChangeNotifier for state management
class ChatViewModel extends ChangeNotifier {
  final AskQuestionUseCase _askQuestionUseCase;
  final ChatRepository _chatRepository;

  ChatViewModel({
    required AskQuestionUseCase askQuestionUseCase,
    required ChatRepository chatRepository,
    IndexDocumentUseCase? indexDocumentUseCase,
  })  : _askQuestionUseCase = askQuestionUseCase,
        _chatRepository = chatRepository;

  // State
  ChatSession? _currentSession;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  String _inputText = '';
  
  // Scoped context state
  int? _scopedFolderId;
  String? _scopedFolderName;
  List<int>? _scopedNoteIds;
  
  // Quick action state
  QuickAction? _activeQuickAction;

  // Getters
  ChatSession? get currentSession => _currentSession;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasMessages => _messages.isNotEmpty;
  int get messageCount => _messages.length;
  String get inputText => _inputText;
  
  // Scope getters
  bool get hasScope => _scopedFolderId != null || _scopedNoteIds != null;
  String? get scopedFolderName => _scopedFolderName;
  int? get scopedFolderId => _scopedFolderId;
  List<int>? get scopedNoteIds => _scopedNoteIds;
  
  // Quick action getters
  QuickAction? get activeQuickAction => _activeQuickAction;
  bool get hasActiveQuickAction => _activeQuickAction != null;

  /// Initialize or load a chat session
  Future<void> initializeSession({int? sessionId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (sessionId != null) {
        // Load existing session
        _currentSession = await _chatRepository.getSession(sessionId);
        if (_currentSession != null) {
          _messages = await _chatRepository.getMessages(_currentSession!.id!);
        }
      } else {
        // Create new session
        _currentSession = await _chatRepository.createSession('New Chat');
        _messages = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to initialize chat: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Send a question to the AI assistant
  Future<void> sendQuestion(String question) async {
    if (question.trim().isEmpty || _currentSession == null || _isSending) {
      return;
    }

    _isSending = true;
    _errorMessage = null;
    _inputText = '';
    notifyListeners();

    try {
      // Execute use case
      await _askQuestionUseCase.execute(
        AskQuestionParams(
          question: question,
          sessionId: _currentSession!.id!,
          scopedNoteIds: _scopedNoteIds,
        ),
      );

      // Reload messages to get both user and assistant messages
      _messages = await _chatRepository.getMessages(_currentSession!.id!);

      _isSending = false;
      notifyListeners();
    } catch (e) {
      _isSending = false;
      _errorMessage = 'Failed to send question: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Execute a quick action
  Future<void> executeQuickAction(QuickAction action, {String? customInput}) async {
    if (_currentSession == null || _isSending) {
      return;
    }

    _activeQuickAction = action;
    notifyListeners();

    String question;
    switch (action) {
      case QuickAction.summarize:
        question = customInput ?? 'Summarize the key information from my notes';
        break;
      case QuickAction.extractKeyPoints:
        question = customInput ?? 'Extract the key points from my notes';
        break;
      case QuickAction.generateFlashcards:
        question = customInput ?? 'Generate flashcards from my notes for studying';
        break;
    }

    await sendQuestion(question);
    _activeQuickAction = null;
    notifyListeners();
  }

  /// Set scope to a specific folder
  void setScopeToFolder(int folderId, String folderName) {
    _scopedFolderId = folderId;
    _scopedFolderName = folderName;
    _scopedNoteIds = null; // Clear note scope
    notifyListeners();
  }

  /// Set scope to specific notes
  void setScopeToNotes(List<int> noteIds) {
    _scopedNoteIds = noteIds;
    _scopedFolderId = null;
    _scopedFolderName = null;
    notifyListeners();
  }

  /// Clear scope (ask from all notes)
  void clearScope() {
    _scopedFolderId = null;
    _scopedFolderName = null;
    _scopedNoteIds = null;
    notifyListeners();
  }

  /// Update input text
  void updateInputText(String text) {
    _inputText = text;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Delete a message
  Future<void> deleteMessage(int messageId) async {
    if (_currentSession == null) return;

    try {
      await _chatRepository.deleteMessage(messageId);
      _messages = await _chatRepository.getMessages(_currentSession!.id!);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete message: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Refresh messages
  Future<void> refreshMessages() async {
    if (_currentSession == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _messages = await _chatRepository.getMessages(_currentSession!.id!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to refresh messages: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Get all chat sessions
  Future<List<ChatSession>> getAllSessions() async {
    try {
      return await _chatRepository.getAllSessions();
    } catch (e) {
      _errorMessage = 'Failed to load sessions: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  /// Delete current session
  Future<void> deleteCurrentSession() async {
    if (_currentSession == null) return;

    try {
      await _chatRepository.deleteSession(_currentSession!.id!);
      _currentSession = null;
      _messages = [];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete session: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Initialize the chat (convenience method for initializeSession)
  Future<void> initialize({int? sessionId}) async {
    await initializeSession(sessionId: sessionId);
  }

  /// Send a message (convenience method for sendQuestion)
  Future<void> sendMessage(String message) async {
    await sendQuestion(message);
  }

  /// Create a new chat session
  Future<void> createNewSession() async {
    await initializeSession(sessionId: null);
  }
}

/// Quick action types for one-tap commands
enum QuickAction {
  summarize,
  extractKeyPoints,
  generateFlashcards,
}
