import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_components.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/services/document_indexing_service.dart';
import '../../core/services/offline_qa_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/retrieval_service.dart';
import '../../domain/entities/file_metadata.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/retrieval_result.dart';
import '../../domain/repositories/file_organization_repository.dart';
import '../../domain/repositories/index_repository.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/repositories/summary_repository.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../../domain/usecases/delete_note_usecase.dart';
import '../../domain/usecases/reindex_notes_usecase.dart';
import '../../data/repositories/index_repository_impl.dart';

class DebugToolsScreen extends StatefulWidget {
  const DebugToolsScreen({super.key});

  @override
  State<DebugToolsScreen> createState() => _DebugToolsScreenState();
}

class _DebugToolsScreenState extends State<DebugToolsScreen> {
  final _picker = ImagePicker();
  final _queryController = TextEditingController();

  File? _selectedImage;
  bool _runPreprocess = true;
  bool _enableThreshold = true;
  bool _enableDenoise = true;
  bool _isOcrRunning = false;
  OcrDebugResult? _ocrResult;

  bool _isIndexLoading = false;
  _IndexDebugState? _indexState;
  String? _indexError;

  bool _isRetrievalRunning = false;
  DebugSearchResult? _debugSearch;
  DebugQaResult? _debugQa;
  String? _normalizedQuery;
  String? _orQuery;
  String? _retrievalError;

