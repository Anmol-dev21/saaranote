# SaaraNote App

A production-ready Flutter application for intelligent note-taking with OCR, PDF import/export, automatic summarization, flashcard generation, rich text and drawing notes, and offline Q&A.

## Overview

SaaraNote is designed as an offline-first study companion that helps students and professionals capture, organize, and review information efficiently. AI processing happens on-device using Google ML Kit and custom services, with optional local LLM enhancement (Ollama) if available, ensuring privacy and functionality without internet connectivity. The app now includes a full Material 3 design system, a rich text and drawing editor, and an offline Q&A pipeline over local notes.

## Features

### 📝 Note Creation
- **Text Notes** - Type or paste content directly
- **Image OCR** - Extract text from photos using Google ML Kit Text Recognition
- **PDF Import** - Extract text from PDF documents for note creation
- **Rich Text Editor** - Bold, italic, underline, colors, and font sizes
- **Drawing Canvas** - Pen, highlighter, eraser, and hybrid text + drawing notes
- Auto-generates summaries and flashcards during creation

### 🔍 Search & Organization
- **Full-Text Search** - Search across note titles and content with instant results
- **Smart Filtering** - Sort by Recent or Oldest creation date
- **Quick Navigation** - Tap any note to view details with summaries and flashcards
- **File Organization System** - Backend for auto-organizing PDFs/images by subject
- **Folders & Tags (Coming Soon)** - Library UI is wired with tabs for future organization

### 🧠 Intelligent Features
- **Extractive Summarization** - Automatically generates concise summaries from note content
- **Hybrid Summaries (Optional)** - Enhances structured summaries with a local Ollama model
- **Flashcard Generation** - AI-powered question-answer pairs for effective revision
- **Key Point Extraction** - Identifies and extracts important concepts
- **Offline Q&A** - Ask questions about your notes using local retrieval
- **Document Indexing** - Chunks and indexes notes for offline retrieval with SQLite FTS

### 💬 AI Chat & Citations
- **Chat Sessions** - Start new conversations and keep history locally
- **Source Citations** - Answers include excerpts linked to indexed notes
- **Offline by Design** - No external API calls or network dependency

### 🧪 Diagnostics & Debug Tools
- **OCR Debugging** - Compare original vs preprocessed OCR output
- **Indexing Tools** - Inspect and rebuild retrieval indexes
- **Retrieval Debugging** - Inspect retrieval results and self-test Q&A

### 📤 Export & Sharing
- **PDF Export** - Generate formatted PDF documents containing:
  - Original note content
  - Generated summary
  - Key points
  - Flashcard Q&A pairs
- Clean, professional layout ready for printing or digital sharing

### 🔄 Flashcard Revision
- **Interactive Review** - Dedicated flashcard screen with question/answer flip
- **Navigation Controls** - Previous/Next buttons to move through cards
- **Confidence Tracking** - Track your confidence level for spaced repetition

### Appearance & Accessibility
- **Material 3 Design System** - Consistent colors, typography, and spacing
- **Theme Settings** - Light, dark, or system theme modes
- **Text Scaling** - Adjustable text scale for readability

### Settings & Preferences
- **AI Toggles** - Enable/disable offline chat, auto summaries, and flashcards
- **Local Storage Controls** - Manage cached files and exports

## Technology Stack

### Framework & Language
- **Flutter** 3.10.4+
- **Dart** - Modern, type-safe language

### State Management
- **Provider** - Reactive state management with ChangeNotifier
- **MVVM Pattern** - ViewModels manage business logic, Views handle presentation

### Local Storage
- **SQLite** (sqflite ^2.4.1) - Relational database for structured data
- **path_provider** - Cross-platform path management
- **shared_preferences** - Local settings storage
- **SQLite FTS** - Full-text search index for offline Q&A retrieval
- **Offline-First Design** - All data stored locally, no cloud dependency

