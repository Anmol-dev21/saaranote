import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Data layer
import 'data/datasources/local/database_helper.dart';
import 'data/repositories/note_repository_impl.dart';
import 'data/repositories/summary_repository_impl.dart';
import 'data/repositories/flashcard_repository_impl.dart';

// Domain layer
import 'domain/repositories/note_repository.dart';
import 'domain/repositories/summary_repository.dart';
import 'domain/repositories/flashcard_repository.dart';
import 'domain/usecases/get_all_notes_usecase.dart';
import 'domain/usecases/get_note_by_id_usecase.dart';
import 'domain/usecases/update_note_usecase.dart';
import 'domain/usecases/delete_note_usecase.dart';
import 'domain/usecases/create_note_from_text_usecase.dart';
import 'domain/usecases/create_note_from_image_usecase.dart';
import 'domain/usecases/get_summaries_for_note_usecase.dart';
import 'domain/usecases/get_flashcards_for_note_usecase.dart';

// Core services
import 'core/services/ocr_service.dart';

// Presentation layer
import 'presentation/viewmodels/note_viewmodel.dart';
import 'presentation/viewmodels/create_note_viewmodel.dart';
import 'presentation/viewmodels/note_detail_viewmodel.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize dependencies
    final databaseHelper = DatabaseHelper.instance;
    
    // Repositories
    final noteRepository = NoteRepositoryImpl(databaseHelper);
    final summaryRepository = SummaryRepositoryImpl(databaseHelper);
    final flashcardRepository = FlashcardRepositoryImpl(databaseHelper);
    
    // Services
    final ocrService = OcrService();
    
    // Use cases
    final getAllNotesUseCase = GetAllNotesUseCase(noteRepository);
    final getNoteByIdUseCase = GetNoteByIdUseCase(noteRepository);
    final updateNoteUseCase = UpdateNoteUseCase(noteRepository);
    final deleteNoteUseCase = DeleteNoteUseCase(
      noteRepository,
      summaryRepository,
      flashcardRepository,
    );
    final createNoteFromTextUseCase = CreateNoteFromTextUseCase(
      noteRepository,
      summaryRepository,
      flashcardRepository,
    );
    final createNoteFromImageUseCase = CreateNoteFromImageUseCase(
      noteRepository,
      summaryRepository,
      flashcardRepository,
      ocrService,
    );
    final getSummariesForNoteUseCase = GetSummariesForNoteUseCase(summaryRepository);
    final getFlashcardsForNoteUseCase = GetFlashcardsForNoteUseCase(flashcardRepository);

    return MultiProvider(
      providers: [
        // ViewModels
        ChangeNotifierProvider(
          create: (_) => NoteViewModel(
            getAllNotesUseCase,
            getNoteByIdUseCase,
            updateNoteUseCase,
            deleteNoteUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CreateNoteViewModel(
            createNoteFromTextUseCase,
            createNoteFromImageUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NoteDetailViewModel(
            getNoteByIdUseCase,
            getSummariesForNoteUseCase,
            getFlashcardsForNoteUseCase,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Saaranote',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
