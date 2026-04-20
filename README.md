# SaaraNote

SaaraNote is an intelligent note-taking and study companion app built with Flutter. It transforms text, images, and PDFs into organized notes with auto-generated summaries and flashcards, leveraging on-device AI for complete offline functionality.

## Features

- **Smart Note Creation** - Create notes from typed text, camera images (OCR), or imported PDF files
- **Hybrid Summarization** - Rule-based summaries with optional local LLM enhancement
- **AI Enhancement Toggle** - Enable or disable AI rewriting per note
- **Flashcard Generation** - AI-powered flashcard creation for effective revision
- **Advanced Search** - Full-text search across all notes with instant results
- **Flexible Filtering** - Sort notes by date (Recent/Oldest) for quick organization
- **PDF Export** - Export notes with summaries and flashcards to formatted PDF documents
- **Offline-First** - All processing happens on-device; no internet required
- **Cross-Platform** - Built with Flutter for Android, iOS, and more

## Tech Stack

**Frontend Framework:** Flutter/Dart  
**Architecture:** Clean Architecture with MVVM pattern  
**State Management:** Provider  
**Local Database:** SQLite (sqflite)  
**OCR Engine:** Google ML Kit Text Recognition  
**PDF Processing:** pdf_text (extraction), pdf (generation)  
**Local LLM (Optional):** Ollama with Phi-3  

## Architecture

SaaraNote follows **Clean Architecture** principles with clear separation of concerns:

- **Domain Layer** - Business entities, repository interfaces, and use cases
- **Data Layer** - Repository implementations and local data sources (SQLite)
- **Presentation Layer** - ViewModels (MVVM) and UI screens

This architecture ensures maintainability, testability, and scalability while keeping the codebase organized and easy to understand.

### Documentation

Comprehensive architecture and feature documentation is available in the [`saaranote_app/docs/`](saaranote_app/docs/) directory, including:

- Design System guidelines
- Offline AI Chat Architecture (1700+ lines)
- Rich Text & Drawing UI implementation
- File Organization System
- Advanced Note Foundation

## Screenshots

*Coming soon*

## Testing

SaaraNote includes a comprehensive test suite covering all major functionality:

- **334 total tests** across 8 testing phases
- **100% pass rate** ensuring code quality
- Tests cover: Core functionality, search, flashcards, PDF export, offline mode, UI stability, and data safety

```bash
# Run all tests
flutter test

# Run specific test phase
flutter test test/phase2_functional_test.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.10.4 or higher)
- Android Studio / VS Code
- Android SDK or Xcode (for iOS)

### Installation

```bash
# Clone the repository
git clone https://github.com/Anmol-dev21/saaranote.git

# Navigate to the Flutter app directory
cd saaranote/saaranote_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Local LLM Setup (Optional)

If you want AI-enhanced summaries, run a local Ollama model:

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Run Phi-3 locally
ollama run phi3
```

The app connects to `http://localhost:11434` for local generation.

### Build Release APK

```bash
cd saaranote_app
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
saaranote/
├── README.md                 # This file
└── saaranote_app/           # Flutter application
    ├── lib/
    │   ├── core/            # Utilities, services, design system
    │   ├── data/            # Repositories and data sources
    │   ├── domain/          # Business logic and entities
    │   └── presentation/    # UI, ViewModels, and widgets
    ├── docs/                # Architecture documentation
    │   ├── README.md        # Documentation index
    │   ├── DESIGN_SYSTEM.md
    │   ├── OFFLINE_AI_CHAT_ARCHITECTURE.md
    │   └── [more docs...]
    ├── test/                # Comprehensive test suite (334 tests)
    │   ├── integration/     # Integration tests
    │   └── [test files...]
    └── README.md            # Detailed app documentation
```

## Author

**Anmol Kumar**  
[GitHub](https://github.com/Anmol-dev21)

## Future Roadmap

- [ ] Cloud sync and backup
- [ ] Spaced repetition algorithm for flashcards
- [ ] Note sharing and collaboration
- [ ] Voice note recording and transcription
- [ ] Dark mode theme customization
- [ ] Tags and categories for better organization
- [ ] Export to multiple formats (Markdown, HTML)

## License

This project is developed as a portfolio demonstration.

---

*Built with ❤️ using Flutter*
