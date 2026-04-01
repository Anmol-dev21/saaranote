import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/note_detail_viewmodel.dart';
import '../../domain/entities/drawing.dart';
import '../../domain/entities/rich_text_content.dart' as domain;

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
                    child: note.hasRichContent
                        ? SelectableText.rich(
                            _buildRichTextSpan(note.richContent!, const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            )),
                          )
                        : SelectableText(
                            note.content,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                  ),

                  // Drawings Section
                  if (viewModel.hasDrawings) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Drawings',
                      icon: Icons.draw,
                      child: Column(
                        children: viewModel.drawings.map((drawing) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outlineVariant,
                              ),
                            ),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: CustomPaint(
                                painter: _DrawingPreviewPainter(drawing: drawing),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  
                  // Summary Section
                  if (viewModel.hasSummaries) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Summary',
                      icon: Icons.description,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: viewModel.summaries.map((summary) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outlineVariant,
                              ),
                            ),
                            child: SelectableText(
                              summary.summaryText,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          );
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

  TextSpan _buildRichTextSpan(domain.RichTextContent content, TextStyle baseStyle) {
    final text = content.plainText;
    if (text.isEmpty) return TextSpan(text: '', style: baseStyle);

    final spans = content.spans.toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (spans.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final children = <TextSpan>[];
    int index = 0;

    for (final span in spans) {
      final start = span.start.clamp(0, text.length);
      final end = span.end.clamp(0, text.length);

      if (start > index) {
        children.add(TextSpan(
          text: text.substring(index, start),
          style: baseStyle,
        ));
      }

      if (end > start) {
        children.add(TextSpan(
          text: text.substring(start, end),
          style: _applySpanStyle(baseStyle, span.style),
        ));
      }

      index = end;
    }

    if (index < text.length) {
      children.add(TextSpan(
        text: text.substring(index),
        style: baseStyle,
      ));
    }

    return TextSpan(style: baseStyle, children: children);
  }

  TextStyle _applySpanStyle(TextStyle baseStyle, domain.TextStyle spanStyle) {
    return baseStyle.copyWith(
      fontWeight: spanStyle.bold ? FontWeight.bold : null,
      fontStyle: spanStyle.italic ? FontStyle.italic : null,
      decoration: spanStyle.underline ? TextDecoration.underline : null,
      fontSize: spanStyle.fontSize,
      color: _parseColor(spanStyle.textColor) ?? baseStyle.color,
      backgroundColor: _parseColor(spanStyle.highlightColor),
    );
  }

  Color? _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    final cleaned = hexColor.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}

class _DrawingPreviewPainter extends CustomPainter {
  final Drawing drawing;

  _DrawingPreviewPainter({required this.drawing});

  @override
  void paint(Canvas canvas, Size size) {
    if (drawing.strokes.isEmpty) return;

    final bounds = drawing.bounds;
    if (bounds == null || bounds.width == 0 || bounds.height == 0) return;

    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final offsetX = (size.width - bounds.width * scale) / 2 - bounds.minX * scale;
    final offsetY = (size.height - bounds.height * scale) / 2 - bounds.minY * scale;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

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
    final colorValue = int.tryParse(colorHex, radix: 16) ?? 0;
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
      return;
    }

    path.moveTo(stroke.points.first.x, stroke.points.first.y);

    for (int i = 1; i < stroke.points.length - 1; i++) {
      final current = stroke.points[i];
      final next = stroke.points[i + 1];
      final controlX = (current.x + next.x) / 2;
      final controlY = (current.y + next.y) / 2;
      path.quadraticBezierTo(current.x, current.y, controlX, controlY);
    }

    final lastPoint = stroke.points.last;
    path.lineTo(lastPoint.x, lastPoint.y);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPreviewPainter oldDelegate) {
    return oldDelegate.drawing != drawing;
  }
}
