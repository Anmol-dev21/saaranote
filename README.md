# SaaraNote

SaaraNote is an intelligent note-taking and study companion app built with Flutter. It transforms text, images, and PDFs into organized notes with auto-generated summaries and flashcards, leveraging on-device AI for complete offline functionality.

## Features

- **Smart Note Creation** - Create notes from typed text, camera images (OCR), or imported PDF files
- **Intelligent Summarization** - Automatic extractive summarization of note content
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

## Architecture

SaaraNote follows **Clean Architecture** principles with clear separation of concerns:

- **Domain Layer** - Business entities, repository interfaces, and use cases
- **Data Layer** - Repository implementations and local data sources (SQLite)
- **Presentation Layer** - ViewModels (MVVM) and UI screens

This architecture ensures maintainability, testability, and scalability while keeping the codebase organized and easy to understand.

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
├── README.md                 # This file
└── saaranote_app/           # Flutter application
    ├── lib/
    │   ├── core/            # Utilities and services
    │   ├── data/            # Repositories and data sources
    │   ├── domain/          # Business logic and entities
    │   └── presentation/    # UI and ViewModels
    └── README.md            # App-specific documentation
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
