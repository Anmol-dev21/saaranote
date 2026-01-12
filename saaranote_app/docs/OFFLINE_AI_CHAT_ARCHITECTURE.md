# Offline AI Chat System Architecture - SaaraNote

## Executive Summary

A fully offline, lightweight AI chat system that answers questions exclusively from user's study materials using RAG (Retrieval-Augmented Generation) with hybrid retrieval (keyword + embedding). Designed to prevent hallucination by grounding all responses in actual user data.

---

## System Overview

### Core Principles
1. **Data-Grounded Responses**: All answers derived from user's notes, PDFs, and study materials
2. **Hybrid Retrieval**: Combine keyword-based (BM25) and semantic (embeddings) search
3. **Lightweight**: Use small, quantized models suitable for mobile/desktop
4. **Offline-First**: No network dependency, all processing on-device
5. **No Hallucination**: Strict citation-based responses with source attribution

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface Layer                     │
│              (Chat Screen - Not in this doc)                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  Chat Orchestrator                           │
│  • Query understanding                                       │
│  • Context building                                          │
│  • Response generation coordination                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼────────┐           ┌────────▼─────────┐
│   Retrieval    │           │   Generation     │
│    Pipeline    │           │    Pipeline      │
│                │           │                  │
│ • BM25 Search  │           │ • Template-based │
│ • Embedding    │           │ • Extractive QA  │
│ • Reranking    │           │ • Summarization  │
└───────┬────────┘           └────────┬─────────┘
        │                             │
┌───────▼──────────────────────────────▼─────────┐
│           Knowledge Base Layer                  │
│                                                 │
│ • Indexed Notes (SQLite FTS5)                   │
│ • Document Chunks (Embeddings)                  │
│ • Metadata (File organization DB)               │
└─────────────────────────────────────────────────┘
```

---

## Detailed Architecture

### 1. Data Ingestion & Indexing Pipeline

#### 1.1 Document Processing Flow

```
User Content (Notes, PDFs, Images with OCR)
           ↓
   Content Extraction
           ↓
   ┌──────┴──────┐
   │             │
Text Extraction  Metadata Extraction
   │             │
   ↓             ↓
Chunking      Store in file_metadata
   │         (existing table)
   ↓
┌──┴───┐
│      │
BM25   Embedding
Index  Generation
│      │
↓      ↓
SQLite Vector Store
FTS5   (SQLite-VSS or binary blobs)
```

#### 1.2 Chunking Strategy

**Text Chunking Parameters:**
- Chunk size: 300-500 tokens (~200-350 words)
- Overlap: 50-100 tokens
- Preserve sentence boundaries
- Keep metadata (source file, page, timestamp)

**Chunk Storage Schema:**
```sql
CREATE TABLE document_chunks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_metadata_id INTEGER NOT NULL,
  chunk_index INTEGER NOT NULL,
  content TEXT NOT NULL,
  embedding BLOB,  -- Quantized embedding vector
  token_count INTEGER,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (file_metadata_id) REFERENCES file_metadata(id) ON DELETE CASCADE
);

CREATE INDEX idx_chunks_file ON document_chunks(file_metadata_id);
CREATE INDEX idx_chunks_index ON document_chunks(chunk_index);
```

#### 1.3 Full-Text Search Index (BM25)

```sql
-- SQLite FTS5 for keyword search
CREATE VIRTUAL TABLE document_chunks_fts USING fts5(
  content,
  content='document_chunks',
  content_rowid='id',
  tokenize='porter unicode61'
);

-- Triggers to keep FTS5 in sync
CREATE TRIGGER chunks_fts_insert AFTER INSERT ON document_chunks BEGIN
  INSERT INTO document_chunks_fts(rowid, content) VALUES (new.id, new.content);
END;

CREATE TRIGGER chunks_fts_delete AFTER DELETE ON document_chunks BEGIN
  DELETE FROM document_chunks_fts WHERE rowid = old.id;
END;

CREATE TRIGGER chunks_fts_update AFTER UPDATE ON document_chunks BEGIN
  UPDATE document_chunks_fts SET content = new.content WHERE rowid = new.id;
END;
```

#### 1.4 Embedding Generation (Offline)

**Recommended Models:**
- **TinyBERT** (14MB, ~80% accuracy of BERT)
- **MiniLM-L6-v2** (22MB, 384 dimensions)
- **All-MiniLM-L12-v2** (45MB, 384 dimensions) - Best quality/size tradeoff

**Flutter Integration Options:**
1. **TensorFlow Lite** - Best cross-platform support
2. **ONNX Runtime** - Better performance, more setup
3. **Pre-computed embeddings** - Generate during content import

**Embedding Storage:**
```dart
// Store as quantized binary blob (8-bit quantization)
// 384 dimensions * 1 byte = 384 bytes per chunk
// vs 384 dimensions * 4 bytes (float32) = 1536 bytes
// Saves 75% storage with minimal accuracy loss
```

---

### 2. Retrieval Pipeline (Hybrid Approach)

#### 2.1 Retrieval Flow

```
User Query
    ↓
Query Processing
    ↓
┌───┴────────────┐
│                │
Keyword Search   Semantic Search
(BM25/FTS5)     (Embedding similarity)
│                │
↓                ↓
Top 50 chunks    Top 30 chunks
│                │
└───┬────────────┘
    ↓
Merge & Deduplicate
    ↓
Reciprocal Rank Fusion (RRF)
    ↓
Top 10 chunks
    ↓
Reranking (Optional)
    ↓
Top 5 chunks for context
```

#### 2.2 Query Processing

```dart
class QueryProcessor {
  // 1. Normalize query
  String normalizeQuery(String query) {
    // Lowercase, remove special chars, stem words
  }
  
  // 2. Extract query intent
  QueryIntent classifyIntent(String query) {
    // Question answering: "What is...?", "How does...?"
    // Summarization: "Summarize...", "Give overview..."
    // Extraction: "List...", "Find all..."
    // Comparison: "Compare...", "Difference between..."
  }
  
