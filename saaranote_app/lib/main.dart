import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Design system
import 'core/design_system/app_theme.dart';

// Data layer
import 'data/datasources/local/database_helper.dart';
import 'data/datasources/local/drawing_local_data_source.dart';
import 'data/repositories/note_repository_impl.dart';
import 'data/repositories/summary_repository_impl.dart';
import 'data/repositories/flashcard_repository_impl.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/index_repository_impl.dart';

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
import 'domain/usecases/ask_question_usecase.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/index_repository.dart';

// Core services
import 'core/services/ocr_service.dart';
import 'core/services/pdf_export_service.dart';
import 'core/services/pdf_text_service.dart';
import 'core/services/rich_text_service.dart';
import 'core/services/drawing_service.dart';
import 'core/services/retrieval_service.dart';
import 'core/services/generation_service.dart';
import 'core/services/offline_qa_service.dart';
import 'core/ai_engine.dart';

// Presentation layer
import 'presentation/viewmodels/note_viewmodel.dart';
import 'presentation/viewmodels/create_note_viewmodel.dart';
import 'presentation/viewmodels/note_detail_viewmodel.dart';
import 'presentation/viewmodels/note_editor_viewmodel.dart';
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
    final chatRepository = ChatRepositoryImpl(databaseHelper);
    final indexRepository = IndexRepositoryImpl(databaseHelper);
    
    // Services
    final ocrService = OcrService();
    final pdfExportService = PdfExportService();
    final pdfTextService = PdfTextService(ocrService);
    final richTextService = RichTextService();
    final drawingService = DrawingService();
    final drawingLocalDataSource = DrawingLocalDataSource(databaseHelper, drawingService);
    final aiEngine = AIEngine();
    final retrievalService = RetrievalService(indexRepository);
    final queryProcessor = QueryProcessor();
    final generationService = GenerationService();
    final offlineQaService = OfflineQaService(
      retrievalService: retrievalService,
      queryProcessor: queryProcessor,
    );
    
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
      aiEngine,
    );
    final createNoteFromImageUseCase = CreateNoteFromImageUseCase(
      noteRepository,
      summaryRepository,
      flashcardRepository,
      ocrService,
      aiEngine,
    );
    final createNoteFromPdfUseCase = CreateNoteFromPdfUseCase(
      noteRepository,
      summaryRepository,
      flashcardRepository,
      pdfTextService,
      aiEngine,
    );
    final getSummariesForNoteUseCase = GetSummariesForNoteUseCase(summaryRepository);
    final getFlashcardsForNoteUseCase = GetFlashcardsForNoteUseCase(flashcardRepository);
    final searchNotesUseCase = SearchNotesUseCase(noteRepository);
    final askQuestionUseCase = AskQuestionUseCase(
      chatRepository: chatRepository,
      retrievalService: retrievalService,
      generationService: generationService,
      queryProcessor: queryProcessor,
      offlineQaService: offlineQaService,
    );

    return MultiProvider(
      providers: [
        Provider<ChatRepository>.value(value: chatRepository),
        Provider<IndexRepository>.value(value: indexRepository),
        Provider<RetrievalService>.value(value: retrievalService),
        Provider<QueryProcessor>.value(value: queryProcessor),
        Provider<GenerationService>.value(value: generationService),
        Provider<OfflineQaService>.value(value: offlineQaService),
        Provider<AskQuestionUseCase>.value(value: askQuestionUseCase),
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
            drawingLocalDataSource,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NoteDetailViewModel(
            getNoteByIdUseCase,
            getSummariesForNoteUseCase,
            getFlashcardsForNoteUseCase,
            pdfExportService,
            drawingLocalDataSource,
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
