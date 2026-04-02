import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/note_detail_viewmodel.dart';
<<<<<<< Updated upstream
=======
import '../../domain/entities/drawing.dart';
import '../../domain/entities/rich_text_content.dart' as domain;
import '../../core/design_system/app_components.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
>>>>>>> Stashed changes

/// Screen displaying note details with summaries and flashcards
class NoteDetailScreen extends StatefulWidget {
  final int noteId;

  const NoteDetailScreen({
    super.key,
    required this.noteId,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load note details when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteDetailViewModel>().loadNoteDetails(widget.noteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Details'),
        actions: [
          Consumer<NoteDetailViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: viewModel.isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                onPressed: viewModel.isExporting ? null : () => _handleExportPdf(context),
                tooltip: 'Export as PDF',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<NoteDetailViewModel>().refresh(),
          ),
        ],
      ),
      body: Consumer<NoteDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage ?? 'An error occurred',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => viewModel.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!viewModel.hasNote) {
            return const Center(
              child: Text('Note not found'),
            );
          }

          final note = viewModel.note!;
          final contentStyle = AppTypography.body(
            color: theme.colorScheme.onSurface,
          );

          return RefreshIndicator(
            onRefresh: () => viewModel.refresh(),
            child: SingleChildScrollView(
              padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note Title
                  Text(
                    note.title,
                    style: AppTypography.h1(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  
                  // Metadata
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _buildMetaPill(
                        icon: Icons.access_time,
                        label: _formatDate(note.updatedAt),
                      ),
                      if (viewModel.hasSummaries)
                        _buildMetaPill(
                          icon: Icons.description,
                          label: '${viewModel.summaryCount} summary',
                        ),
                      if (viewModel.hasFlashcards)
                        _buildMetaPill(
                          icon: Icons.psychology,
                          label: '${viewModel.flashcardCount} cards',
                        ),
                    ],
                  ),
                  AppSpacing.vGapLg,
                  
                  // Note Content
                  _buildSection(
                    title: 'Content',
                    icon: Icons.article,
<<<<<<< Updated upstream
                    child: SelectableText(
                      note.content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
=======
                    child: note.hasRichContent
                        ? SelectableText.rich(
                            _buildRichTextSpan(note.richContent!, contentStyle),
                          )
                        : SelectableText(
                            note.content,
                            style: contentStyle,
                          ),
                  ),

                  // Drawings Section
                  if (viewModel.hasDrawings) ...[
                    AppSpacing.vGapLg,
                    _buildSection(
                      title: 'Drawings',
                      icon: Icons.draw,
                      child: Column(
                        children: viewModel.drawings.map((drawing) {
                          return Padding(
                            padding: AppSpacing.verticalXs,
                            child: Container(
                              padding: AppSpacing.paddingSm,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: AppSpacing.borderRadiusMd,
                                border: Border.all(
                                  color: theme.dividerColor.withOpacity(0.4),
                                ),
                              ),
                              child: AspectRatio(
                                aspectRatio: 4 / 3,
                                child: ClipRRect(
                                  borderRadius: AppSpacing.borderRadiusSm,
                                  child: CustomPaint(
                                    painter: _DrawingPreviewPainter(drawing: drawing),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
>>>>>>> Stashed changes
                      ),
                    ),
                  ),
                  
                  // Summary Section
                  if (viewModel.hasSummaries) ...[
                    AppSpacing.vGapLg,
                    _buildSection(
                      title: 'Summary',
                      icon: Icons.description,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: viewModel.summaries.map((summary) {
<<<<<<< Updated upstream
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: SelectableText(
                              summary.summaryText,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
=======
                          return Padding(
                            padding: AppSpacing.verticalXs,
                            child: Container(
                              padding: AppSpacing.paddingMd,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: AppSpacing.borderRadiusMd,
                                border: Border.all(
                                  color: theme.dividerColor.withOpacity(0.4),
                                ),
                              ),
                              child: SelectableText(
                                summary.summaryText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                  color: theme.colorScheme.onSurface,
                                ),
>>>>>>> Stashed changes
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  
                  // Flashcards Section
                  if (viewModel.hasFlashcards) ...[
                    AppSpacing.vGapLg,
                    _buildSection(
                      title: 'Flashcards',
                      icon: Icons.psychology,
                      child: Column(
                        children: viewModel.flashcards.map((flashcard) {
                          return Padding(
                            padding: AppSpacing.verticalXs,
                            child: Card(
                              elevation: 0,
                              color: theme.colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                side: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.4),
                                ),
                              ),
                              child: ExpansionTile(
                                tilePadding: AppSpacing.paddingMd,
                                childrenPadding: AppSpacing.paddingMd,
                                title: Text(
                                  flashcard.question,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: _getConfidenceColor(flashcard.confidenceLevel),
                                  child: Text(
                                    '${flashcard.confidenceLevel}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Answer',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      AppSpacing.vGapXs,
                                      SelectableText(
                                        flashcard.answer,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      if (flashcard.lastReviewedAt != null) ...[
                                        AppSpacing.vGapSm,
                                        Text(
                                          'Last reviewed: ${_formatDate(flashcard.lastReviewedAt!)}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleExportPdf(BuildContext context) async {
    final viewModel = context.read<NoteDetailViewModel>();
    
    // Call the viewmodel to export PDF
    await viewModel.exportNoteAsPdf();
    
    // Show success or error message
    if (!mounted) return;
    
    if (viewModel.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(viewModel.errorMessage ?? 'Failed to export PDF'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (viewModel.hasPdfExport) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('PDF exported successfully'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: AppSpacing.cardContentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Text(
                    title,
                    style: AppTypography.h3(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapSm,
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaPill({
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          AppSpacing.hGapXs,
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getConfidenceColor(int level) {
    if (level >= 4) return Colors.green;
    if (level >= 2) return Colors.orange;
    return Colors.red;
  }
}