  // 3. Expand query (synonyms, related terms)
  List<String> expandQuery(String query) {
    // Simple rule-based or use offline thesaurus
  }
}
```

#### 2.3 Keyword Search (BM25)

```dart
class KeywordRetriever {
  Future<List<Chunk>> search(String query, int limit) async {
    // Use SQLite FTS5 with BM25 ranking
    final sql = '''
      SELECT 
        dc.id,
        dc.content,
        dc.file_metadata_id,
        bm25(document_chunks_fts) as score
      FROM document_chunks_fts
      JOIN document_chunks dc ON document_chunks_fts.rowid = dc.id
      WHERE document_chunks_fts MATCH ?
      ORDER BY score
      LIMIT ?
    ''';
    
    return await db.rawQuery(sql, [query, limit]);
  }
}
```

#### 2.4 Semantic Search (Embedding-based)

```dart
class SemanticRetriever {
  Future<List<Chunk>> search(String query, int limit) async {
    // 1. Generate query embedding
    final queryEmbedding = await embeddingModel.encode(query);
    
    // 2. Retrieve all candidate chunks (or use approximate search)
    final chunks = await db.query('document_chunks');
    
    // 3. Calculate cosine similarity
    final rankedChunks = chunks.map((chunk) {
      final chunkEmbedding = deserializeEmbedding(chunk['embedding']);
      final similarity = cosineSimilarity(queryEmbedding, chunkEmbedding);
      return (chunk: chunk, score: similarity);
    }).toList();
    
    // 4. Sort by similarity
    rankedChunks.sort((a, b) => b.score.compareTo(a.score));
    
    return rankedChunks.take(limit).map((e) => e.chunk).toList();
  }
  
  // For large datasets, use approximate nearest neighbor (ANN)
  // Options: FAISS-CPU (via FFI), SQLite-VSS, or custom KD-tree
}
```

#### 2.5 Fusion & Reranking

```dart
class HybridRetriever {
  Future<List<Chunk>> retrieve(String query, int limit) async {
    // 1. Get results from both retrievers
    final keywordResults = await keywordRetriever.search(query, 50);
    final semanticResults = await semanticRetriever.search(query, 30);
    
    // 2. Reciprocal Rank Fusion (RRF)
    // score(chunk) = sum(1 / (k + rank)) for each retriever
    final k = 60; // RRF constant
    final scores = <int, double>{};
    
    for (int i = 0; i < keywordResults.length; i++) {
      final chunkId = keywordResults[i].id;
      scores[chunkId] = (scores[chunkId] ?? 0) + 1 / (k + i + 1);
    }
    
    for (int i = 0; i < semanticResults.length; i++) {
      final chunkId = semanticResults[i].id;
      scores[chunkId] = (scores[chunkId] ?? 0) + 1 / (k + i + 1);
    }
    
    // 3. Sort by fused score
    final rankedChunks = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // 4. Retrieve full chunk data for top results
    final topChunks = await getChunksByIds(
      rankedChunks.take(limit).map((e) => e.key).toList()
    );
    
    return topChunks;
  }
}
```

---

### 3. Generation Pipeline (Non-Hallucination)

#### 3.1 Generation Strategies

**NO Large Language Models** - Instead use:

1. **Extractive QA** - Extract exact answer spans from retrieved chunks
2. **Template-based Generation** - Fill templates with extracted information
3. **Rule-based Summarization** - Use TextRank or LexRank algorithms
4. **Citation-based Responses** - Always include source references

#### 3.2 Extractive Question Answering

```dart
class ExtractivQA {
  String answerQuestion(String question, List<Chunk> context) {
    // 1. Find most relevant sentences in context
    final sentences = context
      .expand((chunk) => sentenceSplitter.split(chunk.content))
      .toList();
    
    // 2. Score sentences by relevance to question
    final scored = sentences.map((sentence) {
      final score = calculateRelevance(question, sentence);
      return (sentence: sentence, score: score);
    }).toList();
    
    // 3. Select top sentences
    scored.sort((a, b) => b.score.compareTo(a.score));
    final topSentences = scored.take(3).map((e) => e.sentence).toList();
    
    // 4. Format response with citations
    return formatResponseWithCitations(topSentences, context);
  }
  
  double calculateRelevance(String question, String sentence) {
    // Simple heuristics:
    // - Token overlap between question and sentence
    // - Question keywords present in sentence
    // - Named entity overlap
    // - Position in chunk (early sentences often more relevant)
    
    final questionTokens = tokenize(question);
    final sentenceTokens = tokenize(sentence);
    
    final overlap = questionTokens
      .where((token) => sentenceTokens.contains(token))
      .length;
    
    return overlap / questionTokens.length;
  }
}
```

#### 3.3 Template-based Generation

```dart
class TemplateGenerator {
  String generate(QueryIntent intent, List<Chunk> context) {
    switch (intent) {
      case QueryIntent.definition:
        return _generateDefinition(context);
      case QueryIntent.list:
        return _generateList(context);
      case QueryIntent.comparison:
        return _generateComparison(context);
      case QueryIntent.summary:
        return _generateSummary(context);
    }
  }
  
  String _generateDefinition(List<Chunk> context) {
    // Find sentences with "is", "are", "means", "refers to"
    final definitions = context
      .expand((c) => extractDefinitions(c.content))
      .toList();
    
    if (definitions.isEmpty) {
      return "No definition found in your notes.";
    }
    
    return '''
Based on your notes:

${definitions.first}

Source: ${getSourceInfo(context.first)}
''';
  }
  
