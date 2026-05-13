# SaaraNote Complete Project Documentation

A professional, end-to-end technical and beginner-friendly guide to the SaaraNote application.

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Application Features](#2-application-features)
3. [Tech Stack](#3-tech-stack)
4. [Project Architecture](#4-project-architecture)
5. [Folder Structure Explanation](#5-folder-structure-explanation)
6. [Database System](#6-database-system)
7. [OCR System](#7-ocr-system)
8. [PDF Processing System](#8-pdf-processing-system)
9. [AI System (Deterministic + Hybrid)](#9-ai-system-deterministic--hybrid)
10. [AI Model Details](#10-ai-model-details)
11. [Summarization Pipeline](#11-summarization-pipeline)
12. [AI Chat and Retrieval System](#12-ai-chat-and-retrieval-system)
13. [File Management System](#13-file-management-system)
14. [UI/UX System](#14-uiux-system)
15. [Main Important Files](#15-main-important-files)
16. [Main Algorithms](#16-main-algorithms)
17. [Performance Optimization](#17-performance-optimization)
18. [Security and Privacy](#18-security-and-privacy)
19. [Challenges Faced and Solutions](#19-challenges-faced-and-solutions)
20. [Future Improvements](#20-future-improvements)
21. [Complete App Flow](#21-complete-app-flow)
22. [Installation Guide](#22-installation-guide)
23. [Build and Release Guide](#23-build-and-release-guide)
24. [Final Conclusion](#24-final-conclusion)

---

## 1. Project Overview

### Short Overview
SaaraNote is an offline-first note-taking and study companion built with Flutter. It converts typed text, images, and PDFs into organized notes, summaries, and flashcards, and provides an offline Q and A experience over local notes. Everything runs on-device by default.

### Detailed Overview
Students often collect notes from multiple sources: typed notes, camera scans, and PDFs. SaaraNote provides a unified pipeline that:
- Captures content from text, images (OCR), and PDFs.
- Cleans and normalizes the text for readability.
- Generates deterministic summaries, key points, and flashcards.
- Optionally refines structured summaries using a local LLM (Ollama).
- Indexes notes into a local SQLite FTS index for offline retrieval.
- Offers an offline AI chat UI with citations from local data.

### Target Users
- College and university students
- Learners who want offline study tools
- Developers learning Flutter, AI pipelines, and clean architecture

### Main Problems Solved
- Scattered study content across multiple formats
- Time-consuming manual summarization
- Unreliable or private data concerns with cloud AI
- Lack of offline-friendly learning tools

### Why Offline-First Matters
- Notes and study materials are often sensitive.
- Local-first storage avoids privacy risks and network latency.
- Offline OCR and retrieval work anywhere.

### Key Features (High-Level)
- Text, image, and PDF note creation
- OCR with preprocessing
- Offline summarization and key points
- Flashcard generation and review
- Offline AI chat with citations
- Rich text and drawing notes (hybrid editor)
- PDF export
- File organization backend and source file persistence

---

## 2. Application Features

Below is a feature-by-feature explanation that includes what it does, how it works, technologies used, and main files involved.

### 2.1 Text Notes
- What it does: Create notes by typing or pasting text.
- How it works: Text is cleaned and stored in SQLite. Optional summaries and flashcards are generated.
- Technologies: Flutter UI, SQLite, deterministic summarizer.
- Main files:
  - lib/domain/usecases/create_note_from_text_usecase.dart
  - lib/core/utils/text_processor.dart
  - lib/data/repositories/note_repository_impl.dart

### 2.2 Image OCR Notes
- What it does: Convert images into text-based notes.
- How it works: Images are preprocessed, then OCR extracts text using ML Kit. Cleaned text becomes a note.
- Technologies: google_mlkit_text_recognition, image (preprocessing).
- Main files:
  - lib/core/services/ocr_service.dart
  - lib/domain/usecases/create_note_from_image_usecase.dart

### 2.3 PDF Import
- What it does: Import PDF files and extract text as notes.
- How it works: Syncfusion extracts embedded text. If empty, OCR fallback renders first pages via pdf_render.
- Technologies: syncfusion_flutter_pdf, pdf_render, google_mlkit_text_recognition.
- Main files:
  - lib/core/services/pdf_text_service.dart
  - lib/domain/usecases/create_note_from_pdf_usecase.dart

### 2.4 Rich Text Editing
- What it does: Bold, italic, underline, size and color formatting.
- How it works: Rich text spans are stored with ranges and styles, serialized into JSON.
- Technologies: Custom RichTextContent model, Flutter TextSpan rendering.
- Main files:
  - lib/core/services/rich_text_service.dart
  - lib/domain/entities/rich_text_content.dart
  - lib/presentation/widgets/rich_text_toolbar.dart

### 2.5 Drawing Notes
- What it does: Handwriting and free-draw notes.
- How it works: Strokes are captured, optimized, serialized, and stored in SQLite.
- Technologies: CustomPainter, Douglas-Peucker simplification.
- Main files:
  - lib/core/services/drawing_service.dart
  - lib/data/datasources/local/drawing_local_data_source.dart
  - lib/presentation/widgets/drawing_canvas.dart

### 2.6 Hybrid Notes
- What it does: Combine text and drawing in a single note.
- How it works: Note content tracks content_type and optional drawing IDs.
- Technologies: Custom content types and drawing persistence.
- Main files:
  - lib/domain/entities/note.dart
  - lib/presentation/screens/note_editor_screen.dart

### 2.7 Summaries (Deterministic + Hybrid)
- What it does: Generate structured summaries and key points.
- How it works: AIEngine produces structured summaries. HybridSummaryService can rewrite them with a local LLM.
- Technologies: Deterministic NLP + Ollama (optional).
- Main files:
  - lib/core/ai_engine.dart
  - lib/core/services/hybrid_summary_service.dart
  - lib/core/utils/summary_formatter.dart

### 2.8 Flashcard Generation
- What it does: Converts definitions and key facts into Q/A flashcards.
- How it works: Rule-based extraction from sentences.
- Technologies: TextProcessor + KeyPointExtractor.
- Main files:
  - lib/core/utils/key_point_extractor.dart
  - lib/domain/usecases/create_note_from_text_usecase.dart
  - lib/presentation/screens/flashcard_revision_screen.dart

### 2.9 Offline AI Chat with Citations
- What it does: Ask questions about local notes with cited sources.
- How it works: Local chunk indexing + FTS search + reranking + answer composition.
- Technologies: SQLite FTS, deterministic answer composer.
- Main files:
  - lib/core/services/document_indexing_service.dart
  - lib/core/services/retrieval_service.dart
  - lib/core/services/offline_qa_service.dart
  - lib/domain/usecases/ask_question_usecase.dart

### 2.10 Search and Filtering
- What it does: Search by title/content and filter by date/order.
- How it works: SQL LIKE search against notes table.
- Technologies: SQLite, Provider.
- Main files:
  - lib/data/repositories/note_repository_impl.dart
  - lib/presentation/viewmodels/note_viewmodel.dart

### 2.11 PDF Export
- What it does: Export notes, summaries, and flashcards to a PDF document.
- How it works: PDF is generated with structured sections and saved to temp directory.
- Technologies: pdf package.
- Main files:
  - lib/core/services/pdf_export_service.dart
  - lib/presentation/viewmodels/note_detail_viewmodel.dart

### 2.12 File Organization Backend
- What it does: Organizes files into subject/date/type folders and tracks metadata.
- How it works: File metadata stored in SQLite, with optional subject detection.
- Technologies: File I/O + SQLite.
- Main files:
  - lib/core/services/file_organization_service.dart
  - lib/data/repositories/file_organization_repository_impl.dart

### 2.13 Source File Persistence
- What it does: Keeps original images and PDFs for preview.
- How it works: Copies files into app documents directory under source_files.
- Technologies: path_provider.
- Main files:
  - lib/core/services/source_file_service.dart

### 2.14 Settings System
- What it does: Theme, text scale, and AI toggles.
- How it works: SharedPreferences storage; UI toggles update local state.
- Technologies: shared_preferences.
- Main files:
  - lib/core/services/settings_service.dart
  - lib/presentation/screens/settings_screen.dart

---

## 3. Tech Stack

### Core Framework
- Flutter (UI, cross-platform)
- Dart (language)
- Provider (MVVM state management)

### Data and Storage
- SQLite via sqflite for notes, summaries, flashcards, chat, and indexing
- SharedPreferences for app settings
- path_provider for app storage paths

### OCR and Image Processing
- Google ML Kit Text Recognition for OCR
- image package for grayscale, denoise, thresholding

### PDF Handling
- syncfusion_flutter_pdf for text extraction
- pdf_render for rendering scanned PDFs for OCR fallback
- pdf for PDF export

### AI and NLP
- Deterministic AIEngine (keyword extraction, sentence ranking, structured output)
- Ollama local LLM integration for summary rewrite (optional)
- Default model configured: qwen2.5:3b
- Prompt template mentions Phi-3, but runtime model is set in LlmService

### Why These Choices
- Flutter + Provider: fast iteration and clean MVVM architecture.
- SQLite: reliable offline persistence and full-text search with FTS.
- ML Kit OCR: on-device OCR without external services.
- Ollama: local-only LLM option without cloud dependency.

---

## 4. Project Architecture

SaaraNote follows Clean Architecture with MVVM in the presentation layer.

### Layers
- Presentation: Screens and ViewModels
- Domain: Entities, repositories, use cases
- Data: SQLite data sources and repository implementations
- Core: AI engine, services, utilities, design system

### Dependency Flow
Presentation -> Domain -> Data
Core utilities are shared and are not dependent on UI.

### Architecture Diagram (ASCII)

```
+----------------------------+     +---------------------------+
|        Presentation        |     |          Core             |
| Screens + ViewModels       |<----| Services + AI + Utils     |
+-------------+--------------+     +-------------+-------------+
              |                                |
              v                                v
+-------------+--------------+     +-------------+-------------+
|            Domain          |---->|            Data           |
| Entities + Use Cases       |     | SQLite + Repositories     |
+----------------------------+     +---------------------------+
```

### Data Flow (Simplified)

```
User input -> ViewModel -> Use Case -> Repository -> SQLite
User query -> Retrieval -> Offline QA -> Response + Citations
```

---

## 5. Folder Structure Explanation

### lib/
Core app code.

### lib/core/
- ai_engine.dart: deterministic summary engine
- services/: OCR, PDF, retrieval, LLM, file management
- utils/: text cleanup, summarization, keyword ranking
- design_system/: colors, spacing, typography, components

### lib/data/
- datasources/local/: SQLite helper, drawing storage
- models/: serialization models for entities
- repositories/: SQLite repository implementations

### lib/domain/
- entities/: note, summary, flashcard, chat, files
- repositories/: abstract contracts
- usecases/: business logic classes

### lib/presentation/
- screens/: UI screens (home, add note, editor, chat, settings)
- viewmodels/: MVVM state controllers
- widgets/: rich text and drawing widgets

### vendor/
Local PDF render plugin used for OCR fallback.

---

## 6. Database System

SQLite is used with version 4 schema in DatabaseHelper.

### Core Tables
- notes: text content + rich content + drawing ids
- drawings: JSON-serialized strokes
- summaries: summaries per note
- flashcards: Q/A pairs with confidence
- file_metadata + organization_rules: file organization backend
- document_chunks + document_chunks_fts: retrieval index
- chat_sessions + chat_messages + message_sources: offline chat

### Example Schema (Notes)
```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  is_archived INTEGER DEFAULT 0,
  color TEXT,
  rich_content TEXT,
  drawing_ids TEXT,
  content_type TEXT DEFAULT 'plain'
)
```

### Indexing and FTS
- document_chunks_fts uses FTS5 with a fallback to FTS4.
- Triggers keep FTS table in sync with document_chunks.

### Note Persistence
- Notes are stored in notes.
- Summaries and flashcards are stored in their own tables.
- Drawings are serialized JSON and stored in drawings.
- Rich content is serialized JSON stored in notes.rich_content.

---

## 7. OCR System

### Pipeline
1. Load image file or bytes
2. Preprocess image
3. Run ML Kit OCR
4. Clean and normalize output text

### Preprocessing Steps (OcrService)
- Resize to max dimension (default 2000)
- Grayscale conversion
- Contrast and brightness boost
- Gaussian blur for denoise
- Luminance thresholding if scanned-like

### Output Cleanup (TextProcessor)
- Remove OCR artifacts and control characters
- Fix hyphenated line breaks
- Normalize punctuation and spacing
- Merge lines while preserving lists

### Main Files
- lib/core/services/ocr_service.dart
- lib/core/utils/text_processor.dart

---

## 8. PDF Processing System

### PDF Extraction Flow
1. Extract embedded text via Syncfusion PDF.
2. If empty, render first pages via pdf_render.
3. Run OCR on rendered pages.
4. Clean and normalize extracted text.

### Why This Design
- Some PDFs are scanned images with no embedded text.
- OCR fallback ensures coverage for scanned documents.

### Main Files
- lib/core/services/pdf_text_service.dart
- lib/core/services/ocr_service.dart

---

## 9. AI System (Deterministic + Hybrid)

SaaraNote uses a two-layer AI pipeline:

1) Deterministic AIEngine (always available)
2) Optional LLM rewrite (HybridSummaryService) using Ollama

### Deterministic Engine (AIEngine)
- Extracts keywords
- Ranks sentences
- Builds structured summary with title, key points, and sections

### Hybrid Summary Service
- Sends structured summary to a local LLM
- Validates output structure before accepting
- Uses in-memory LRU-style cache for repeated prompts

### LLM Integration
- LlmService uses Ollama endpoints:
  - http://localhost:11434
  - http://10.0.2.2:11434 (Android emulator)
  - http://127.0.0.1:11434
- Model name: qwen2.5:3b
- Temperature and top_p tuned to reduce hallucination

### Why Hybrid AI
- Deterministic summaries are stable and fast
- LLM rewrite can improve readability without changing facts
- Hybrid approach avoids full reliance on LLMs

---

## 10. AI Model Details

### Default Model
- Configured model: qwen2.5:3b
- Host: Ollama local server
- Task: rewrite structured summaries to simpler notes

### Phi-3 Mention
- The prompt template is labeled for Phi-3 in LlmPromptBuilder
- Runtime model selection is controlled in LlmService
- To switch models, update LlmService._model

### Offline Inference
- Ollama runs locally, so no cloud data transfer
- If Ollama is not available, hybrid enhancement is skipped

### Resource Considerations
- Local LLMs are CPU and RAM heavy
- Exact requirements vary by device and model build
- Expect multi-GB RAM usage for 3B models on desktop-class hardware

---

## 11. Summarization Pipeline

### Full Flow
```
Input text
  -> TextProcessor.cleanText
  -> KeywordExtractor.extractKeywords
  -> SentenceRanker.rankSentences
  -> AIEngine.buildStructuredSummary
  -> SummaryFormatter.formatStructuredSummary
  -> (Optional) HybridSummaryService with Ollama
  -> Final summary stored in SQLite
```

### Structured Output Example (Format)
```
Title: <short title>
Summary: <1-2 sentences>
Key Points:
- point 1
- point 2
```

### Why Deterministic Preprocessing Exists
- Ensures stable output even without LLM
- Avoids hallucinations
- Supports offline-only devices

---

## 12. AI Chat and Retrieval System

### Indexing
- Notes are chunked into 140-word segments with overlap.
- Chunks are stored in document_chunks.
- FTS index is built in document_chunks_fts.

### Retrieval
- Keyword retrieval with FTS5 (bm25 scoring)
- Fallback to LIKE search if FTS unavailable

### Reranking
- Query expansion with stems and synonyms
- Re-ranking with overlap, phrase hits, and length penalty

### Answer Composition
- Intent classification: definition, list, summary, comparison
- Answers are built from top chunks
- Citations are attached to chat messages

### Main Files
- lib/core/services/document_indexing_service.dart
- lib/core/services/retrieval_service.dart
- lib/core/services/offline_qa_service.dart
- lib/data/repositories/index_repository_impl.dart

---

## 13. File Management System

### Source File Persistence
- Original PDFs and images are copied into:
  documents/saaranote/source_files/{images|pdfs}

### File Organization Backend
- File metadata stored in file_metadata
- Supports subject detection and folder organization
- UI for folders/tags is currently placeholder in Library screen

### Main Files
- lib/core/services/source_file_service.dart
- lib/core/services/file_organization_service.dart
- lib/data/repositories/file_organization_repository_impl.dart

---

## 14. UI/UX System

### Design System
- Material 3 theme
- App-specific colors, typography, spacing, and components

### Primary Screens
- Home: note list + quick actions
- Add Note: text, image OCR, or PDF import
- Note Editor: rich text, drawing, hybrid modes
- Note Detail: content, summaries, flashcards, export
- AI Chat: offline Q and A with citations
- Settings: theme, text scale, AI toggles
- Library: all notes + folders/tags placeholders

### MVVM Binding
- ViewModels use ChangeNotifier + Provider
- UI widgets rebuild based on state

---

## 15. Main Important Files

- lib/main.dart: dependency injection and app wiring
- lib/core/ai_engine.dart: deterministic summary engine
- lib/core/services/ocr_service.dart: OCR pipeline
- lib/core/services/pdf_text_service.dart: PDF extraction and OCR fallback
- lib/core/services/hybrid_summary_service.dart: LLM-based summary rewrite
- lib/core/services/llm_service.dart: Ollama integration
- lib/core/services/offline_qa_service.dart: offline QA composition
- lib/core/services/document_indexing_service.dart: chunk indexing
- lib/core/services/retrieval_service.dart: query retrieval
- lib/data/datasources/local/database_helper.dart: SQLite schema and migrations
- lib/presentation/screens/note_editor_screen.dart: rich text and drawing editor
- lib/presentation/screens/ai_chat_screen.dart: offline chat UI

---

## 16. Main Algorithms

### Sentence Ranking
- Scores sentences by position, length, keywords, and structure
- Removes near-duplicates using Jaccard similarity

### Keyword Extraction
- Tokenization + stopword removal
- Light stemming
- Frequency scoring with length boosts

### OCR Cleanup
- De-hyphenation at line breaks
- Noise removal and punctuation normalization
- Paragraph reconstruction while preserving lists

### Retrieval Reranking
- Query expansion with stems and synonyms
- Overlap and phrase-hit scoring
- Length penalty for long chunks

### Drawing Optimization
- Douglas-Peucker line simplification to reduce points

---

## 17. Performance Optimization

- OCR preprocessing runs in compute isolates to avoid UI jank
- Drawing strokes are simplified before storage
- Retrieval uses SQLite FTS for fast keyword search
- Summary enhancement caches LLM responses
- Chunking limits retrieval payload size
- Note editor uses selective rebuilds and CustomPainter

---

## 18. Security and Privacy

- Offline-first: no external cloud dependency by default
- Local SQLite storage for all notes and chat history
- Optional local LLM (Ollama) keeps data on device
- No API keys required for core features

---

## 19. Challenges Faced and Solutions

### OCR Noise and Scanned Images
- Problem: low-quality images create noisy text
- Solution: preprocessing pipeline + text cleanup rules

### Scanned PDFs Without Embedded Text
- Problem: text extraction returns empty
- Solution: render pages and OCR fallback

### Summary Quality Without LLM
- Problem: generic summaries can be shallow
- Solution: structured summaries and optional LLM rewrite

### Retrieval Accuracy
- Problem: keyword-only search can miss context
- Solution: query expansion + reranking

### Drawing Storage Size
- Problem: large drawings can bloat storage
- Solution: Douglas-Peucker simplification and size estimation

### Offline LLM Availability
- Problem: Ollama may not be running on device
- Solution: hybrid summary falls back to deterministic output

---

## 20. Future Improvements

- Add semantic embeddings for higher-quality retrieval
- Provide a full folder and tag management UI
- Optional cloud sync and encrypted backup
- Multilingual OCR enhancements
- Improved flashcard scheduling and spaced repetition
- Expand export formats (Markdown, HTML)

---

## 21. Complete App Flow

### End-to-End Flow (Image to Chat)
```
User captures image
  -> OcrService preprocess
  -> ML Kit OCR
  -> TextProcessor clean
  -> Create note in SQLite
  -> AIEngine summary + flashcards
  -> (Optional) LLM rewrite
  -> DocumentIndexingService chunking
  -> FTS index
  -> AI Chat query
  -> Retrieval + rerank
  -> Answer + citations
```

### Flow by Input Type
- Text: Direct clean -> summarize -> index
- Image: OCR -> clean -> summarize -> index
- PDF: Extract -> OCR fallback -> clean -> summarize -> index

---

## 22. Installation Guide

### Prerequisites
- Flutter SDK 3.10.4 or newer
- Android Studio or VS Code with Flutter extension
- Android SDK or Xcode (for iOS)

### Setup
```bash
git clone https://github.com/Anmol-dev21/saaranote.git
cd saaranote/saaranote_app
flutter pub get
```

### Run
```bash
flutter run
```

### Optional: Ollama Setup (for Hybrid Summaries)
```bash
# Install Ollama (see https://ollama.com)
ollama pull qwen2.5:3b
ollama serve
```

---

## 23. Build and Release Guide

### Analyze and Test
```bash
flutter analyze
flutter test
```

### Build Release APK
```bash
flutter build apk --release
```
Output:
build/app/outputs/flutter-apk/app-release.apk

### Build App Bundle (Play Store)
```bash
flutter build appbundle --release
```

---

## 24. Final Conclusion

SaaraNote delivers an offline-first study assistant that combines OCR, deterministic summarization, flashcards, and a local retrieval-based chat system. Its clean architecture and MVVM design make it maintainable and easy to extend. The hybrid AI approach adds optional LLM quality without sacrificing offline reliability, and the strong storage and indexing foundations make it suitable for real-world student workflows.