  bool _isSelfTestRunning = false;
  _DiagnosticResult? _diagnosticResult;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debug Tools'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'OCR'),
              Tab(text: 'Index'),
              Tab(text: 'Retrieval'),
              Tab(text: 'Self-Test'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOcrTab(context),
            _buildIndexTab(context),
            _buildRetrievalTab(context),
            _buildSelfTestTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOcrTab(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
      children: [
        AppInfoBanner(
          message: 'Runs OCR on original and preprocessed images for comparison.',
          icon: Icons.image_search,
        ),
        AppSpacing.vGapLg,
        AppSectionHeader(
          title: 'Input',
          action: TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Select image'),
          ),
        ),
        if (_selectedImage != null) ...[
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusMd,
            child: Image.file(
              _selectedImage!,
              fit: BoxFit.contain,
            ),
          ),
        ] else ...[
          AppEmptyState(
            icon: Icons.image_outlined,
            title: 'No image selected',
            message: 'Pick a handwritten image to test OCR.',
          ),
        ],
        AppSpacing.vGapLg,
        AppSectionHeader(title: 'Options'),
        SwitchListTile(
          title: const Text('Run preprocessing'),
          subtitle: const Text('Compare original vs preprocessed output'),
          value: _runPreprocess,
          onChanged: (value) => setState(() => _runPreprocess = value),
        ),
        SwitchListTile(
          title: const Text('Enable thresholding'),
          subtitle: const Text('May hurt handwriting if too aggressive'),
          value: _enableThreshold,
          onChanged: (value) => setState(() => _enableThreshold = value),
        ),
        SwitchListTile(
          title: const Text('Enable denoise'),
          subtitle: const Text('Can blur faint handwriting'),
          value: _enableDenoise,
          onChanged: (value) => setState(() => _enableDenoise = value),
        ),
        AppSpacing.vGapMd,
        ElevatedButton.icon(
          onPressed: _isOcrRunning ? null : _runOcrDebug,
          icon: _isOcrRunning
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(_isOcrRunning ? 'Running OCR...' : 'Run OCR'),
        ),
        if (_ocrResult != null) ...[
          AppSpacing.vGapLg,
          _buildOcrResultCard(theme, _ocrResult!),
        ],
      ],
    );
  }

  Widget _buildOcrResultCard(ThemeData theme, OcrDebugResult result) {
    return AppCard(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OCR Summary', style: theme.textTheme.titleMedium),
          AppSpacing.vGapSm,
          _buildStatRow('Selected source', result.selectedSource),
          _buildStatRow(
            'Selected confidence',
            result.selectedConfidence?.toStringAsFixed(3) ?? 'n/a',
          ),
          _buildStatRow('Word count', result.wordCount.toString()),
          _buildStatRow('Preprocessing used', result.preprocessingUsed ? 'Yes' : 'No'),
          AppSpacing.vGapMd,
          _buildOcrBlock('Original OCR', result.originalText, result.originalConfidence,
              result.originalDurationMs),
          AppSpacing.vGapMd,
          _buildOcrBlock('Preprocessed OCR', result.preprocessedText,
              result.preprocessedConfidence, result.preprocessedDurationMs),
          AppSpacing.vGapMd,
          _buildOcrBlock('Cleaned Text', result.cleanedText, null, null),
        ],
      ),
    );
  }

  Widget _buildOcrBlock(
    String title,
    String text,
    double? confidence,
    int? durationMs,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const Spacer(),
            if (confidence != null)
              Text('Conf: ${confidence.toStringAsFixed(3)}',
                  style: theme.textTheme.bodySmall),
            if (durationMs != null) ...[
              AppSpacing.hGapSm,
              Text('${durationMs}ms', style: theme.textTheme.bodySmall),
            ],
          ],
        ),
        AppSpacing.vGapXs,
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingSm,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
          ),
          child: SelectableText(
            text.isEmpty ? 'No text extracted.' : text,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildIndexTab(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
      children: [
        AppInfoBanner(
          message: 'View index stats and rebuild the index if needed.',
          icon: Icons.storage_outlined,
        ),
        AppSpacing.vGapLg,
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isIndexLoading ? null : _loadIndexStats,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh stats'),
            ),
            AppSpacing.hGapSm,
            OutlinedButton.icon(
              onPressed: _isIndexLoading ? null : _rebuildIndex,
              icon: const Icon(Icons.replay_outlined, size: 18),
              label: const Text('Rebuild index'),
            ),
          ],
        ),
        if (_indexError != null) ...[
          AppSpacing.vGapSm,
          AppInfoBanner(
            message: _indexError!,
            icon: Icons.error_outline,
            backgroundColor: theme.colorScheme.errorContainer,
            textColor: theme.colorScheme.onErrorContainer,
          ),
        ],
        AppSpacing.vGapMd,
        if (_isIndexLoading)
          const AppLoadingIndicator(message: 'Loading index stats...')
        else if (_indexState != null)
          _buildIndexStats(theme, _indexState!)
        else
          const AppEmptyState(
            icon: Icons.storage_outlined,
            title: 'No stats yet',
            message: 'Tap refresh to load indexing details.',
          ),
      ],
    );
  }

  Widget _buildIndexStats(ThemeData theme, _IndexDebugState state) {
    return AppCard(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Index Summary', style: theme.textTheme.titleMedium),
          AppSpacing.vGapSm,
          _buildStatRow('Total files', state.totalFiles.toString()),
          _buildStatRow('Indexed notes', state.totalNotes.toString()),
          _buildStatRow('Total chunks', state.totalChunks.toString()),
          _buildStatRow(
            'FTS rows',
            state.ftsRowCount >= 0 ? state.ftsRowCount.toString() : 'Unavailable',
          ),
          _buildStatRow('Last note id', state.lastNoteId ?? 'n/a'),
          _buildStatRow('Last chunk count', state.lastChunkCount.toString()),
          AppSpacing.vGapMd,
          Text('Chunk previews', style: theme.textTheme.titleSmall),
          AppSpacing.vGapXs,
          if (state.chunkPreviews.isEmpty)
            Text('No chunks available.', style: theme.textTheme.bodySmall)
          else
            Column(
              children: state.chunkPreviews
                  .map((preview) => Padding(
                        padding: AppSpacing.verticalXs,
                        child: Container(
                          width: double.infinity,
                          padding: AppSpacing.paddingSm,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: AppSpacing.borderRadiusSm,
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(preview, style: theme.textTheme.bodySmall),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRetrievalTab(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
      children: [
        AppInfoBanner(
          message: 'Test query normalization, FTS matches, and QA output.',
          icon: Icons.search,
        ),
        AppSpacing.vGapLg,
        TextField(
          controller: _queryController,
          decoration: const InputDecoration(
            labelText: 'Query',
            hintText: 'Ticket, refund, Paytm',
          ),
        ),
        AppSpacing.vGapMd,
        ElevatedButton.icon(
          onPressed: _isRetrievalRunning ? null : _runRetrievalDebug,
          icon: const Icon(Icons.play_arrow, size: 18),
          label: Text(_isRetrievalRunning ? 'Running...' : 'Run query'),
        ),
        if (_retrievalError != null) ...[
          AppSpacing.vGapSm,
          AppInfoBanner(
            message: _retrievalError!,
            icon: Icons.error_outline,
            backgroundColor: theme.colorScheme.errorContainer,
            textColor: theme.colorScheme.onErrorContainer,
          ),
        ],
        AppSpacing.vGapMd,
        if (_isRetrievalRunning)
          const AppLoadingIndicator(message: 'Running retrieval...')
        else if (_debugQa != null)
          _buildRetrievalResults(theme)
        else
          const AppEmptyState(
            icon: Icons.search_off,
            title: 'No retrieval run',
            message: 'Enter a query and run diagnostics.',
          ),
      ],
    );
  }

  Widget _buildRetrievalResults(ThemeData theme) {
    final qa = _debugQa!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: AppSpacing.paddingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Query details', style: theme.textTheme.titleMedium),
              AppSpacing.vGapSm,
              _buildStatRow('Normalized query', _normalizedQuery ?? 'n/a'),
              _buildStatRow('OR query', _orQuery ?? 'n/a'),
              _buildStatRow('Expanded query', qa.expandedQuery),
            ],
          ),
        ),
        AppSpacing.vGapLg,
        if (_debugSearch != null)
          AppCard(
            padding: AppSpacing.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FTS vs LIKE', style: theme.textTheme.titleMedium),
                AppSpacing.vGapSm,
                _buildStatRow(
                  'FTS available',
                  _debugSearch!.ftsAvailable ? 'Yes' : 'No',
                ),
                if (_debugSearch!.ftsError != null)
                  Text(
                    _debugSearch!.ftsError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                _buildStatRow(
                  'FTS matches',
                  _debugSearch!.ftsResults.length.toString(),
                ),
                _buildStatRow(
                  'LIKE matches',
                  _debugSearch!.likeResults.length.toString(),
                ),
              ],
            ),
          ),
        AppSpacing.vGapLg,
        _buildResultList(theme, 'Top reranked', qa.reranked),
        AppSpacing.vGapLg,
        _buildResultList(theme, 'Final context', qa.context),
        AppSpacing.vGapLg,
        AppCard(
          padding: AppSpacing.paddingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Final AI answer', style: theme.textTheme.titleMedium),
              AppSpacing.vGapSm,
              SelectableText(
                qa.answer,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultList(
    ThemeData theme,
    String title,
    List<RetrievalResult> results,
  ) {
    return AppCard(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          AppSpacing.vGapSm,
          if (results.isEmpty)
            Text('No results.', style: theme.textTheme.bodySmall)
          else
            Column(
              children: results.take(5).map((result) {
                final preview = _preview(result.chunk.content);
                return Padding(
                  padding: AppSpacing.verticalXs,
                  child: Container(
                    width: double.infinity,
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'score=${result.score.toStringAsFixed(3)}  $preview',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSelfTestTab(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
      children: [
        AppInfoBanner(
          message: 'Creates a temporary note, indexes it, and tests retrieval/QA.',
          icon: Icons.bug_report_outlined,
        ),
        AppSpacing.vGapLg,
        ElevatedButton.icon(
          onPressed: _isSelfTestRunning ? null : _runDiagnostics,
          icon: const Icon(Icons.play_circle_outline, size: 18),
          label: Text(_isSelfTestRunning ? 'Running diagnostics...' : 'Run Diagnostic'),
        ),
        AppSpacing.vGapMd,
        if (_isSelfTestRunning)
          const AppLoadingIndicator(message: 'Running diagnostics...')
        else if (_diagnosticResult != null)
          _buildDiagnosticResult(theme, _diagnosticResult!)
        else
          const AppEmptyState(
            icon: Icons.checklist_outlined,
            title: 'No diagnostics yet',
            message: 'Run the diagnostic to validate OCR and retrieval.',
          ),
      ],
    );
  }

  Widget _buildDiagnosticResult(ThemeData theme, _DiagnosticResult result) {
    return AppCard(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagnostic Results', style: theme.textTheme.titleMedium),
          AppSpacing.vGapSm,
          _buildStatusRow('OCR', result.ocrPass, result.ocrNote),
          _buildStatusRow('Indexing', result.indexPass, result.indexNote),
          _buildStatusRow('Retrieval', result.retrievalPass, result.retrievalNote),
          _buildStatusRow('QA Answer', result.qaPass, result.qaNote),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool pass, String note) {
    final theme = Theme.of(context);
    final color = pass ? Colors.green : theme.colorScheme.error;
    return Padding(
      padding: AppSpacing.verticalXs,
      child: Row(
        children: [
          Icon(pass ? Icons.check_circle : Icons.cancel, color: color, size: 18),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              '$label: ${pass ? 'PASS' : 'FAIL'}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: AppSpacing.verticalXs,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _ocrResult = null;
    });
  }

  Future<void> _runOcrDebug() async {
    if (_selectedImage == null) return;
    final ocrService = context.read<OcrService>();

    setState(() => _isOcrRunning = true);
    final result = await ocrService.debugAnalyzeImage(
      _selectedImage!,
      runPreprocessing: _runPreprocess,
      enableThresholdingOverride: _enableThreshold,
      enableDenoiseOverride: _enableDenoise,
    );
    setState(() {
      _ocrResult = result;
      _isOcrRunning = false;
    });
  }

  Future<void> _loadIndexStats() async {
    setState(() {
      _isIndexLoading = true;
      _indexError = null;
    });

    try {
      final indexRepository = context.read<IndexRepository>();
      final fileRepo = context.read<FileOrganizationRepository>();
      final stats = await indexRepository.getIndexStats();
      final totalChunks = stats['totalChunks'] as int? ?? 0;
      final files = await fileRepo.getAllFiles();
      final totalFiles = files.length;
      final totalNotes = files.where((file) => file.fileType == FileType.note).length;

      String? lastNoteId;
      int lastChunkCount = 0;
      final chunkPreviews = <String>[];
      int ftsRowCount = -1;

      if (indexRepository is IndexRepositoryImpl) {
        ftsRowCount = await indexRepository.getFtsCount();
      }

      if (files.isNotEmpty) {
        final latest = files.first;
        lastNoteId = latest.relatedNoteId;
        final chunks = await indexRepository.getChunksByFileId(latest.id!);
        lastChunkCount = chunks.length;
        for (final chunk in chunks.take(3)) {
          chunkPreviews.add(_preview(chunk.content));
        }
      }

      setState(() {
        _indexState = _IndexDebugState(
          totalFiles: totalFiles,
          totalNotes: totalNotes,
          totalChunks: totalChunks,
          lastNoteId: lastNoteId,
          lastChunkCount: lastChunkCount,
          chunkPreviews: chunkPreviews,
          ftsRowCount: ftsRowCount,
        );
      });
    } catch (e) {
      setState(() => _indexError = 'Failed to load index stats: ${e.toString()}');
    } finally {
      setState(() => _isIndexLoading = false);
    }
  }

  Future<void> _rebuildIndex() async {
    setState(() {
      _isIndexLoading = true;
      _indexError = null;
    });
    try {
      final noteRepo = context.read<NoteRepository>();
      final indexing = context.read<DocumentIndexingService>();
      final reindex = ReindexNotesUseCase(noteRepo, indexing);
      await reindex.execute();
      await _loadIndexStats();
    } catch (e) {
      setState(() => _indexError = 'Reindex failed: ${e.toString()}');
    } finally {
      setState(() => _isIndexLoading = false);
    }
  }

  Future<void> _runRetrievalDebug() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isRetrievalRunning = true;
      _retrievalError = null;
      _debugSearch = null;
      _debugQa = null;
      _normalizedQuery = null;
      _orQuery = null;
    });

    try {
      final retrieval = context.read<RetrievalService>();
      final offlineQa = context.read<OfflineQaService>();
      final indexRepository = context.read<IndexRepository>();

      final normalized = retrieval.debugNormalizeQuery(query);
      final orQuery = retrieval.debugOrQuery(normalized);
      DebugSearchResult? debugSearch;
      if (indexRepository is IndexRepositoryImpl) {
        debugSearch = await indexRepository.debugSearch(normalized, 5);
      }
      final qa = await offlineQa.debugAnswer(query: query);

      setState(() {
        _normalizedQuery = normalized;
        _orQuery = orQuery;
        _debugSearch = debugSearch;
        _debugQa = qa;
      });
    } catch (e) {
      setState(() => _retrievalError = 'Retrieval failed: ${e.toString()}');
    } finally {
      setState(() => _isRetrievalRunning = false);
    }
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isSelfTestRunning = true;
      _diagnosticResult = null;
    });

    final noteRepo = context.read<NoteRepository>();
    final summaryRepo = context.read<SummaryRepository>();
    final flashcardRepo = context.read<FlashcardRepository>();
    final fileRepo = context.read<FileOrganizationRepository>();
    final indexRepo = context.read<IndexRepository>();
    final indexing = context.read<DocumentIndexingService>();
    final offlineQa = context.read<OfflineQaService>();
    final ocrService = context.read<OcrService>();

    Note? tempNote;
    try {
      const content =
          'Operator Bus Paytm Ticket refund amount 120 cancellation policy. '
          'JavaScript browser AJAX example.';
      final note = Note(
        title: '[DEBUG] Retrieval Test',
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      tempNote = await noteRepo.create(note);

      await indexing.indexNoteContent(
        noteId: tempNote.id!,
        title: tempNote.title,
        content: tempNote.content,
        fileType: FileType.note,
      );

      final metadata = await fileRepo.getFileByRelatedNoteId(tempNote.id!.toString());
      final chunks = metadata?.id != null
          ? await indexRepo.getChunksByFileId(metadata!.id!)
          : <dynamic>[];
      final indexPass = chunks.isNotEmpty;

      final qa = await offlineQa.debugAnswer(query: 'Paytm');
      final retrievalPass = qa.context.isNotEmpty;
      final qaPass = !qa.answer.toLowerCase().contains('no relevant information');

      bool ocrPass = false;
      String ocrNote = 'Skipped';
      if (_selectedImage != null) {
        final ocr = await ocrService.debugAnalyzeImage(
          _selectedImage!,
          runPreprocessing: _runPreprocess,
          enableThresholdingOverride: _enableThreshold,
          enableDenoiseOverride: _enableDenoise,
        );
        ocrPass = ocr.selectedText.trim().isNotEmpty;
        ocrNote = ocrPass ? 'OK' : 'Empty OCR';
      }

      setState(() {
        _diagnosticResult = _DiagnosticResult(
          ocrPass: ocrPass,
          indexPass: indexPass,
          retrievalPass: retrievalPass,
          qaPass: qaPass,
          ocrNote: ocrNote,
          indexNote: indexPass ? 'Chunks=${chunks.length}' : 'No chunks',
          retrievalNote: retrievalPass ? 'Context=${qa.context.length}' : 'Empty',
          qaNote: qaPass ? 'Answer OK' : 'No answer',
        );
      });
    } catch (e) {
      setState(() {
        _diagnosticResult = _DiagnosticResult(
          ocrPass: false,
          indexPass: false,
          retrievalPass: false,
          qaPass: false,
          ocrNote: 'Error',
          indexNote: 'Error',
          retrievalNote: 'Error',
          qaNote: e.toString(),
        );
      });
    } finally {
      if (tempNote?.id != null) {
        final deleteUseCase = DeleteNoteUseCase(
          noteRepo,
          summaryRepo,
          flashcardRepo,
          fileOrganizationRepository: fileRepo,
          indexRepository: indexRepo,
        );
        try {
          await deleteUseCase.execute(tempNote!.id!);
        } catch (_) {
          // Leave debug note if cleanup fails.
        }
      }
      setState(() => _isSelfTestRunning = false);
    }
  }

  String _preview(String text) {
    final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= 90) return collapsed;
    return '${collapsed.substring(0, 90)}...';
  }
}

class _IndexDebugState {
  final int totalFiles;
  final int totalNotes;
  final int totalChunks;
  final String? lastNoteId;
  final int lastChunkCount;
  final List<String> chunkPreviews;
  final int ftsRowCount;

  const _IndexDebugState({
    required this.totalFiles,
    required this.totalNotes,
    required this.totalChunks,
    required this.lastNoteId,
    required this.lastChunkCount,
    required this.chunkPreviews,
    required this.ftsRowCount,
  });
}

class _DiagnosticResult {
  final bool ocrPass;
  final bool indexPass;
  final bool retrievalPass;
  final bool qaPass;
  final String ocrNote;
  final String indexNote;
  final String retrievalNote;
  final String qaNote;

  const _DiagnosticResult({
    required this.ocrPass,
    required this.indexPass,
    required this.retrievalPass,
    required this.qaPass,
    required this.ocrNote,
    required this.indexNote,
    required this.retrievalNote,
    required this.qaNote,
  });
}