  String _generateList(List<Chunk> context) {
    // Extract bullet points, numbered lists, or enumerated items
    final items = context
      .expand((c) => extractListItems(c.content))
      .toSet() // Deduplicate
      .toList();
    
    if (items.isEmpty) {
      return "No list items found in your notes.";
    }
    
    final formatted = items.map((item) => '• $item').join('\n');
    
    return '''
From your notes:

$formatted

Sources: ${formatSources(context)}
''';
  }
}
```

#### 3.4 Summarization (Extractive)

```dart
class ExtractiveSummarizer {
  String summarize(List<Chunk> chunks, int maxSentences) {
    // Use TextRank algorithm (graph-based ranking)
    
    // 1. Extract all sentences
    final sentences = chunks
      .expand((c) => sentenceSplitter.split(c.content))
      .toList();
    
    // 2. Build similarity graph
    final graph = _buildSimilarityGraph(sentences);
    
    // 3. Apply PageRank-style scoring
    final scores = _textRank(graph);
    
    // 4. Select top sentences
    final topSentences = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final selected = topSentences
      .take(maxSentences)
      .map((e) => sentences[e.key])
      .toList();
    
    // 5. Reorder by original position for coherence
    selected.sort((a, b) => 
      sentences.indexOf(a).compareTo(sentences.indexOf(b))
    );
    
    return selected.join(' ');
  }
  
  Map<int, List<double>> _buildSimilarityGraph(List<String> sentences) {
    // Calculate cosine similarity between all sentence pairs
    // Can use TF-IDF vectors or simple token overlap
  }
  
  Map<int, double> _textRank(Map<int, List<double>> graph) {
    // Iterative PageRank algorithm
    // Converge when scores stabilize
  }
}
```

#### 3.5 Response Formatting with Citations

```dart
class ResponseFormatter {
  String format(String answer, List<Chunk> sources) {
    final citations = sources.map((chunk, index) {
      return Citation(
        number: index + 1,
        fileName: chunk.fileMetadata.fileName,
        subject: chunk.fileMetadata.subject,
        chunkIndex: chunk.chunkIndex,
      );
    }).toList();
    
    // Add inline citations
    String citedAnswer = answer;
    for (final citation in citations) {
      citedAnswer += ' [${citation.number}]';
    }
    
    // Add source list
    final sourceList = citations.map((c) => 
      '[${c.number}] ${c.fileName} (${c.subject})'
    ).join('\n');
    
    return '''
$citedAnswer

---
Sources:
$sourceList

Tap to view source content.
''';
  }
}
```

---

### 4. Domain Layer Architecture

#### 4.1 Entities

```dart
// lib/domain/entities/chat_message.dart
class ChatMessage {
  final int? id;
  final String content;
  final MessageRole role; // user, assistant
  final DateTime timestamp;
  final List<CitedSource>? sources;
  final MessageStatus status; // sending, sent, error
  
  const ChatMessage({...});
}

enum MessageRole { user, assistant }
enum MessageStatus { sending, sent, error }

class CitedSource {
  final int fileMetadataId;
  final String fileName;
  final int chunkId;
  final String excerpt;
  final double relevanceScore;
  
  const CitedSource({...});
}

// lib/domain/entities/chat_session.dart
class ChatSession {
  final int? id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? tags;
  
  const ChatSession({...});
}

// lib/domain/entities/document_chunk.dart
class DocumentChunk {
  final int? id;
  final int fileMetadataId;
  final int chunkIndex;
  final String content;
  final List<double>? embedding; // Optional, loaded on demand
  final int tokenCount;
  final DateTime createdAt;
  
  const DocumentChunk({...});
}

// lib/domain/entities/retrieval_result.dart
class RetrievalResult {
  final DocumentChunk chunk;
  final double score;
  final RetrievalMethod method; // keyword, semantic, hybrid
  
  const RetrievalResult({...});
}

enum RetrievalMethod { keyword, semantic, hybrid }
```

#### 4.2 Use Cases

```dart
// lib/domain/usecases/ask_question_usecase.dart
class AskQuestionUseCase {
  final ChatRepository chatRepository;
  final RetrievalService retrievalService;
  final GenerationService generationService;
  
  Future<ChatMessage> execute(AskQuestionParams params) async {
    // 1. Save user message
    final userMessage = await chatRepository.addMessage(
      ChatMessage(
        content: params.question,
        role: MessageRole.user,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      ),
      params.sessionId,
    );
    
    // 2. Retrieve relevant context
    final retrievalResults = await retrievalService.retrieve(
      query: params.question,
      limit: 5,
    );
    
    if (retrievalResults.isEmpty) {
      return _noResultsResponse(params.sessionId);
    }
    
    // 3. Generate response
    final response = await generationService.generate(
      query: params.question,
      context: retrievalResults,
      intent: params.intent ?? QueryIntent.questionAnswering,
    );
    
    // 4. Save assistant message
    final assistantMessage = await chatRepository.addMessage(
      ChatMessage(
        content: response.content,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        sources: response.sources,
      ),
      params.sessionId,
    );
    
    return assistantMessage;
  }
}

// lib/domain/usecases/index_document_usecase.dart
class IndexDocumentUseCase {
  final ChunkingService chunkingService;
  final EmbeddingService embeddingService;
  final IndexRepository indexRepository;
  
  Future<void> execute(IndexDocumentParams params) async {
    // 1. Extract text from file
    final text = await params.fileMetadata.extractText();
    
    // 2. Chunk text
    final chunks = await chunkingService.chunkText(
      text: text,
      chunkSize: 400,
      overlap: 50,
    );
    
    // 3. Generate embeddings
    final embeddings = await embeddingService.batchEncode(
      chunks.map((c) => c.content).toList(),
    );
    
    // 4. Store chunks with embeddings
    for (int i = 0; i < chunks.length; i++) {
      final chunk = DocumentChunk(
        fileMetadataId: params.fileMetadata.id!,
        chunkIndex: i,
        content: chunks[i].content,
        embedding: embeddings[i],
        tokenCount: chunks[i].tokenCount,
        createdAt: DateTime.now(),
      );
      
      await indexRepository.addChunk(chunk);
    }
  }
}

// lib/domain/usecases/search_notes_usecase.dart
class SearchNotesUseCase {
  final RetrievalService retrievalService;
  
