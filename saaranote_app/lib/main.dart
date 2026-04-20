import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Design system
import 'core/design_system/app_theme.dart';

// Data layer
import 'data/datasources/local/database_helper.dart';
import 'data/repositories/note_repository_impl.dart';
import 'data/repositories/summary_repository_impl.dart';
import 'data/repositories/flashcard_repository_impl.dart';

// Domain layer
import 'domain/usecases/get_all_notes_usecase.dart';
import 'domain/usecases/get_note_by_id_usecase.dart';
import 'domain/usecases/update_note_usecase.dart';
import 'domain/usecases/delete_note_usecase.dart';
import 'domain/usecases/create_note_from_text_usecase.dart';
import 'domain/usecases/create_note_from_image_usecase.dart';
import 'domain/usecases/create_note_from_pdf_usecase.dart';
import 'domain/usecases/get_summaries_for_note_usecase.dart';
import 'domain/usecases/get_flashcards_for_note_usecase.dart';
import 'domain/usecases/search_notes_usecase.dart';

// Core services
import 'core/services/ocr_service.dart';
import 'core/services/pdf_export_service.dart';
import 'core/services/pdf_text_service.dart';
import 'core/services/rich_text_service.dart';
import 'core/services/drawing_service.dart';
import 'core/services/llm_service.dart';
import 'core/services/hybrid_summary_service.dart';

// Presentation layer
import 'presentation/viewmodels/note_viewmodel.dart';
import 'presentation/viewmodels/create_note_viewmodel.dart';
import 'presentation/viewmodels/note_detail_viewmodel.dart';
import 'presentation/viewmodels/note_editor_viewmodel.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  // Initialize Flutter binding before any async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-initialize database to avoid race conditions
  await DatabaseHelper.instance.database;
  
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
    final pdfExportService = PdfExportService();
    final pdfTextService = PdfTextService();
    final richTextService = RichTextService();
    final drawingService = DrawingService();
    final llmService = LlmService();
    final hybridSummaryService = HybridSummaryService(llmService: llmService);
    
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
      hybridSummaryService,
    );
    final createNoteFromImageUseCase = CreateNoteFromImageUseCase(
      noteRepository,
      summaryRepository,
      flashcardRepository,
      ocrService,
      hybridSummaryService,
    );
    final createNoteFromPdfUseCase = CreateNoteFromPdfUseCase(
      noteRepository,
      summaryRepository,
      flashcardRepository,
      pdfTextService,
      hybridSummaryService,
    );
    final getSummariesForNoteUseCase = GetSummariesForNoteUseCase(summaryRepository);
    final getFlashcardsForNoteUseCase = GetFlashcardsForNoteUseCase(flashcardRepository);
    final searchNotesUseCase = SearchNotesUseCase(noteRepository);

    return MultiProvider(
      providers: [
        // ViewModels
        ChangeNotifierProvider(
          create: (_) => NoteViewModel(
            getAllNotesUseCase,
            getNoteByIdUseCase,
            updateNoteUseCase,
            deleteNoteUseCase,
            searchNotesUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CreateNoteViewModel(
            createNoteFromTextUseCase,
            createNoteFromImageUseCase,
            createNoteFromPdfUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NoteDetailViewModel(
            getNoteByIdUseCase,
            getSummariesForNoteUseCase,
            getFlashcardsForNoteUseCase,
            pdfExportService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NoteEditorViewModel(
            richTextService,
            drawingService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'SaaraNote',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
