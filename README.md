# SaaraNote

SaaraNote is an intelligent note-taking and study companion app built with Flutter. It turns text, images, and PDFs into organized notes with auto-generated summaries and flashcards, and now adds rich text, drawing, offline Q&A, and a full design system for a consistent UI.

## Features

- **Smart Note Creation** - Create notes from typed text, camera images (OCR), or imported PDF files
- **Rich Text + Drawing Notes** - Format text, sketch with pen/highlighter, or combine both in hybrid notes
- **Intelligent Summarization** - Automatic extractive summarization of note content
- **Flashcard Generation** - AI-powered flashcard creation for effective revision
- **Offline Q&A & AI Chat** - Ask questions about your notes with local retrieval and cited sources
- **Advanced Search** - Full-text search across all notes with instant results
- **Flexible Filtering** - Sort notes by date (Recent/Oldest) for quick organization
- **File Organization System** - Backend for auto-organizing PDFs/images into subject folders
- **PDF Export** - Export notes with summaries and flashcards to formatted PDF documents
- **Design System** - Material 3 theming with consistent typography, spacing, and components
- **Offline-First** - All processing happens on-device; no internet required
- **Cross-Platform** - Built with Flutter for Android, iOS, and more

## Tech Stack

**Frontend Framework:** Flutter/Dart  
**Architecture:** Clean Architecture with MVVM pattern  
**State Management:** Provider  
**Local Database:** SQLite (sqflite)  
**OCR Engine:** Google ML Kit Text Recognition  
**PDF Processing:** syncfusion_flutter_pdf (extraction), pdf (generation), pdf_render (fallback rendering)  
**Typography:** Google Fonts (Inter)  
**Settings:** shared_preferences  

## Architecture

SaaraNote follows **Clean Architecture** principles with clear separation of concerns:

- **Domain Layer** - Business entities, repository interfaces, and use cases
- **Data Layer** - Repository implementations and local data sources (SQLite)
- **Presentation Layer** - ViewModels (MVVM) and UI screens
- **Core Services** - OCR, PDF, rich text, drawing, retrieval, offline Q&A
- **Design System** - Theme, typography, spacing, and reusable UI components

This architecture ensures maintainability, testability, and scalability while keeping the codebase organized and easy to understand.

## Documentation

- Design system implementation: [DESIGN_SYSTEM_IMPLEMENTATION.md](DESIGN_SYSTEM_IMPLEMENTATION.md)
- UI/UX spec: [SAARANOTE_UI_UX_DESIGN.md](SAARANOTE_UI_UX_DESIGN.md)
- 2.0 system proposal: [SAARANOTE_2.0_DESIGN.md](SAARANOTE_2.0_DESIGN.md)
- App design system guide: [saaranote_app/DESIGN_SYSTEM.md](saaranote_app/DESIGN_SYSTEM.md)
- Advanced note foundation: [saaranote_app/ADVANCED_NOTE_FOUNDATION.md](saaranote_app/ADVANCED_NOTE_FOUNDATION.md)
- Rich text and drawing UI: [saaranote_app/RICH_TEXT_DRAWING_UI.md](saaranote_app/RICH_TEXT_DRAWING_UI.md)
- File organization system: [saaranote_app/FILE_ORGANIZATION_SYSTEM.md](saaranote_app/FILE_ORGANIZATION_SYSTEM.md)

## Screenshots

*Coming soon*

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

### Build Release APK

```bash
cd saaranote_app
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
saaranote/
├── README.md                       # This file
└── saaranote_app/                  # Flutter application
    ├── lib/
    │   ├── core/
    │   │   ├── ai_engine.dart      # Offline summarization engine
    │   │   ├── design_system/      # Theme, typography, spacing, components
    │   │   ├── services/           # OCR, PDF, rich text, drawing, retrieval, QA
    │   │   └── utils/              # Text processing utilities
    │   ├── data/
    │   │   ├── datasources/local/  # SQLite helpers
    │   │   ├── models/             # Data models
    │   │   └── repositories/       # Repository implementations
    │   ├── domain/
    │   │   ├── entities/           # Core entities (notes, chat, files)
    │   │   ├── repositories/       # Repository contracts
    │   │   └── usecases/           # Business logic use cases
    │   ├── presentation/
    │   │   ├── screens/            # UI screens
    │   │   ├── viewmodels/         # MVVM state management
    │   │   └── widgets/            # Reusable UI widgets
    │   └── main.dart               # App entry point
    └── README.md                   # App-specific documentation
```

## Author

**Anmol Bhargav**  
[GitHub](https://github.com/Anmol-dev21)

## Future Roadmap

- [ ] Cloud sync and backup
- [ ] Spaced repetition algorithm for flashcards
- [ ] Note sharing and collaboration
- [ ] Voice note recording and transcription
- [ ] Custom theme palettes and typography presets
- [ ] Tags and categories for better organization
- [ ] Export to multiple formats (Markdown, HTML)

## License

This project is developed as a portfolio demonstration.

---

*Built with ❤️ using Flutter*
