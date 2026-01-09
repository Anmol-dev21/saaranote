# SaaraNote App

A production-ready Flutter application for intelligent note-taking with AI-powered features including OCR, PDF import/export, automatic summarization, and flashcard generation.

## Overview

SaaraNote is designed as an offline-first study companion that helps students and professionals capture, organize, and review information efficiently. All AI processing happens on-device using Google ML Kit and custom algorithms, ensuring privacy and functionality without internet connectivity.

## Features

### 📝 Note Creation
- **Text Notes** - Type or paste content directly
- **Image OCR** - Extract text from photos using Google ML Kit Text Recognition
- **PDF Import** - Extract text from PDF documents for note creation
- Auto-generates summaries and flashcards during creation

### 🔍 Search & Organization
- **Full-Text Search** - Search across note titles and content with instant results
- **Smart Filtering** - Sort by Recent or Oldest creation date
- **Quick Navigation** - Tap any note to view details with summaries and flashcards

### 🧠 Intelligent Features
- **Extractive Summarization** - Automatically generates concise summaries from note content
- **Flashcard Generation** - AI-powered question-answer pairs for effective revision
- **Key Point Extraction** - Identifies and extracts important concepts

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
- **Offline-First Design** - All data stored locally, no cloud dependency

### AI & Processing
- **Google ML Kit Text Recognition** (^0.13.1) - On-device OCR
- **Custom Algorithms**:
  - `TextProcessor` - Content cleaning and normalization
  - `Summarizer` - Extractive summarization using sentence scoring
  - `KeyPointExtractor` - Question-answer pair generation

### PDF Support
- **pdf_text** (^0.5.0) - Extract text from PDF files
- **pdf** (^3.11.1) - Generate formatted PDF documents

### Other Dependencies
- **image_picker** (^1.1.2) - Camera and gallery access
- **file_picker** (^8.1.4) - File system navigation

## Architecture

### Clean Architecture Layers

```
lib/
├── core/
│   ├── services/          # External services (OCR, PDF)
│   └── utils/            # Helper utilities (TextProcessor, Summarizer)
├── data/
│   ├── datasources/      # SQLite database operations
│   ├── models/           # Data models
│   └── repositories/     # Repository implementations
├── domain/
│   ├── entities/         # Business entities (Note, Flashcard, Summary)
│   ├── repositories/     # Repository contracts
│   └── usecases/         # Business logic use cases
└── presentation/
    ├── screens/          # UI screens
    └── viewmodels/       # State management (MVVM)
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

## Database Schema

### Notes Table
```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  color TEXT,
  is_archived INTEGER DEFAULT 0
)
```

### Summaries Table
```sql
CREATE TABLE summaries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note_id INTEGER NOT NULL,
  summary_text TEXT NOT NULL,
  created_at TEXT NOT NULL,
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
  created_at TEXT NOT NULL,
  last_reviewed_at TEXT,
  FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
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
  google_mlkit_text_recognition: ^0.13.1  # OCR
  pdf_text: ^0.5.0              # PDF reading
  pdf: ^3.11.1                  # PDF generation
  file_picker: ^8.1.4           # File selection
  image_picker: ^1.1.2          # Camera/gallery
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