  Future<List<RetrievalResult>> execute(String query) async {
    return await retrievalService.retrieve(
      query: query,
      limit: 20,
    );
  }
}
```

#### 4.3 Repository Interfaces

```dart
// lib/domain/repositories/chat_repository.dart
abstract class ChatRepository {
  Future<ChatSession> createSession(String title);
  Future<List<ChatSession>> getAllSessions();
  Future<ChatSession?> getSession(int id);
  Future<void> deleteSession(int id);
  
  Future<ChatMessage> addMessage(ChatMessage message, int sessionId);
  Future<List<ChatMessage>> getMessages(int sessionId);
  Future<void> deleteMessage(int id);
}

// lib/domain/repositories/index_repository.dart
abstract class IndexRepository {
  Future<void> addChunk(DocumentChunk chunk);
  Future<void> deleteChunksByFileId(int fileMetadataId);
  Future<DocumentChunk?> getChunk(int id);
  Future<List<DocumentChunk>> getChunksByFileId(int fileMetadataId);
  Future<List<DocumentChunk>> getAllChunks();
  
  // FTS5 search
  Future<List<RetrievalResult>> keywordSearch(String query, int limit);
  
  // Embedding search
  Future<List<RetrievalResult>> semanticSearch(
    List<double> queryEmbedding,
    int limit,
  );
}
```

---

### 5. Service Layer Architecture

#### 5.1 Core Services

```dart
// lib/core/services/retrieval_service.dart
class RetrievalService {
  final IndexRepository indexRepository;
  final EmbeddingService embeddingService;
  
  Future<List<RetrievalResult>> retrieve({
    required String query,
    required int limit,
    RetrievalStrategy strategy = RetrievalStrategy.hybrid,
  }) async {
    switch (strategy) {
      case RetrievalStrategy.keyword:
        return await _keywordRetrieval(query, limit);
      case RetrievalStrategy.semantic:
        return await _semanticRetrieval(query, limit);
      case RetrievalStrategy.hybrid:
        return await _hybridRetrieval(query, limit);
    }
  }
  
  Future<List<RetrievalResult>> _hybridRetrieval(
    String query,
    int limit,
  ) async {
    // 1. Keyword search
    final keywordResults = await indexRepository.keywordSearch(
      query,
      limit * 5,
    );
    
    // 2. Semantic search
    final queryEmbedding = await embeddingService.encode(query);
    final semanticResults = await indexRepository.semanticSearch(
      queryEmbedding,
      limit * 3,
    );
    
    // 3. Reciprocal Rank Fusion
    final fused = _reciprocalRankFusion(
      keywordResults,
      semanticResults,
      k: 60,
    );
    
    return fused.take(limit).toList();
  }
  
  List<RetrievalResult> _reciprocalRankFusion(
    List<RetrievalResult> list1,
    List<RetrievalResult> list2,
    int k,
  ) {
    final scores = <int, double>{};
    
    for (int i = 0; i < list1.length; i++) {
      final chunkId = list1[i].chunk.id!;
      scores[chunkId] = (scores[chunkId] ?? 0) + 1 / (k + i + 1);
    }
    
    for (int i = 0; i < list2.length; i++) {
      final chunkId = list2[i].chunk.id!;
      scores[chunkId] = (scores[chunkId] ?? 0) + 1 / (k + i + 1);
    }
    
    final rankedIds = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Reconstruct results in fused order
    final allResults = [...list1, ...list2];
    return rankedIds.map((entry) {
      final result = allResults.firstWhere(
        (r) => r.chunk.id == entry.key,
      );
      return result.copyWith(score: entry.value);
    }).toList();
  }
}

// lib/core/services/generation_service.dart
class GenerationService {
  final ExtractivQAEngine qaEngine;
  final SummarizationEngine summaryEngine;
  final TemplateGenerator templateGenerator;
  
  Future<GeneratedResponse> generate({
    required String query,
    required List<RetrievalResult> context,
    required QueryIntent intent,
  }) async {
    if (context.isEmpty) {
      return GeneratedResponse(
        content: "I couldn't find any relevant information in your notes.",
        sources: [],
        confidence: 0.0,
      );
    }
    
    String content;
    switch (intent) {
      case QueryIntent.questionAnswering:
        content = await qaEngine.answer(query, context);
        break;
      case QueryIntent.summarization:
        content = await summaryEngine.summarize(context, maxSentences: 5);
        break;
      case QueryIntent.listExtraction:
        content = templateGenerator.generateList(context);
        break;
      case QueryIntent.definition:
        content = templateGenerator.generateDefinition(context);
        break;
    }
    
    final sources = context.map((r) => CitedSource(
      fileMetadataId: r.chunk.fileMetadataId,
      fileName: r.chunk.fileMetadata.fileName,
      chunkId: r.chunk.id!,
      excerpt: r.chunk.content.substring(0, 150),
      relevanceScore: r.score,
    )).toList();
    
    return GeneratedResponse(
      content: content,
      sources: sources,
      confidence: _calculateConfidence(context),
    );
  }
  
  double _calculateConfidence(List<RetrievalResult> context) {
    // Confidence based on top result score and score distribution
    if (context.isEmpty) return 0.0;
    
    final topScore = context.first.score;
    final avgScore = context.map((r) => r.score).reduce((a, b) => a + b) / 
                     context.length;
    
    // High confidence if top score is significantly higher than average
    final confidence = topScore / (avgScore + 0.1);
    return confidence.clamp(0.0, 1.0);
  }
}

// lib/core/services/embedding_service.dart
class EmbeddingService {
  late TensorFlowLiteModel _model;
  late Tokenizer _tokenizer;
  
  Future<void> initialize() async {
    // Load TFLite model (e.g., MiniLM-L6-v2.tflite)
    _model = await TensorFlowLiteModel.load('assets/models/minilm.tflite');
    _tokenizer = await Tokenizer.load('assets/models/tokenizer.json');
  }
  
