import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('saaranote.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Incremented from 2 to 3 for file organization support
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const integerType = 'INTEGER NOT NULL';

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id $idType,
        title $textType,
        content $textType,
        created_at $integerType,
        updated_at $integerType,
        is_archived $integerType DEFAULT 0,
        color $textNullableType,
        rich_content $textNullableType,
        drawing_ids $textNullableType,
        content_type $textNullableType DEFAULT 'plain'
      )
    ''');

    // Summaries table
    await db.execute('''
      CREATE TABLE summaries (
        id $idType,
        note_id $integerType,
        summary_text $textType,
        created_at $integerType,
        FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');

    // Flashcards table
    await db.execute('''
      CREATE TABLE flashcards (
        id $idType,
        note_id $integerType,
        question $textType,
        answer $textType,
        created_at $integerType,
        last_reviewed_at $integerType,
        confidence_level $integerType DEFAULT 0,
        FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
        'CREATE INDEX idx_notes_created_at ON notes(created_at DESC)');
    await db.execute('CREATE INDEX idx_summaries_note_id ON summaries(note_id)');
    await db.execute(
        'CREATE INDEX idx_flashcards_note_id ON flashcards(note_id)');

    // File metadata table (for file organization system)
    if (version >= 3) {
      await db.execute('''
        CREATE TABLE file_metadata (
          id $idType,
          file_path $textType UNIQUE,
          file_name $textType,
          file_type $integerType,
          subject $textNullableType,
          created_at $integerType,
          last_modified $integerType,
          file_size $integerType,
          related_note_id $textNullableType,
          organization_status $integerType DEFAULT 0,
          custom_folder $textNullableType,
          tags $textNullableType
        )
      ''');

      // Organization rules table
      await db.execute('''
        CREATE TABLE organization_rules (
          id $textType PRIMARY KEY,
          name $textType,
          subject_pattern $textNullableType,
          file_type $integerType,
          target_folder $textType,
          priority $integerType DEFAULT 0,
          is_enabled $integerType DEFAULT 1
        )
      ''');

      // Create indexes for file organization
      await db.execute('CREATE INDEX idx_file_metadata_subject ON file_metadata(subject)');
      await db.execute('CREATE INDEX idx_file_metadata_type ON file_metadata(file_type)');
      await db.execute('CREATE INDEX idx_file_metadata_status ON file_metadata(organization_status)');
      await db.execute('CREATE INDEX idx_file_metadata_created ON file_metadata(created_at DESC)');
      await db.execute('CREATE INDEX idx_organization_rules_priority ON organization_rules(priority DESC)');
    }
<<<<<<< Updated upstream
=======

    // AI Chat system tables (version 4+)
    if (version >= 4) {
      // Document chunks for AI retrieval
      await db.execute('''
        CREATE TABLE document_chunks (
          id $idType,
          file_metadata_id $integerType NOT NULL,
          chunk_index $integerType NOT NULL,
          content $textType,
          token_count $integerType,
          created_at $integerType NOT NULL,
          FOREIGN KEY (file_metadata_id) REFERENCES file_metadata(id) ON DELETE CASCADE
        )
      ''');

      await _createDocumentChunksFts(db);

      // Chat sessions
      await db.execute('''
        CREATE TABLE chat_sessions (
          id $idType,
          title $textType,
          created_at $integerType NOT NULL,
          updated_at $integerType NOT NULL,
          tags $textNullableType
        )
      ''');

      // Chat messages
      await db.execute('''
        CREATE TABLE chat_messages (
          id $idType,
          session_id $integerType NOT NULL,
          role $textType NOT NULL CHECK(role IN ('user', 'assistant')),
          content $textType,
          timestamp $integerType NOT NULL,
          status $textType NOT NULL CHECK(status IN ('sending', 'sent', 'error')),
          FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
        )
      ''');

      // Message sources (citations)
      await db.execute('''
        CREATE TABLE message_sources (
          id $idType,
          message_id $integerType NOT NULL,
          file_metadata_id $integerType NOT NULL,
          chunk_id $integerType NOT NULL,
          relevance_score REAL NOT NULL,
          FOREIGN KEY (message_id) REFERENCES chat_messages(id) ON DELETE CASCADE,
          FOREIGN KEY (file_metadata_id) REFERENCES file_metadata(id) ON DELETE CASCADE,
          FOREIGN KEY (chunk_id) REFERENCES document_chunks(id) ON DELETE CASCADE
        )
      ''');

      // Create indexes for AI chat
      await db.execute('CREATE INDEX idx_chunks_file ON document_chunks(file_metadata_id)');
      await db.execute('CREATE INDEX idx_messages_session ON chat_messages(session_id)');
      await db.execute('CREATE INDEX idx_messages_timestamp ON chat_messages(timestamp DESC)');
      await db.execute('CREATE INDEX idx_sources_message ON message_sources(message_id)');
    }
>>>>>>> Stashed changes
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here when version changes
    
    // Version 1 -> 2: Add advanced note content support (rich text, drawings)
    if (oldVersion < 2) {
      // Add new columns for rich content support
      // All columns are nullable to maintain backward compatibility
      await db.execute('ALTER TABLE notes ADD COLUMN rich_content TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN drawing_ids TEXT');
      await db.execute("ALTER TABLE notes ADD COLUMN content_type TEXT DEFAULT 'plain'");
      
      // Create drawings table for storing drawing stroke data
      await db.execute('''
        CREATE TABLE IF NOT EXISTS drawings (
          id TEXT PRIMARY KEY,
          note_id INTEGER NOT NULL,
          drawing_data TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
        )
      ''');
      
      // Create index for drawing lookups
      await db.execute('CREATE INDEX idx_drawings_note_id ON drawings(note_id)');
    }

    // Version 2 -> 3: Add file organization system
    if (oldVersion < 3) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const textNullableType = 'TEXT';
      const integerType = 'INTEGER NOT NULL';

      // Create file metadata table
      await db.execute('''
        CREATE TABLE file_metadata (
          id $idType,
          file_path $textType UNIQUE,
          file_name $textType,
          file_type $integerType,
          subject $textNullableType,
          created_at $integerType,
          last_modified $integerType,
          file_size $integerType,
          related_note_id $textNullableType,
          organization_status $integerType DEFAULT 0,
          custom_folder $textNullableType,
          tags $textNullableType
        )
      ''');

      // Create organization rules table
      await db.execute('''
        CREATE TABLE organization_rules (
          id $textType PRIMARY KEY,
          name $textType,
          subject_pattern $textNullableType,
          file_type $integerType,
          target_folder $textType,
          priority $integerType DEFAULT 0,
          is_enabled $integerType DEFAULT 1
        )
      ''');

      // Create indexes for file organization queries
      await db.execute('CREATE INDEX idx_file_metadata_subject ON file_metadata(subject)');
      await db.execute('CREATE INDEX idx_file_metadata_type ON file_metadata(file_type)');
      await db.execute('CREATE INDEX idx_file_metadata_status ON file_metadata(organization_status)');
      await db.execute('CREATE INDEX idx_file_metadata_created ON file_metadata(created_at DESC)');
      await db.execute('CREATE INDEX idx_organization_rules_priority ON organization_rules(priority DESC)');
    }
<<<<<<< Updated upstream
=======

    // Version 3 -> 4: Add AI chat system
    if (oldVersion < 4) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const textNullableType = 'TEXT';
      const integerType = 'INTEGER NOT NULL';

      // Document chunks for AI retrieval
      await db.execute('''
        CREATE TABLE document_chunks (
          id $idType,
          file_metadata_id $integerType NOT NULL,
          chunk_index $integerType NOT NULL,
          content $textType,
          token_count $integerType,
          created_at $integerType NOT NULL,
          FOREIGN KEY (file_metadata_id) REFERENCES file_metadata(id) ON DELETE CASCADE
        )
      ''');

      await _createDocumentChunksFts(db);

      // Chat sessions
      await db.execute('''
        CREATE TABLE chat_sessions (
          id $idType,
          title $textType,
          created_at $integerType NOT NULL,
          updated_at $integerType NOT NULL,
          tags $textNullableType
        )
      ''');

      // Chat messages
      await db.execute('''
        CREATE TABLE chat_messages (
          id $idType,
          session_id $integerType NOT NULL,
          role $textType NOT NULL CHECK(role IN ('user', 'assistant')),
          content $textType,
          timestamp $integerType NOT NULL,
          status $textType NOT NULL CHECK(status IN ('sending', 'sent', 'error')),
          FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
        )
      ''');

      // Message sources (citations)
      await db.execute('''
        CREATE TABLE message_sources (
          id $idType,
          message_id $integerType NOT NULL,
          file_metadata_id $integerType NOT NULL,
          chunk_id $integerType NOT NULL,
          relevance_score REAL NOT NULL,
          FOREIGN KEY (message_id) REFERENCES chat_messages(id) ON DELETE CASCADE,
          FOREIGN KEY (file_metadata_id) REFERENCES file_metadata(id) ON DELETE CASCADE,
          FOREIGN KEY (chunk_id) REFERENCES document_chunks(id) ON DELETE CASCADE
        )
      ''');

      // Create indexes for AI chat
      await db.execute('CREATE INDEX idx_chunks_file ON document_chunks(file_metadata_id)');
      await db.execute('CREATE INDEX idx_messages_session ON chat_messages(session_id)');
      await db.execute('CREATE INDEX idx_messages_timestamp ON chat_messages(timestamp DESC)');
      await db.execute('CREATE INDEX idx_sources_message ON message_sources(message_id)');
    }
>>>>>>> Stashed changes
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
