import '../entities/chat_message.dart';
import '../entities/chat_session.dart';

/// Repository interface for chat operations
abstract class ChatRepository {
  /// Create a new chat session
  Future<ChatSession> createSession(String title);

  /// Get all chat sessions
  Future<List<ChatSession>> getAllSessions();

  /// Get a specific chat session by ID
  Future<ChatSession?> getSession(int id);

  /// Delete a chat session
  Future<void> deleteSession(int id);

  /// Add a message to a session
  Future<ChatMessage> addMessage(ChatMessage message, int sessionId);

  /// Get all messages in a session
  Future<List<ChatMessage>> getMessages(int sessionId);

  /// Delete a message
  Future<void> deleteMessage(int id);
}