  Future<List<double>> encode(String text) async {
    // 1. Tokenize
    final tokens = _tokenizer.encode(text, maxLength: 128);
    
    // 2. Run inference
    final output = await _model.run(tokens);
    
    // 3. Mean pooling
    final embedding = _meanPooling(output);
    
    // 4. Normalize
    return _normalize(embedding);
  }
  
  Future<List<List<double>>> batchEncode(List<String> texts) async {
    // Process in batches for efficiency
    final embeddings = <List<double>>[];
    
    for (int i = 0; i < texts.length; i += 32) {
      final batch = texts.skip(i).take(32).toList();
      final batchEmbeddings = await Future.wait(
        batch.map((text) => encode(text)),
      );
      embeddings.addAll(batchEmbeddings);
    }
    
    return embeddings;
  }
}

// lib/core/services/chunking_service.dart
class ChunkingService {
  Future<List<TextChunk>> chunkText({
    required String text,
    required int chunkSize,
    required int overlap,
  }) async {
    final sentences = _splitIntoSentences(text);
    final chunks = <TextChunk>[];
    
    int currentPosition = 0;
    List<String> currentChunk = [];
    int currentTokens = 0;
    
    for (final sentence in sentences) {
      final tokens = _tokenize(sentence).length;
      
      if (currentTokens + tokens > chunkSize && currentChunk.isNotEmpty) {
        // Save current chunk
        chunks.add(TextChunk(
          content: currentChunk.join(' '),
          tokenCount: currentTokens,
          startPosition: currentPosition,
        ));
        
        // Start new chunk with overlap
        final overlapSentences = _getOverlapSentences(
          currentChunk,
          overlap,
        );
        currentChunk = overlapSentences;
        currentTokens = overlapSentences
          .map((s) => _tokenize(s).length)
          .fold(0, (a, b) => a + b);
      }
      
      currentChunk.add(sentence);
      currentTokens += tokens;
      currentPosition++;
    }
    
    // Add final chunk
    if (currentChunk.isNotEmpty) {
      chunks.add(TextChunk(
        content: currentChunk.join(' '),
        tokenCount: currentTokens,
        startPosition: currentPosition,
      ));
    }
    
    return chunks;
  }
}
```

---

### 6. Data Layer Architecture

#### 6.1 Database Schema Extensions

```sql
-- Chat sessions
CREATE TABLE chat_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  tags TEXT  -- JSON array
);

-- Chat messages
CREATE TABLE chat_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('sending', 'sent', 'error')),
  FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
);

-- Message sources (citations)
CREATE TABLE message_sources (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message_id INTEGER NOT NULL,
  file_metadata_id INTEGER NOT NULL,
  chunk_id INTEGER NOT NULL,
  relevance_score REAL NOT NULL,
  FOREIGN KEY (message_id) REFERENCES chat_messages(id) ON DELETE CASCADE,
  FOREIGN KEY (file_metadata_id) REFERENCES file_metadata(id) ON DELETE CASCADE,
  FOREIGN KEY (chunk_id) REFERENCES document_chunks(id) ON DELETE CASCADE
);

-- Document chunks (already defined in section 1.2)
CREATE TABLE document_chunks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_metadata_id INTEGER NOT NULL,
  chunk_index INTEGER NOT NULL,
  content TEXT NOT NULL,
  embedding BLOB,
  token_count INTEGER,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (file_metadata_id) REFERENCES file_metadata(id) ON DELETE CASCADE
);

-- FTS5 index (already defined in section 1.3)
CREATE VIRTUAL TABLE document_chunks_fts USING fts5(
  content,
  content='document_chunks',
  content_rowid='id',
  tokenize='porter unicode61'
);

-- Indexes
CREATE INDEX idx_messages_session ON chat_messages(session_id);
CREATE INDEX idx_messages_timestamp ON chat_messages(timestamp DESC);
CREATE INDEX idx_sources_message ON message_sources(message_id);
CREATE INDEX idx_chunks_file ON document_chunks(file_metadata_id);
```

#### 6.2 Repository Implementations

```dart
// lib/data/repositories/chat_repository_impl.dart
class ChatRepositoryImpl implements ChatRepository {
  final DatabaseHelper _databaseHelper;
  
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
  Future<ChatMessage> addMessage(ChatMessage message, int sessionId) async {
    final db = await _databaseHelper.database;
    
    // Insert message
    final messageId = await db.insert('chat_messages', {
      'session_id': sessionId,
      'role': message.role.name,
      'content': message.content,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'status': message.status.name,
    });
    
    // Insert sources if present
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
    
    // Update session timestamp
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
      
      // Load sources
      final sourcesResults = await db.rawQuery('''
        SELECT 
          ms.*,
          fm.file_name,
          dc.content
        FROM message_sources ms
        JOIN file_metadata fm ON ms.file_metadata_id = fm.id
        JOIN document_chunks dc ON ms.chunk_id = dc.id
        WHERE ms.message_id = ?
      ''', [messageId]);
      
      final sources = sourcesResults.map((s) => CitedSource(
        fileMetadataId: s['file_metadata_id'] as int,
        fileName: s['file_name'] as String,
        chunkId: s['chunk_id'] as int,
        excerpt: (s['content'] as String).substring(0, 150),
        relevanceScore: s['relevance_score'] as double,
      )).toList();
      
      messages.add(ChatMessage(
        id: messageId,
        content: row['content'] as String,
        role: MessageRole.values.byName(row['role'] as String),
        timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
        status: MessageStatus.values.byName(row['status'] as String),
        sources: sources.isEmpty ? null : sources,
      ));
    }
    
    return messages;
  }
}

// lib/data/repositories/index_repository_impl.dart
class IndexRepositoryImpl implements IndexRepository {
  final DatabaseHelper _databaseHelper;
  
