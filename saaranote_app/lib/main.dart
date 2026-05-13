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
import 'data/repositories/file_organization_repository_impl.dart';

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
import 'domain/usecases/get_source_file_for_note_usecase.dart';
import 'domain/usecases/search_notes_usecase.dart';
import 'domain/usecases/ask_question_usecase.dart';
import 'domain/usecases/reindex_notes_usecase.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/index_repository.dart';
import 'domain/repositories/note_repository.dart';
import 'domain/repositories/summary_repository.dart';
import 'domain/repositories/flashcard_repository.dart';
import 'domain/repositories/file_organization_repository.dart';

// Core services
import 'core/services/ocr_service.dart';
import 'core/services/pdf_export_service.dart';
import 'core/services/pdf_text_service.dart';
import 'core/services/rich_text_service.dart';
import 'core/services/drawing_service.dart';
import 'core/services/retrieval_service.dart';
import 'core/services/generation_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/offline_qa_service.dart';
import 'core/services/llm_service.dart';
import 'core/services/hybrid_summary_service.dart';
import 'core/services/document_indexing_service.dart';
import 'core/services/source_file_service.dart';
import 'core/ai_engine.dart';

// Presentation layer
import 'presentation/viewmodels/note_viewmodel.dart';
import 'presentation/viewmodels/create_note_viewmodel.dart';
import 'presentation/viewmodels/note_detail_viewmodel.dart';
import 'presentation/viewmodels/note_editor_viewmodel.dart';
import 'presentation/viewmodels/chat_viewmodel.dart';
import 'presentation/viewmodels/settings_viewmodel.dart';
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
    final fileOrganizationRepository = FileOrganizationRepositoryImpl(databaseHelper);

    // Services
    final ocrService = OcrService();
    final pdfExportService = PdfExportService();
    final pdfTextService = PdfTextService(ocrService);
    final richTextService = RichTextService();
    final drawingService = DrawingService();
    final drawingLocalDataSource = DrawingLocalDataSource(
      databaseHelper,
      drawingService,
    );
    final sourceFileService = SourceFileService();
    final aiEngine = AIEngine();
    final llmService = LlmService();
    final hybridSummaryService = HybridSummaryService(llmService);
    final documentIndexingService = DocumentIndexingService(
      indexRepository,
      fileOrganizationRepository,
    );
    final retrievalService = RetrievalService(indexRepository);
    final queryProcessor = QueryProcessor();
    final generationService = GenerationService(aiEngine: aiEngine);
    final offlineQaService = OfflineQaService(
      retrievalService: retrievalService,
      queryProcessor: queryProcessor,
      aiEngine: aiEngine,
    );
    final settingsService = SettingsService();

    // Use cases
    final getAllNotesUseCase = GetAllNotesUseCase(noteRepository);
    final getNoteByIdUseCase = GetNoteByIdUseCase(noteRepository);
    final updateNoteUseCase = UpdateNoteUseCase(
      noteRepository,
      documentIndexingService,
    );
    final deleteNoteUseCase = DeleteNoteUseCase(
      noteRepository,
      summaryRepository,
      flashcardRepository,
      fileOrganizationRepository: fileOrganizationRepository,
      indexRepository: indexRepository,
    );
    final createNoteFromTextUseCase = CreateNoteFromTextUseCase(
      noteRepository,
      summaryRepository,
      flashcardRepository,
      aiEngine,
      hybridSummaryService,
      documentIndexingService,
    );
    final createNoteFromImageUseCase = CreateNoteFromImageUseCase(
      noteRepository,
      summaryRepository,
      flashcardRepository,
      ocrService,
      aiEngine,
      hybridSummaryService,
      documentIndexingService,
      sourceFileService,
    );
    final createNoteFromPdfUseCase = CreateNoteFromPdfUseCase(
      noteRepository,
      summaryRepository,
      flashcardRepository,
      pdfTextService,
      aiEngine,
      hybridSummaryService,
      documentIndexingService,
      sourceFileService,
    );
    final getSummariesForNoteUseCase = GetSummariesForNoteUseCase(summaryRepository);
    final getFlashcardsForNoteUseCase = GetFlashcardsForNoteUseCase(flashcardRepository);
    final getSourceFileForNoteUseCase = GetSourceFileForNoteUseCase(
      fileOrganizationRepository,
    );
    final searchNotesUseCase = SearchNotesUseCase(noteRepository);
    final askQuestionUseCase = AskQuestionUseCase(
      chatRepository: chatRepository,
      retrievalService: retrievalService,
      generationService: generationService,
      queryProcessor: queryProcessor,
      offlineQaService: offlineQaService,
      indexRepository: indexRepository,
      reindexNotesUseCase: ReindexNotesUseCase(
        noteRepository,
        documentIndexingService,
      ),
    );

    return MultiProvider(
      providers: [
        Provider<OcrService>.value(value: ocrService),
        Provider<DocumentIndexingService>.value(value: documentIndexingService),
        Provider<NoteRepository>.value(value: noteRepository),
        Provider<SummaryRepository>.value(value: summaryRepository),
        Provider<FlashcardRepository>.value(value: flashcardRepository),
        Provider<FileOrganizationRepository>.value(value: fileOrganizationRepository),
        Provider<ChatRepository>.value(value: chatRepository),
        Provider<IndexRepository>.value(value: indexRepository),
        Provider<RetrievalService>.value(value: retrievalService),
        Provider<QueryProcessor>.value(value: queryProcessor),
        Provider<GenerationService>.value(value: generationService),
        Provider<OfflineQaService>.value(value: offlineQaService),
        Provider<AskQuestionUseCase>.value(value: askQuestionUseCase),
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
            getSourceFileForNoteUseCase,
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
        ChangeNotifierProvider(
          create: (_) => ChatViewModel(
            chatRepository,
            askQuestionUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(settingsService)..load(),
        ),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'SaaraNote',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: settings.themeMode,
            builder: (context, appChild) {
              final data = MediaQuery.of(context);
              return MediaQuery(
                data: data.copyWith(textScaler: TextScaler.linear(settings.textScale)),
                child: appChild ?? const SizedBox.shrink(),
              );
            },
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}