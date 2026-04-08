import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/note_detail_viewmodel.dart';
import '../../domain/entities/drawing.dart';
import '../../domain/entities/rich_text_content.dart' as domain;
import '../../core/design_system/app_components.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';

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
                  Text(
                    note.title,
                    style: AppTypography.h1(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  AppSpacing.vGapSm,

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

                  _buildSection(
                    title: 'Content',
                    icon: Icons.article,
                    child: note.hasRichContent
                        ? SelectableText.rich(
                            _buildRichTextSpan(note.richContent!, contentStyle),
                          )
                        : SelectableText(
                            note.content,
                            style: contentStyle,
                          ),
                  ),

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
                      ),
                    ),
                  ],

                  if (viewModel.hasSummaries) ...[
                    AppSpacing.vGapLg,
                    _buildSection(
                      title: 'Summary',
                      icon: Icons.description,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: viewModel.summaries.map((summary) {
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
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

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
    await viewModel.exportNoteAsPdf();

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
    return AppCard(
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

  TextSpan _buildRichTextSpan(
    domain.RichTextContent content,
    TextStyle baseStyle,
  ) {
    if (content.spans.isEmpty) {
      return TextSpan(text: content.plainText, style: baseStyle);
    }

    final spans = <TextSpan>[];
    int current = 0;

    for (final span in content.spans) {
      if (span.start > current) {
        spans.add(TextSpan(
          text: content.plainText.substring(current, span.start),
          style: baseStyle,
        ));
      }

      final style = _buildTextStyle(span.style, baseStyle);
      spans.add(TextSpan(
        text: content.plainText.substring(span.start, span.end),
        style: style,
      ));
      current = span.end;
    }

    if (current < content.plainText.length) {
      spans.add(TextSpan(
        text: content.plainText.substring(current),
        style: baseStyle,
      ));
    }

    return TextSpan(style: baseStyle, children: spans);
  }

  TextStyle _buildTextStyle(domain.TextStyle style, TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontWeight: style.bold ? FontWeight.w600 : baseStyle.fontWeight,
      fontStyle: style.italic ? FontStyle.italic : baseStyle.fontStyle,
      decoration: style.underline ? TextDecoration.underline : baseStyle.decoration,
      fontSize: style.fontSize ?? baseStyle.fontSize,
      color: style.textColor != null ? _parseHexColor(style.textColor!) : baseStyle.color,
      backgroundColor: style.highlightColor != null
          ? _parseHexColor(style.highlightColor!)
          : baseStyle.backgroundColor,
    );
  }

  Color _parseHexColor(String value) {
    final hex = value.replaceFirst('#', '');
    final colorValue = int.parse(hex, radix: 16);
    return Color(0xFF000000 | colorValue);
  }
}

class _DrawingPreviewPainter extends CustomPainter {
  final Drawing drawing;

  _DrawingPreviewPainter({
    required this.drawing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final stroke in drawing.strokes) {
      _drawStroke(canvas, stroke);
    }
    canvas.restore();
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.style.width;

    final colorHex = stroke.style.color.replaceFirst('#', '');
    final colorValue = int.parse(colorHex, radix: 16);
    final baseColor = Color(0xFF000000 | colorValue);

    paint.color = baseColor.withOpacity(stroke.style.opacity);

    switch (stroke.style.type) {
      case StrokeType.pen:
        break;
      case StrokeType.highlighter:
        paint.strokeWidth = stroke.style.width * 1.5;
        paint.color = paint.color.withOpacity(0.4);
        break;
      case StrokeType.eraser:
        paint.color = Colors.white;
        paint.blendMode = BlendMode.clear;
        break;
    }

    final path = Path();
    if (stroke.points.length == 1) {
      final point = stroke.points.first;
      canvas.drawCircle(
        Offset(point.x, point.y),
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
    } else {
      path.moveTo(stroke.points.first.x, stroke.points.first.y);

      for (int i = 1; i < stroke.points.length - 1; i++) {
        final current = stroke.points[i];
        final next = stroke.points[i + 1];

        final controlX = (current.x + next.x) / 2;
        final controlY = (current.y + next.y) / 2;

        path.quadraticBezierTo(
          current.x,
          current.y,
          controlX,
          controlY,
        );
      }

      final lastPoint = stroke.points.last;
      path.lineTo(lastPoint.x, lastPoint.y);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPreviewPainter oldDelegate) {
    return oldDelegate.drawing.id != drawing.id ||
        oldDelegate.drawing.totalPoints != drawing.totalPoints;
  }
}