  @override
  Future<void> addChunk(DocumentChunk chunk) async {
    final db = await _databaseHelper.database;
    
    await db.insert('document_chunks', {
      'file_metadata_id': chunk.fileMetadataId,
      'chunk_index': chunk.chunkIndex,
      'content': chunk.content,
      'embedding': chunk.embedding != null 
        ? _quantizeEmbedding(chunk.embedding!)
        : null,
      'token_count': chunk.tokenCount,
      'created_at': chunk.createdAt.millisecondsSinceEpoch,
    });
  }
  
  @override
  Future<List<RetrievalResult>> keywordSearch(String query, int limit) async {
    final db = await _databaseHelper.database;
    
    final results = await db.rawQuery('''
      SELECT 
        dc.id,
        dc.file_metadata_id,
        dc.chunk_index,
        dc.content,
        dc.token_count,
        dc.created_at,
        bm25(document_chunks_fts) as score
      FROM document_chunks_fts
      JOIN document_chunks dc ON document_chunks_fts.rowid = dc.id
      WHERE document_chunks_fts MATCH ?
      ORDER BY score DESC
      LIMIT ?
    ''', [query, limit]);
    
    return results.map((row) => RetrievalResult(
      chunk: DocumentChunk(
        id: row['id'] as int,
        fileMetadataId: row['file_metadata_id'] as int,
        chunkIndex: row['chunk_index'] as int,
        content: row['content'] as String,
        tokenCount: row['token_count'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
      ),
      score: (row['score'] as num).toDouble().abs(),
      method: RetrievalMethod.keyword,
    )).toList();
  }
  
  @override
  Future<List<RetrievalResult>> semanticSearch(
    List<double> queryEmbedding,
    int limit,
  ) async {
    final db = await _databaseHelper.database;
    
    // Load all chunks with embeddings
    final results = await db.query('document_chunks');
    
    // Calculate cosine similarity
    final scored = results.map((row) {
      final embeddingBytes = row['embedding'] as Uint8List?;
      if (embeddingBytes == null) {
        return null;
      }
      
      final embedding = _dequantizeEmbedding(embeddingBytes);
      final similarity = _cosineSimilarity(queryEmbedding, embedding);
      
      return (row: row, score: similarity);
    }).whereType<({Map<String, Object?> row, double score})>().toList();
    
    // Sort by similarity
    scored.sort((a, b) => b.score.compareTo(a.score));
    
    // Return top results
    return scored.take(limit).map((item) {
      final row = item.row;
      return RetrievalResult(
        chunk: DocumentChunk(
          id: row['id'] as int,
          fileMetadataId: row['file_metadata_id'] as int,
          chunkIndex: row['chunk_index'] as int,
          content: row['content'] as String,
          tokenCount: row['token_count'] as int,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at'] as int,
          ),
        ),
        score: item.score,
        method: RetrievalMethod.semantic,
      );
    }).toList();
  }
  
  // Quantize float32 to int8 for storage efficiency
  Uint8List _quantizeEmbedding(List<double> embedding) {
    final bytes = Uint8List(embedding.length);
    for (int i = 0; i < embedding.length; i++) {
      // Scale from [-1, 1] to [0, 255]
      bytes[i] = ((embedding[i] + 1.0) * 127.5).round().clamp(0, 255);
    }
    return bytes;
  }
  
  List<double> _dequantizeEmbedding(Uint8List bytes) {
    final embedding = List<double>.filled(bytes.length, 0);
    for (int i = 0; i < bytes.length; i++) {
      // Scale from [0, 255] to [-1, 1]
      embedding[i] = (bytes[i] / 127.5) - 1.0;
    }
    return embedding;
  }
  
  double _cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
```

---

### 7. Performance Optimizations

#### 7.1 Indexing Optimizations

**Batch Processing:**
- Index multiple documents in parallel
- Use transactions for bulk inserts
- Generate embeddings in batches (32-64 at a time)

**Lazy Loading:**
- Load embeddings only when needed for semantic search
- Cache frequently accessed chunks
- Paginate large result sets

**Storage Optimization:**
- Use int8 quantization for embeddings (75% size reduction)
- Compress chunk content (GZIP for chunks > 500 chars)
- Prune old/unused indexes periodically

#### 7.2 Retrieval Optimizations

**Approximate Nearest Neighbor (ANN):**
For large datasets (>10K chunks), consider:
- **Hierarchical Navigable Small World (HNSW)** - Via SQLite-VSS extension
- **Product Quantization** - Reduce embedding dimensions
- **Inverted File Index (IVF)** - Partition search space

**Caching Strategy:**
```dart
class CachedRetrievalService extends RetrievalService {
  final LRUCache<String, List<RetrievalResult>> _cache;
  
  @override
  Future<List<RetrievalResult>> retrieve({...}) async {
    final cacheKey = _generateCacheKey(query, limit, strategy);
    
    if (_cache.containsKey(cacheKey)) {
      return _cache.get(cacheKey)!;
    }
    
    final results = await super.retrieve(...);
    _cache.put(cacheKey, results);
    
    return results;
  }
}
```

#### 7.3 Generation Optimizations

**Pre-computed Summaries:**
- Generate and cache summaries for frequently accessed notes
- Update summaries when content changes

**Template Caching:**
- Cache compiled templates
- Reuse formatted responses for similar queries

---

### 8. Integration with Existing Architecture

#### 8.1 File Organization System Integration

```dart
// Automatically index files when organized
class EnhancedOrganizeFileUseCase extends OrganizeFileUseCase {
  final IndexDocumentUseCase indexDocumentUseCase;
  
  @override
  Future<FileMetadata> execute(OrganizeFileParams params) async {
    // 1. Organize file (existing logic)
    final organizedFile = await super.execute(params);
    
    // 2. Index for chat system (new logic)
    if (_shouldIndex(organizedFile)) {
      await indexDocumentUseCase.execute(
        IndexDocumentParams(fileMetadata: organizedFile),
      );
    }
    
    return organizedFile;
  }
  
