# SaaraNote Documentation

## Quick Navigation
- [1. Project Overview](#1-project-overview)
- [2. Key Features](#2-key-features)
- [3. How AI Works (Very Important)](#3-how-ai-works-very-important)
- [4. Architecture](#4-architecture)
- [5. Core Code Walkthrough](#5-core-code-walkthrough)
- [6. Drawing System](#6-drawing-system)
- [7. Data Storage](#7-data-storage)
- [8. UI/UX Design](#8-uiux-design)
- [9. Technologies Used](#9-technologies-used)
- [10. Performance and Optimization](#10-performance-and-optimization)
- [11. Limitations and Future Improvements](#11-limitations-and-future-improvements)
- [12. How to Run the Project](#12-how-to-run-the-project)

## 1. Project Overview

SaaraNote is an offline-first note-taking and study companion built with Flutter. It helps students capture content from text, images, and PDFs, then turns that content into structured study materials such as summaries, key points, and flashcards. The core idea is simple: provide a private, on-device study assistant that works without internet access.

**Problem it solves**
- Students often juggle scattered notes, scanned pages, and PDFs.
- Manual summarization and flashcard creation is slow and inconsistent.
- Many study tools require cloud access and expose private data.

**Target users**
- High school, college, and graduate students.
- Learners who need reliable offline study tools.

**Key idea**
- SaaraNote combines offline content capture (OCR and PDF text extraction) with lightweight AI-style processing to generate study aids locally.

## 2. Key Features

### Note creation (text, image, PDF)
- Create notes by typing or pasting text.
- Import images and extract text with OCR.
- Import PDFs and extract text for notes.

### OCR (image to text)
- Uses Google ML Kit Text Recognition for on-device OCR.
- Produces text that can be cleaned and summarized automatically.

### PDF import
- Uses `syncfusion_flutter_pdf` for text extraction.
- For scanned PDFs with no embedded text, `pdf_render` renders pages and OCR runs on the images.

### AI summarization (structured + simplified)
- Generates a structured summary with title, short summary, key points, sections, and detailed summary.
- Optional simplification step replaces complex words with simpler alternatives for student readability.

### Key points extraction
- Extracts high-signal sentences using rule-based scoring.
- Filters for definitions, comparisons, and important phrases.

### Flashcards
- Generates question-and-answer pairs from definitions and structured sentences.
- Creates flashcards automatically during note creation.

### Drawing + hybrid notes
- Rich text formatting (bold, italic, underline, colors, sizes).
- Drawing canvas with pen, highlighter, and eraser.
- Hybrid notes combine formatted text and drawings.

### Offline AI chat (RAG-based)
- Users can ask questions about their notes.
- Retrieval-Augmented Generation (RAG) is implemented with local keyword retrieval plus answer composition.
- Responses include citations with excerpts from the note index.

### Search and filtering
- Full-text search over note titles and content.
- Sorting options (recent, oldest) in the Library screen.

### PDF export
- Exports note content, summaries, key points, and flashcards to a formatted PDF.

## 3. How AI Works (Very Important)

SaaraNote uses lightweight, deterministic logic to generate study aids. There is no cloud model and no heavy on-device LLM. Everything runs locally.

### Summarization pipeline

1. **Text cleaning**
   - `TextProcessor.cleanText()` normalizes whitespace, punctuation, OCR artifacts, and broken line breaks.

2. **Sentence splitting**
   - `TextProcessor.splitIntoSentences()` splits cleaned content into sentences using punctuation and capitalization rules.

3. **Keyword extraction**
   - `KeywordExtractor.extractKeywords()` tokenizes text, removes stopwords, applies light stemming, and scores terms by frequency.

4. **Sentence ranking**
   - `SentenceRanker.rankSentences()` scores sentences using:
     - position in the document
     - length and structure
     - presence of keywords
     - definition patterns and numeric facts
     - similarity checks to avoid duplicates

5. **Topic grouping**
   - `AIEngine._buildSections()` groups sentences into buckets using keyword stems and builds short section summaries.

6. **Structured output**
   - `AIEngine.generateSummary()` produces:
     - Title
     - Short summary
     - Key points
     - Section bullets
     - Optional detailed summary
   - `SummaryFormatter.formatStructuredSummary()` formats the structured output into a readable report.

### Simplification engine

- `SimplificationService` is a dictionary-based replacement layer.
- It replaces complex words (for example, "utilize" -> "use") while preserving capitalization.
- This is optional and designed to reduce reading friction for students.

### Offline Q&A pipeline

1. **Indexing**
   - Note content is chunked and stored in `document_chunks`.
   - A SQLite FTS virtual table (`document_chunks_fts`) powers fast keyword search.

2. **Retrieval**
   - `RetrievalService` performs keyword search using FTS.
   - Results are returned as ranked chunks with scores.

3. **Re-ranking and composition**
   - `OfflineQaService` expands queries with stems and synonyms, then re-ranks results based on overlap and phrase hits.
   - Answers are composed using the top-ranked content with intent-aware formatting (definition, list, comparison, summary).

4. **Citations**
   - Sources are attached to chat messages using the `message_sources` table.
   - Users see citations and snippets in the chat UI.

### Why it works offline

- All steps use local data structures, local OCR, and SQLite.
- No external APIs or cloud inference are required.

## 4. Architecture

### Clean Architecture layers

- **core**: Cross-cutting services and utilities (OCR, PDF, retrieval, summarization, design system)
- **domain**: Entities, repository interfaces, and use cases
- **data**: SQLite data sources, models, and repository implementations
- **presentation**: Screens, ViewModels, and widgets

### MVVM pattern

- **ViewModels**: Manage state, user actions, and error handling.
- **Views (Screens)**: Render UI and bind to ViewModels using Provider.

### Role of key components

- **ViewModels**
  - `NoteViewModel` loads, searches, filters, and updates notes.
  - `CreateNoteViewModel` orchestrates text, OCR, and PDF note creation.
  - `NoteEditorViewModel` manages rich text and drawing state.
  - `ChatViewModel` manages offline AI chat sessions and messages.

- **Use cases**
  - Encapsulate business logic such as `CreateNoteFromPdfUseCase` or `AskQuestionUseCase`.
  - Keep ViewModels thin and consistent.

- **Services**
  - OCR, PDF parsing/export, retrieval, and drawing optimization live here.
  - Provide a stable API for the domain and presentation layers.

## 5. Core Code Walkthrough

This section explains the main code paths and where the core logic lives.

### App entry and dependency wiring

- The app starts in [saaranote_app/lib/main.dart](saaranote_app/lib/main.dart).
- This file wires up the database, repositories, services, and use cases.
- Providers are registered for ViewModels so the UI can access state and actions.

### Core services

- OCR is handled by `OcrService` in [saaranote_app/lib/core/services/ocr_service.dart](saaranote_app/lib/core/services/ocr_service.dart).
- PDF text extraction is handled by `PdfTextService` in [saaranote_app/lib/core/services/pdf_text_service.dart](saaranote_app/lib/core/services/pdf_text_service.dart).
- PDF export is handled by `PdfExportService` in [saaranote_app/lib/core/services/pdf_export_service.dart](saaranote_app/lib/core/services/pdf_export_service.dart).
- Rich text formatting is serialized by `RichTextService` in [saaranote_app/lib/core/services/rich_text_service.dart](saaranote_app/lib/core/services/rich_text_service.dart).
- Drawing optimization and serialization is handled by `DrawingService` in [saaranote_app/lib/core/services/drawing_service.dart](saaranote_app/lib/core/services/drawing_service.dart).
- Offline Q&A flow uses `RetrievalService` and `OfflineQaService` in [saaranote_app/lib/core/services/retrieval_service.dart](saaranote_app/lib/core/services/retrieval_service.dart) and [saaranote_app/lib/core/services/offline_qa_service.dart](saaranote_app/lib/core/services/offline_qa_service.dart).

### AI engine and utilities

- `AIEngine` in [saaranote_app/lib/core/ai_engine.dart](saaranote_app/lib/core/ai_engine.dart) builds structured summaries using:
   - `TextProcessor`, `KeywordExtractor`, and `SentenceRanker` in [saaranote_app/lib/core/utils](saaranote_app/lib/core/utils).
   - `SummaryFormatter` and `SimplificationService` for readable output.

### Data access and repositories

- SQLite initialization and migrations live in [saaranote_app/lib/data/datasources/local/database_helper.dart](saaranote_app/lib/data/datasources/local/database_helper.dart).
- Drawing storage uses [saaranote_app/lib/data/datasources/local/drawing_local_data_source.dart](saaranote_app/lib/data/datasources/local/drawing_local_data_source.dart).
- Repository implementations are in [saaranote_app/lib/data/repositories](saaranote_app/lib/data/repositories).
- The domain layer defines repository contracts in [saaranote_app/lib/domain/repositories](saaranote_app/lib/domain/repositories) and entities in [saaranote_app/lib/domain/entities](saaranote_app/lib/domain/entities).

### Note creation pipeline

- Text notes are created by `CreateNoteFromTextUseCase` in [saaranote_app/lib/domain/usecases/create_note_from_text_usecase.dart](saaranote_app/lib/domain/usecases/create_note_from_text_usecase.dart).
- Image notes go through OCR via `CreateNoteFromImageUseCase` in [saaranote_app/lib/domain/usecases/create_note_from_image_usecase.dart](saaranote_app/lib/domain/usecases/create_note_from_image_usecase.dart).
- PDF notes are handled by `CreateNoteFromPdfUseCase` in [saaranote_app/lib/domain/usecases/create_note_from_pdf_usecase.dart](saaranote_app/lib/domain/usecases/create_note_from_pdf_usecase.dart).
- These use cases create the note, then optionally generate summaries and flashcards.

### Offline AI chat pipeline

- Chat is orchestrated by `AskQuestionUseCase` in [saaranote_app/lib/domain/usecases/ask_question_usecase.dart](saaranote_app/lib/domain/usecases/ask_question_usecase.dart).
- Retrieval pulls chunks from the local FTS index, then `OfflineQaService` composes an answer with citations.
- Chat sessions and messages are persisted via `ChatRepositoryImpl` in [saaranote_app/lib/data/repositories/chat_repository_impl.dart](saaranote_app/lib/data/repositories/chat_repository_impl.dart).

### UI foundations

- The design system is centralized in [saaranote_app/lib/core/design_system/design_system.dart](saaranote_app/lib/core/design_system/design_system.dart).
- Rich text and drawing widgets live in [saaranote_app/lib/presentation/widgets](saaranote_app/lib/presentation/widgets).
- Screens are in [saaranote_app/lib/presentation/screens](saaranote_app/lib/presentation/screens) and bind to ViewModels in [saaranote_app/lib/presentation/viewmodels](saaranote_app/lib/presentation/viewmodels).

## 6. Drawing System

The drawing system is designed for smooth interaction and low-end device performance.

**Gesture handling**
- `DrawingCanvas` listens to pan start, update, and end events.
- Strokes are built incrementally as the user draws.

**Stroke buffer**
- Each stroke stores a list of `StrokePoint` objects (x, y, optional pressure).
- Strokes are collected into a `Drawing` object.

**CustomPainter rendering**
- `CustomPainter` renders strokes using quadratic Bezier curves for smooth paths.
- Eraser strokes use `BlendMode.clear` with a saveLayer to remove pixels cleanly.

**Undo/redo**
- `NoteEditorViewModel` maintains undo and redo stacks.
- Each drawing action becomes a history entry so users can roll back or reapply changes.

**Performance optimization**
- `DrawingService.optimizeDrawing()` applies the Douglas-Peucker algorithm to reduce point count without visible quality loss.
- The canvas uses `RepaintBoundary` to minimize redraw cost.

## 7. Data Storage

### SQLite usage

The app uses a local SQLite database (version 4). Key tables include:

- `notes`: stores note metadata and content.
- `summaries`: stores generated summaries per note.
- `flashcards`: stores Q&A pairs per note.
- `drawings`: stores serialized drawing data as JSON.
- `file_metadata` and `organization_rules`: store file organization metadata.
- `document_chunks` and `document_chunks_fts`: power offline search and Q&A.
- `chat_sessions`, `chat_messages`, `message_sources`: store offline AI chat history and citations.

### How content is stored

- Notes store plain text in `notes.content`.
- Rich text is serialized JSON and stored in `notes.rich_content`.
- Drawing IDs are stored in `notes.drawing_ids`, while the actual drawing data is stored in `drawings`.
- Summaries and flashcards are stored as separate entities for fast access and export.

### File handling (PDF/images)

- Imported PDFs and images are processed locally for text extraction.
- The file organization system can move files into structured folders by subject and date.

## 8. UI/UX Design

- Designed for students with a clean, minimal interface.
- Uses a design system for consistent typography, spacing, and components.
- Editor supports modes:
  - **Text**: rich text formatting toolbar
  - **Draw**: full canvas with drawing tools
  - **Hybrid**: combined text and drawing workflow

Performance considerations:
- Minimal widget rebuilds via Provider and Selector.
- CustomPainter for efficient drawing.
- Asynchronous background processing for OCR and PDF parsing.

## 9. Technologies Used

- Flutter and Dart
- SQLite (sqflite)
- Google ML Kit for OCR
- Syncfusion PDF for text extraction
- pdf_render for OCR fallback
- Custom offline AI pipeline for summarization and Q&A

## 10. Performance and Optimization

- Lightweight summarization and retrieval avoids heavy models.
- Optimized drawing storage reduces memory use.
- Offline-first design avoids latency and network dependency.
- Text processing is rule-based and deterministic, ensuring predictable performance.

## 11. Limitations and Future Improvements

Current limitations:
- Offline Q&A is keyword-based rather than semantic embedding search.
- Folder and tag management UI is still in progress.
- No cloud sync or multi-device support.

Future improvements:
- Add semantic embeddings for higher quality retrieval.
- Provide a full file organization UI with folder management.
- Add cloud sync and encrypted backups.
- Expand export formats to Markdown and HTML.
- Improve OCR for low-quality scans with additional preprocessing.

## 12. How to Run the Project

### Prerequisites
- Flutter SDK 3.10.4 or higher
- Android Studio or VS Code with Flutter extensions
- Android SDK (API 21+) or Xcode for iOS

### Setup
```bash
git clone https://github.com/Anmol-dev21/saaranote.git
cd saaranote/saaranote_app
flutter pub get
```

### Run locally
```bash
flutter run
```

### Build a release APK
```bash
flutter build apk --release
```

The APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`
