import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/ask_question_usecase.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final AskQuestionUseCase _askQuestionUseCase;

  ChatViewModel(this._chatRepository, this._askQuestionUseCase);

  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  bool _isDisposed = false;

  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  List<ChatMessage> _messages = [];

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  List<ChatSession> get sessions => _sessions;
  ChatSession? get currentSession => _currentSession;
  List<ChatMessage> get messages => _messages;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _loadSessionsAndMessages();
  }

  Future<void> refresh() async {
    await _loadSessionsAndMessages();
  }

  Future<void> createNewSession() async {
    _setLoading(true);
    try {
      final session = await _chatRepository.createSession(_buildSessionTitle());
      _sessions = [session, ..._sessions];
      _currentSession = session;
      _messages = [];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to start a new chat: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSession(ChatSession session) async {
    _currentSession = session;
    await _loadMessagesForCurrent();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (_isSending) return;

    if (_currentSession == null) {
      await createNewSession();
    }

    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      _errorMessage = 'Unable to start a chat session.';
      _notifySafely();
      return;
    }

    final pendingMessage = ChatMessage(
      content: trimmed,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    _messages = [..._messages, pendingMessage];

    _isSending = true;
    _errorMessage = null;
    _notifySafely();

    try {
      await _askQuestionUseCase
          .execute(
            AskQuestionParams(
              question: trimmed,
              sessionId: sessionId,
            ),
          )
          .timeout(const Duration(seconds: 20));
      await _loadSessionsAndMessages();
    } on TimeoutException {
      _errorMessage = 'Request timed out. Try again.';
    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
    } finally {
      _isSending = false;
      _notifySafely();
    }
  }

  Future<void> _loadSessionsAndMessages() async {
    _setLoading(true);
    try {
      _sessions = await _chatRepository.getAllSessions();
      if (_sessions.isEmpty) {
        _currentSession = await _chatRepository.createSession(_buildSessionTitle());
        _sessions = [_currentSession!];
      } else {
        _currentSession ??= _sessions.first;
      }
      await _loadMessagesForCurrent();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load chats: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadMessagesForCurrent() async {
    final sessionId = _currentSession?.id;
    if (sessionId == null) {
      _messages = [];
      _notifySafely();
      return;
    }
    _messages = await _chatRepository.getMessages(sessionId);
    _notifySafely();
  }

  String _buildSessionTitle() {
    final count = _sessions.length + 1;
    return 'Conversation $count';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notifySafely();
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
}