  bool _shouldIndex(FileMetadata file) {
    // Index text-heavy files
    return file.fileType == FileType.pdf || 
           file.fileType == FileType.note;
  }
}
```

#### 8.2 Rich Text Notes Integration

```dart
// Index rich text notes for better search
class NoteIndexingService {
  Future<void> indexNote(Note note) async {
    String textContent;
    
    if (note.contentType == ContentType.richText) {
      // Extract plain text from rich content
      textContent = _extractTextFromRichContent(note.richContent!);
    } else {
      textContent = note.content;
    }
    
    // Create temporary FileMetadata for note
    final noteMetadata = FileMetadata(
      filePath: 'note://${note.id}',
      fileName: note.title,
      fileType: FileType.note,
      subject: _detectSubject(note.title, textContent),
      createdAt: note.createdAt,
      fileSize: textContent.length,
    );
    
    // Index note
    await indexDocumentUseCase.execute(
      IndexDocumentParams(
        fileMetadata: noteMetadata,
        textContent: textContent,
      ),
    );
  }
}
```

---

### 9. Anti-Hallucination Mechanisms

#### 9.1 Strict Grounding

**Never generate without context:**
```dart
class GroundedGenerationService extends GenerationService {
  @override
  Future<GeneratedResponse> generate({...}) async {
    // CRITICAL: No context = No response
    if (context.isEmpty) {
      return GeneratedResponse(
        content: "I couldn't find relevant information in your notes. "
                 "Try rephrasing your question or adding more study materials.",
        sources: [],
        confidence: 0.0,
      );
    }
    
    // Low confidence threshold = explicit disclaimer
    final response = await super.generate(...);
    
    if (response.confidence < 0.5) {
      response.content = "⚠️ Low confidence answer:\n\n" + 
                         response.content + 
                         "\n\nConsider reviewing the sources for accuracy.";
    }
    
    return response;
  }
}
```

#### 9.2 Source Attribution

**Every statement must cite a source:**
```dart
class CitationEnforcingFormatter {
  String format(String answer, List<Chunk> sources) {
    // Split answer into sentences
    final sentences = sentenceSplitter.split(answer);
    
    // Assign citation to each sentence
    final citedSentences = sentences.map((sentence, index) {
      final sourceIndex = (index % sources.length) + 1;
      return '$sentence [$sourceIndex]';
    }).toList();
    
    final citedAnswer = citedSentences.join(' ');
    
    // Add source list with clickable links
    final sourceList = sources.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final source = entry.value;
      return '[$index] ${source.fileMetadata.fileName} - '
             '${source.fileMetadata.subject}\n'
             'Preview: "${source.content.substring(0, 100)}..."';
    }).join('\n\n');
    
    return '''
$citedAnswer

━━━━━━━━━━━━━━━━━━━━━━
📚 Sources

$sourceList

Tap any source to view full context.
''';
  }
}
```

#### 9.3 Confidence Scoring

**Multi-factor confidence calculation:**
```dart
double calculateConfidence({
  required List<RetrievalResult> retrievalResults,
  required String query,
  required String generatedAnswer,
}) {
  // Factor 1: Retrieval score (0-1)
  final retrievalScore = retrievalResults.isEmpty 
    ? 0.0 
    : retrievalResults.first.score;
  
  // Factor 2: Score consistency (0-1)
  final scoreConsistency = retrievalResults.length > 1
    ? 1.0 - (retrievalResults.first.score - retrievalResults.last.score)
    : 0.5;
  
  // Factor 3: Query-answer lexical overlap (0-1)
  final lexicalOverlap = _calculateTokenOverlap(query, generatedAnswer);
  
  // Factor 4: Multiple source agreement (0-1)
  final sourceAgreement = _calculateSourceAgreement(retrievalResults);
  
  // Weighted average
  final confidence = (
    retrievalScore * 0.4 +
    scoreConsistency * 0.2 +
    lexicalOverlap * 0.2 +
    sourceAgreement * 0.2
  );
  
  return confidence.clamp(0.0, 1.0);
}
```

#### 9.4 Explicit Limitations

**Show what the system cannot do:**
```dart
class LimitationAwareResponder {
  String respond(String query, GeneratedResponse response) {
    // Detect out-of-scope queries
    if (_isOutOfScope(query)) {
      return '''
❌ I can only answer questions about your study materials.

Your question appears to be about: ${_detectTopic(query)}

I have study materials about: ${_listAvailableSubjects()}

Please rephrase your question to focus on your notes.
''';
    }
    
    // Detect ambiguous queries
    if (response.confidence < 0.3) {
      return '''
🤔 I found some information, but I'm not confident it answers your question.

Here's what I found:
${response.content}

Try being more specific, or check if you have relevant notes on this topic.
''';
    }
    
    return response.content;
  }
}
```

---

### 10. Deployment & Resource Management

#### 10.1 Model Storage

```
assets/
└── models/
    ├── minilm-l6-v2.tflite      (22 MB) - Embedding model
    ├── tokenizer.json            (500 KB) - Tokenizer vocabulary
    └── stopwords.txt             (10 KB) - Common words to filter
```

**Model Loading Strategy:**
- Lazy load models on first use
- Keep models in memory once loaded (singleton)
- Provide progress indicators during first-time initialization

#### 10.2 Memory Management

```dart
class ResourceManager {
  static const int MAX_CACHE_SIZE = 50 * 1024 * 1024; // 50 MB
  static const int MAX_CHUNKS_IN_MEMORY = 1000;
  
  final LRUCache<String, List<RetrievalResult>> _resultsCache;
  final LRUCache<String, List<double>> _embeddingCache;
  
  void clearCaches() {
    _resultsCache.clear();
    _embeddingCache.clear();
  }
  