### AI & Processing
- **Google ML Kit Text Recognition** (^0.13.1) - On-device OCR
- **Custom Algorithms**:
  - `TextProcessor` - Content cleaning and normalization
  - `Summarizer` - Extractive summarization using sentence scoring
  - `HybridSummaryService` - Optional LLM-enhanced structured summaries
  - `LlmService` - Local Ollama summary enhancement client
  - `KeyPointExtractor` - Question-answer pair generation
  - `RetrievalService` - Local retrieval over indexed notes
  - `OfflineQaService` - On-device question answering pipeline

### PDF Support
- **syncfusion_flutter_pdf** (^28.2.12) - Extract text from PDF files
- **pdf_render** (local) - Render PDF pages for OCR fallback
- **pdf** (^3.11.1) - Generate formatted PDF documents

### Other Dependencies
- **image_picker** (^1.1.2) - Camera and gallery access
- **file_picker** (^8.1.4) - File system navigation
- **http** (^1.2.2) - Local LLM calls (Ollama)
- **image** (^4.2.0) - OCR image preprocessing
- **google_fonts** (^8.0.2) - App typography (Inter)

## Architecture

### Clean Architecture Layers

```
lib/
├── core/
│   ├── ai_engine.dart     # Offline summarization engine
│   ├── design_system/     # Theme, typography, spacing, components
│   ├── services/          # OCR, PDF, rich text, drawing, retrieval, QA
│   └── utils/             # Text processing utilities
├── data/
│   ├── datasources/       # SQLite database operations
│   ├── models/            # Data models
│   └── repositories/      # Repository implementations
├── domain/
│   ├── entities/          # Notes, chat, drawings, file metadata
│   ├── repositories/      # Repository contracts
│   └── usecases/          # Business logic use cases
└── presentation/
  ├── screens/           # UI screens
  ├── viewmodels/        # State management (MVVM)
  └── widgets/           # Reusable UI widgets
```

### Key Design Patterns

**1. Clean Architecture**
- Domain layer is independent of frameworks and external libraries
- Data layer implements domain interfaces
- Presentation layer depends only on domain contracts

**2. MVVM (Model-View-ViewModel)**
- Views (Screens) observe ViewModels using Provider
- ViewModels manage state using ChangeNotifier
- Business logic delegated to Use Cases

**3. Repository Pattern**
- Abstract repositories define data contracts
- Implementations handle SQLite operations
- Easy to swap data sources (e.g., add remote sync)

**4. Use Case Pattern**
- Single-responsibility classes for business operations
- Examples: `CreateNoteFromImageUseCase`, `SearchNotesUseCase`
- Keeps ViewModels thin and testable

**5. Design System**
- Material 3 themes, typography, spacing, and reusable components
- Shared tokens for consistent UI across screens

## Database Schema

**Database Version:** 4

### Notes Table
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

### Drawings Table
```sql
CREATE TABLE drawings (
  id TEXT PRIMARY KEY,
  note_id INTEGER NOT NULL,
  drawing_data TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
)
```

### Summaries Table
```sql
CREATE TABLE summaries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note_id INTEGER NOT NULL,
  summary_text TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
)
```

### Flashcards Table
```sql
CREATE TABLE flashcards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note_id INTEGER NOT NULL,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  confidence_level INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  last_reviewed_at INTEGER,
  FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
)
```

### File Organization Tables
```sql
CREATE TABLE file_metadata (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_path TEXT NOT NULL UNIQUE,
  file_name TEXT NOT NULL,
  file_type INTEGER NOT NULL,
  subject TEXT,
  created_at INTEGER NOT NULL,
  last_modified INTEGER,
  file_size INTEGER NOT NULL,
  related_note_id TEXT,
  organization_status INTEGER DEFAULT 0,
  custom_folder TEXT,
  tags TEXT
)
```

```sql
CREATE TABLE organization_rules (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  subject_pattern TEXT,
  file_type INTEGER,
  target_folder TEXT NOT NULL,
  priority INTEGER DEFAULT 0,
  is_enabled INTEGER DEFAULT 1
)
```

