import '../entities/chat_message.dart';
import '../entities/chat_session.dart';

abstract class ChatRepository {
  Future<ChatSession> createSession(String title);
  Future<List<ChatSession>> getAllSessions();
  Future<ChatSession?> getSession(int id);
  Future<void> deleteSession(int id);
  Future<ChatMessage> addMessage(ChatMessage message, int sessionId);
  Future<List<ChatMessage>> getMessages(int sessionId);
  Future<void> deleteMessage(int id);
}
