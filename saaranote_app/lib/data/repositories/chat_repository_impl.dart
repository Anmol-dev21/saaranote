import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

/// Implementation of ChatRepository using SQLite
class ChatRepositoryImpl implements ChatRepository {
  final DatabaseHelper _databaseHelper;

  ChatRepositoryImpl(this._databaseHelper);

  @override
  Future<ChatSession> createSession(String title) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final id = await db.insert('chat_sessions', {
      'title': title,
      'created_at': now,
      'updated_at': now,
    });

    return ChatSession(
      id: id,
      title: title,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  @override
  Future<List<ChatSession>> getAllSessions() async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'chat_sessions',
      orderBy: 'updated_at DESC',
    );

    return results
        .map((map) => ChatSessionModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<ChatSession?> getSession(int id) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return ChatSessionModel.fromMap(results.first).toEntity();
  }

  @override
  Future<void> deleteSession(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<ChatMessage> addMessage(ChatMessage message, int sessionId) async {
    final db = await _databaseHelper.database;
    final model = ChatMessageModel.fromEntity(message);

    final messageId = await db.insert('chat_messages', {
      'session_id': sessionId,
      ...model.toMap(),
    });

    if (message.sources != null) {
      for (final source in message.sources!) {
        await db.insert('message_sources', {
          'message_id': messageId,
          'file_metadata_id': source.fileMetadataId,
          'chunk_id': source.chunkId,
          'relevance_score': source.relevanceScore,
        });
      }
    }

    await db.update(
      'chat_sessions',
      {'updated_at': message.timestamp.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    return message.copyWith(id: messageId);
  }

  @override
  Future<List<ChatMessage>> getMessages(int sessionId) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    final messages = <ChatMessage>[];

    for (final row in results) {
      final messageId = row['id'] as int;

      final sourcesResults = await db.rawQuery('''
        SELECT
          ms.*, fm.file_name, dc.content
        FROM message_sources ms
        JOIN file_metadata fm ON ms.file_metadata_id = fm.id
        JOIN document_chunks dc ON ms.chunk_id = dc.id
        WHERE ms.message_id = ?
      ''', [messageId]);

      final sources = sourcesResults.map((s) => CitedSource(
        fileMetadataId: s['file_metadata_id'] as int,
        fileName: s['file_name'] as String,
        chunkId: s['chunk_id'] as int,
        excerpt: (s['content'] as String).length > 150
            ? '${(s['content'] as String).substring(0, 150)}...'
            : s['content'] as String,
        relevanceScore: s['relevance_score'] as double,
      )).toList();

      final message = ChatMessageModel.fromMap(row).toEntity().copyWith(
        sources: sources.isEmpty ? null : sources,
      );

      messages.add(message);
    }

    return messages;
  }

  @override
  Future<void> deleteMessage(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