### Offline Q&A Tables
```sql
CREATE TABLE document_chunks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_metadata_id INTEGER NOT NULL,
  chunk_index INTEGER NOT NULL,
  content TEXT NOT NULL,
  token_count INTEGER,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (file_metadata_id) REFERENCES file_metadata(id) ON DELETE CASCADE
)
```

```sql
CREATE VIRTUAL TABLE document_chunks_fts USING fts5(
  content,
  content='document_chunks',
  content_rowid='id'
)
```

FTS5 is used when available, with a fallback to FTS4 on devices without FTS5 support.

```sql
CREATE TABLE chat_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  tags TEXT
)
```

```sql
CREATE TABLE chat_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  status TEXT NOT NULL,
  FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
)
```

```sql
CREATE TABLE message_sources (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message_id INTEGER NOT NULL,
  file_metadata_id INTEGER NOT NULL,
  chunk_id INTEGER NOT NULL,
  relevance_score REAL NOT NULL,
  FOREIGN KEY (message_id) REFERENCES chat_messages(id) ON DELETE CASCADE,
  FOREIGN KEY (file_metadata_id) REFERENCES file_metadata(id) ON DELETE CASCADE,
  FOREIGN KEY (chunk_id) REFERENCES document_chunks(id) ON DELETE CASCADE
)
```

## Getting Started

### Prerequisites

- Flutter SDK 3.10.4 or higher
- Android Studio / VS Code with Flutter extensions
- Android SDK (API level 21+) or Xcode for iOS

### Installation

```bash
# Navigate to app directory
cd saaranote_app

# Install dependencies
flutter pub get

# Verify installation
flutter doctor
```

### Optional: Local LLM Summaries (Ollama)

SaaraNote can enhance structured summaries using a local Ollama model if it is running.

```bash
# Install Ollama and pull the model
ollama pull qwen2.5:3b

# Start the local server (defaults to http://localhost:11434)
ollama serve
```

The app will automatically try `localhost:11434` and Android emulator `10.0.2.2:11434`.

### Running the App

**Development Mode:**
```bash
flutter run
```

**Release Mode:**
```bash
flutter run --release
```

**Specific Device:**
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### Building

**Android APK (Release):**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS (requires macOS):**
```bash
flutter build ios --release
```

## Project Configuration

### Dependencies

All dependencies are managed in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2              # State management
  sqflite: ^2.4.1               # Local database
  path_provider: ^2.1.5         # File paths
  path: ^1.9.0                  # Path utilities
  shared_preferences: ^2.3.2    # Local settings
  google_mlkit_text_recognition: ^0.13.1  # OCR
  syncfusion_flutter_pdf: ^28.2.12  # PDF text extraction
  pdf_render:                   # PDF rendering (local path)
    path: vendor/pdf_render
  pdf: ^3.11.1                  # PDF generation
  file_picker: ^8.1.4           # File selection
  image_picker: ^1.1.2          # Camera/gallery
  google_fonts: ^8.0.2          # Typography
```

### App Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
- `CAMERA` - For capturing images
- `READ_EXTERNAL_STORAGE` - For image/PDF selection
- `WRITE_EXTERNAL_STORAGE` - For PDF export

**iOS** (`ios/Runner/Info.plist`):
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

## Key Features Implementation

### 1. Note Creation Flow

```dart
CreateNoteFromTextUseCase
  → TextProcessor.cleanText()
  → Summarizer.generateSummary()
  → HybridSummaryService.enhanceSummary() (optional, if local LLM available)
  → KeyPointExtractor.extractFlashcardPairs()
  → NoteRepository.create()
  → SummaryRepository.create()
  → FlashcardRepository.create()
```

### 2. OCR Processing

```dart
User captures image
  → ImagePicker.pickImage()
  → OcrService.recognizeText()
  → CreateNoteFromImageUseCase
  → Same flow as text creation
```

### 3. PDF Import

```dart
User selects PDF
  → FilePicker.pickFiles()
  → PdfTextService.extractTextFromPdf()
  → CreateNoteFromPdfUseCase
  → Same flow as text creation
