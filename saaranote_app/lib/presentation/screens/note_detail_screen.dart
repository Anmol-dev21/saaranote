import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/note_detail_viewmodel.dart';
import '../utils/summary_parser.dart';
import '../../core/services/summary_state_labels.dart';
import '../../core/services/summary_generation_state.dart';

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

          return RefreshIndicator(
            onRefresh: () => viewModel.refresh(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note Title
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Metadata
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(note.updatedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (viewModel.hasSummaries) ...[
                        Icon(Icons.description, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${viewModel.summaryCount} summary',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(width: 16),
                      if (viewModel.hasFlashcards) ...[
                        Icon(Icons.psychology, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${viewModel.flashcardCount} cards',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Divider(height: 32),
                  
                  // Note Content
                  _buildSection(
                    title: 'Content',
                    icon: Icons.article,
                    child: SelectableText(
                      note.content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  // Summary Section
                  if (viewModel.hasSummaries) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Summary',
                      icon: Icons.description,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: viewModel.summaries.map((summary) {
                          return _buildSummaryCard(summary.summaryText, summary.generationState);
                        }).toList(),
                      ),
                    ),
                  ],
                  
                  // Flashcards Section
                  if (viewModel.hasFlashcards) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Flashcards',
                      icon: Icons.psychology,
                      child: Column(
                        children: viewModel.flashcards.map((flashcard) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Text(
                                flashcard.question,
                                style: const TextStyle(
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
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Answer:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        flashcard.answer,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      if (flashcard.lastReviewedAt != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Last reviewed: ${_formatDate(flashcard.lastReviewedAt!)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
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
    if (!context.mounted) return;
    
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildSummaryCard(String summaryText, String? generationStateStr) {
    final parsed = SummaryParser.parse(summaryText);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Parse the stored generation state string back to enum
    final state = SummaryStateLabels.fromString(generationStateStr);
    final isAiEnhanced = state == SummaryGenerationState.aiEnhanced;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAiEnhanced && parsed.isValid)
            _buildAiEnhancedLabel(state!)
          else
            _buildFallbackBanner(state),
          const SizedBox(height: 8),
          if (parsed.isValid)
            _buildStructuredSummary(parsed)
          else
            SelectableText(
              summaryText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiEnhancedLabel(SummaryGenerationState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.secondary),
        ),
        child: Text(
          SummaryStateLabels.title(state),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBanner(SummaryGenerationState? state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayState = state ?? SummaryGenerationState.fallback;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SummaryStateLabels.title(displayState),
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2),
          Text(
            SummaryStateLabels.subtitle(displayState),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredSummary(SummaryParseResult parsed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          parsed.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          parsed.summary,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Key Points',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: parsed.keyPoints.map((point) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
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