  Future<void> pruneIfNeeded() async {
    final memoryUsage = await _getMemoryUsage();
    if (memoryUsage > MAX_CACHE_SIZE) {
      clearCaches();
    }
  }
}
```

#### 10.3 Background Processing

```dart
class BackgroundIndexer {
  Future<void> indexAllPendingDocuments() async {
    // Get unindexed files
    final unindexedFiles = await fileOrganizationRepository
      .getFilesByStatus(OrganizationStatus.organized)
      .where((f) => !f.isIndexed);
    
    // Index in background with progress
    for (final file in unindexedFiles) {
      try {
        await indexDocumentUseCase.execute(
          IndexDocumentParams(fileMetadata: file),
        );
        
        // Update indexing status
        await fileOrganizationRepository.updateFile(
          file.copyWith(isIndexed: true),
        );
      } catch (e) {
        // Log error but continue
        print('Failed to index ${file.fileName}: $e');
      }
    }
  }
}
```

---

### 11. Testing Strategy

#### 11.1 Unit Tests

```dart
// Test retrieval accuracy
test('Hybrid retrieval returns relevant chunks', () async {
  final query = 'What is photosynthesis?';
  final results = await retrievalService.retrieve(query: query, limit: 5);
  
  expect(results, isNotEmpty);
  expect(results.first.chunk.content, contains('photosynthesis'));
  expect(results.first.score, greaterThan(0.5));
});

// Test anti-hallucination
test('Returns no answer when no context found', () async {
  final response = await generationService.generate(
    query: 'What is quantum entanglement?',
    context: [],
    intent: QueryIntent.questionAnswering,
  );
  
  expect(response.content, contains("couldn't find"));
  expect(response.sources, isEmpty);
  expect(response.confidence, equals(0.0));
});

// Test citation enforcement
test('All responses include source citations', () async {
  final response = await generationService.generate(
    query: 'Explain Newton\'s laws',
    context: mockRetrievalResults,
    intent: QueryIntent.questionAnswering,
  );
  
  expect(response.content, contains('[1]'));
  expect(response.sources, isNotEmpty);
});
```

#### 11.2 Integration Tests

```dart
// End-to-end chat flow
testWidgets('Complete chat interaction', (tester) async {
  // 1. Index a test document
  await indexDocumentUseCase.execute(...);
  
  // 2. Create chat session
  final session = await chatRepository.createSession('Test');
  
  // 3. Ask question
  final response = await askQuestionUseCase.execute(
    AskQuestionParams(
      question: 'What is mitosis?',
      sessionId: session.id!,
    ),
  );
  
  // 4. Verify response
  expect(response.content, isNotEmpty);
  expect(response.sources, isNotEmpty);
  
  // 5. Verify persistence
  final messages = await chatRepository.getMessages(session.id!);
  expect(messages.length, equals(2)); // User + Assistant
});
```

#### 11.3 Performance Tests

```dart
test('Retrieval completes within 500ms', () async {
  final stopwatch = Stopwatch()..start();
  
  await retrievalService.retrieve(query: 'test query', limit: 10);
  
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(500));
});

test('Handles 1000 chunks efficiently', () async {
  // Index 1000 test chunks
  for (int i = 0; i < 1000; i++) {
    await indexRepository.addChunk(mockChunk());
  }
  
  // Retrieval should still be fast
  final stopwatch = Stopwatch()..start();
  final results = await retrievalService.retrieve(query: 'test', limit: 10);
  stopwatch.stop();
  
  expect(results, isNotEmpty);
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

---

### 12. Future Enhancements (Phase 2+)

#### 12.1 Advanced Features

**Query Understanding:**
- Intent classification beyond basic types
- Named entity recognition for better filtering
- Query expansion with synonyms/related terms

**Multi-turn Conversation:**
- Context tracking across messages
- Follow-up question handling
- Clarification requests

**Personalization:**
- Learn from user feedback (thumbs up/down)
- Adapt retrieval based on past interactions
- User-specific ranking adjustments

#### 12.2 Advanced Retrieval

**Temporal Filtering:**
- Weight recent notes higher
- Filter by date ranges
- Track note recency in ranking

**Subject-aware Search:**
- Restrict search to specific subjects
- Cross-subject synthesis
- Subject relationship mapping

**Metadata-enhanced Retrieval:**
- Use tags for filtering
- Consider note importance/frequency
- Leverage file organization structure

#### 12.3 Advanced Generation

**Multi-document Synthesis:**
- Combine information from multiple sources
- Identify contradictions
- Generate comparative summaries

**Visual Content:**
- Extract text from images (OCR integration)
- Reference diagrams in responses
- Generate simple visualizations (charts, timelines)

**Interactive Responses:**
- Clickable source previews
- Inline definitions
- Related questions suggestions

---

## Summary

### Architecture Highlights

1. **Fully Offline**: All processing on-device, no network dependency
2. **Hybrid Retrieval**: BM25 + embeddings with Reciprocal Rank Fusion
3. **No Hallucination**: Strict grounding in user data with mandatory citations
4. **Lightweight**: ~22MB model, quantized embeddings, efficient indexing
5. **Clean Architecture**: Domain-driven design, testable, maintainable

### Key Components

| Component | Technology | Size/Performance |
|-----------|-----------|------------------|
| Embedding Model | MiniLM-L6-v2 (TFLite) | 22 MB, ~50ms per encoding |
| Keyword Search | SQLite FTS5 (BM25) | Built-in, <10ms queries |
| Vector Search | Cosine similarity | ~100ms for 10K chunks |
| Storage | SQLite + quantized embeddings | 75% size reduction |
| Generation | Extractive + Templates | No additional models |

### Implementation Priorities

**Phase 1 (MVP):**
1. Document chunking and indexing
2. Keyword retrieval (FTS5)
3. Basic extractive QA
4. Simple chat UI

**Phase 2:**
5. Embedding model integration
6. Hybrid retrieval
7. Template-based generation
8. Citation system

**Phase 3:**
9. Advanced query understanding
10. Multi-turn conversations
11. Personalization
12. Performance optimizations

This architecture provides a solid foundation for a production-ready offline AI chat system that respects user data, prevents hallucination, and delivers accurate, grounded responses.