```

### 4. Search

```dart
User types query
  → NoteViewModel.searchNotes()
  → SearchNotesUseCase.execute()
  → NoteRepository.searchNotes()
  → SQLite LIKE query on title/content
```

### 5. PDF Export

```dart
User taps export
  → NoteDetailViewModel.exportNoteAsPdf()
  → PdfExportService.exportNoteToPdf()
  → Generates formatted PDF with pw.Document()
  → Saves to temporary directory
  → Returns File for sharing
```

### 6. Rich Text and Drawing Editor

```dart
User opens editor
  → NoteEditorViewModel manages mode and formatting
  → RichTextService serializes spans to JSON
  → DrawingService serializes stroke data
  → NoteRepository.save() with rich_content and drawing_ids
  → Drawings saved in drawings table
```

### 7. Offline Q&A

```dart
User asks a question
  → ChatViewModel.sendMessage()
  → AskQuestionUseCase.execute()
  → RetrievalService uses SQLite FTS keyword search
  → OfflineQaService reranks context and generates response
  → ChatRepository stores messages and sources
```

### 8. File Organization

```dart
User imports files
  → FileOrganizationService.organizeFile()
  → Organization rules applied
  → FileOrganizationRepository saves metadata
  → Files indexed in file_metadata table
```

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Test Structure

```
test/
├── unit/           # Use case and utility tests
├── widget/         # Widget tests
└── integration/    # End-to-end tests
```

## Development Guidelines

### Adding New Features

1. **Domain Layer**: Define entity, repository interface, use case
2. **Data Layer**: Implement repository with database operations
3. **Presentation Layer**: Create ViewModel, then UI screen
4. **Dependency Injection**: Wire up in `main.dart`

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` to check for issues
- Format code with `dart format lib/`

### State Management Rules

- ViewModels use `ChangeNotifier` and call `notifyListeners()`
- Screens use `Consumer<T>` or `context.watch<T>()` to observe
- Never put business logic in widgets
- Use `context.read<T>()` for one-time actions

## Troubleshooting

### Common Issues

**Build Fails:**
```bash
flutter clean
flutter pub get
flutter build apk
```

**Database Issues:**
- Uninstall and reinstall the app
- Database recreates automatically on first launch

**OCR Not Working:**
- Ensure Google ML Kit models are downloaded
- Check camera permissions
- Use well-lit, clear images

## Performance Considerations

- **Database Indexing**: Indexes on `note_id` foreign keys for fast joins
- **Lazy Loading**: Notes loaded on-demand, not all at once
- **Text Processing**: Runs asynchronously to avoid UI blocking
- **Image Optimization**: Large images compressed before OCR

## Security & Privacy

- **Offline-First**: No data leaves the device
- **No Analytics**: No tracking or telemetry
- **Local Storage**: All data in SQLite on device
- **On-Device AI**: OCR and summarization happen locally
- **Optional Local LLM**: Uses local Ollama only if available

## Documentation

- Design system guide: [saaranote_app/DESIGN_SYSTEM.md](saaranote_app/DESIGN_SYSTEM.md)
- Advanced note foundation: [saaranote_app/ADVANCED_NOTE_FOUNDATION.md](saaranote_app/ADVANCED_NOTE_FOUNDATION.md)
- Rich text and drawing UI: [saaranote_app/RICH_TEXT_DRAWING_UI.md](saaranote_app/RICH_TEXT_DRAWING_UI.md)
- File organization system: [saaranote_app/FILE_ORGANIZATION_SYSTEM.md](saaranote_app/FILE_ORGANIZATION_SYSTEM.md)

## Contributing

This is a portfolio project, but feedback and suggestions are welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is developed as a portfolio demonstration.

---

**Developer**: Anmol Bhargav  
**Repository**: [github.com/Anmol-dev21/saaranote](https://github.com/Anmol-dev21/saaranote)  
**Built With**: Flutter • Dart • SQLite • Google ML Kit
