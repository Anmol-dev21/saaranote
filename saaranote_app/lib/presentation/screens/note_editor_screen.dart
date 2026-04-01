import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/note_editor_viewmodel.dart';
import '../viewmodels/create_note_viewmodel.dart';
import '../widgets/rich_text_toolbar.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/drawing_tools_panel.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/rich_text_content.dart' as domain;

/// Advanced note editor screen with rich text and drawing support
/// 
/// Features:
/// - Rich text formatting (bold, italic, colors, etc.)
/// - Handwriting/drawing canvas
/// - Mode switching (text/draw/hybrid)
/// - Maintains existing note creation compatibility
class NoteEditorScreen extends StatefulWidget {
  final Note? existingNote; // For editing existing notes

  const NoteEditorScreen({
    super.key,
    this.existingNote,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late final RichTextEditingController _contentController;
  final _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _contentController = RichTextEditingController(
      viewModel: context.read<NoteEditorViewModel>(),
    );
    
    // Load existing note if editing
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!.title;
      _contentController.text = widget.existingNote!.content;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NoteEditorViewModel>().loadNote(widget.existingNote!);
      });
    }

    // Listen to text changes
    _contentController.addListener(_onTextChanged);
    _contentFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final viewModel = context.read<NoteEditorViewModel>();
    viewModel.updateText(_contentController.text);
    viewModel.updateTextSelection(_contentController.selection);
  }

  void _onFocusChanged() {
    if (_contentFocusNode.hasFocus) {
      final viewModel = context.read<NoteEditorViewModel>();
      viewModel.updateTextSelection(_contentController.selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingNote == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode selector
          _buildModeSelector(),
          
          // Title input
          _buildTitleInput(),
          
          // Content area (switches based on mode)
          Expanded(
            child: _buildContentArea(),
          ),
          
          // Toolbar (switches based on mode)
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Consumer<NoteEditorViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Text(
                'Mode:',
                style: AppTypography.bodySmall(),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SegmentedButton<EditorMode>(
                  segments: const [
                    ButtonSegment(
                      value: EditorMode.text,
                      icon: Icon(Icons.text_fields, size: 18),
                      label: Text('Text'),
                    ),
                    ButtonSegment(
                      value: EditorMode.draw,
                      icon: Icon(Icons.draw, size: 18),
                      label: Text('Draw'),
                    ),
                    ButtonSegment(
                      value: EditorMode.hybrid,
                      icon: Icon(Icons.space_dashboard, size: 18),
                      label: Text('Hybrid'),
                    ),
                  ],
                  selected: {viewModel.mode},
                  onSelectionChanged: (Set<EditorMode> newSelection) {
                    viewModel.setMode(newSelection.first);
                  },
                  showSelectedIcon: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleInput() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: TextFormField(
        controller: _titleController,
        style: AppTypography.h3(),
        decoration: InputDecoration(
          hintText: 'Note Title',
          hintStyle: AppTypography.h3().copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          border: InputBorder.none,
        ),
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildContentArea() {
    return Consumer<NoteEditorViewModel>(
      builder: (context, viewModel, child) {
        switch (viewModel.mode) {
          case EditorMode.text:
            return _buildTextEditor();
          case EditorMode.draw:
            return const DrawingCanvas();
          case EditorMode.hybrid:
            return _buildHybridEditor();
        }
      },
    );
  }

  Widget _buildTextEditor() {
    return Consumer<NoteEditorViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: TextField(
            controller: _contentController,
            focusNode: _contentFocusNode,
            style: AppTypography.noteContent(),
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Start typing or tap formatting buttons below...',
              hintStyle: AppTypography.noteContent().copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              border: InputBorder.none,
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (text) {
              // Text is automatically synced via listener
            },
          ),
        );
      },
    );
  }

  Widget _buildHybridEditor() {
    return Column(
      children: [
        // Text section (upper half)
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
            ),
            child: _buildTextEditor(),
          ),
        ),
        
        // Drawing section (lower half)
        Expanded(
          flex: 1,
          child: const DrawingCanvas(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Consumer<NoteEditorViewModel>(
      builder: (context, viewModel, child) {
        switch (viewModel.mode) {
          case EditorMode.text:
            return const RichTextToolbar();
          case EditorMode.draw:
            return const DrawingToolsPanel();
          case EditorMode.hybrid:
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                RichTextToolbar(),
                DrawingToolsPanel(),
              ],
            );
        }
      },
    );
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content')),
      );
      return;
    }

    final editorViewModel = context.read<NoteEditorViewModel>();
    final createViewModel = context.read<CreateNoteViewModel>();

    try {
      // Save drawing if in draw or hybrid mode
      if (editorViewModel.mode == EditorMode.draw || 
          editorViewModel.mode == EditorMode.hybrid) {
        editorViewModel.saveDrawing();
      }

      final richContent = editorViewModel.getRichTextContent();
      final drawingIds = editorViewModel.getDrawingIds();
      final drawings = editorViewModel.drawings;

      final persistedDrawingIds = drawingIds.isNotEmpty ? drawingIds : null;
      final persistedDrawings = drawings.isNotEmpty ? drawings : null;

      final success = await createViewModel.createNoteFromText(
        title: title,
        content: content,
        generateSummary: true,
        generateFlashcards: true,
        richContent: richContent,
        drawingIds: persistedDrawingIds,
        contentType: editorViewModel.contentType,
        drawings: persistedDrawings,
      );

      if (success && mounted) {
        // Reset editor
        editorViewModel.reset();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully')),
        );
        
        // Go back
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(createViewModel.errorMessage ?? 'Failed to save note'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Text controller that renders rich text spans for the editor
class RichTextEditingController extends TextEditingController {
  final NoteEditorViewModel viewModel;

  RichTextEditingController({
    required this.viewModel,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool withComposing = false,
  }) {
    final baseStyle = style ?? const TextStyle();
    final text = value.text;

    if (text.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    final spans = _buildSpans(text, viewModel.textSpans, baseStyle);
    return TextSpan(style: baseStyle, children: spans);
  }

  List<TextSpan> _buildSpans(
    String text,
    List<domain.TextSpan> spans,
    TextStyle baseStyle,
  ) {
    if (spans.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final sorted = List<domain.TextSpan>.from(spans)
      ..sort((a, b) => a.start.compareTo(b.start));

    final result = <TextSpan>[];
    int index = 0;

    for (final span in sorted) {
      final start = span.start.clamp(0, text.length);
      final end = span.end.clamp(0, text.length);

      if (start > index) {
        result.add(TextSpan(
          text: text.substring(index, start),
          style: baseStyle,
        ));
      }

      if (end > start) {
        result.add(TextSpan(
          text: text.substring(start, end),
          style: _applySpanStyle(baseStyle, span.style),
        ));
      }

      index = end;
    }

    if (index < text.length) {
      result.add(TextSpan(
        text: text.substring(index),
        style: baseStyle,
      ));
    }

    return result;
  }

  TextStyle _applySpanStyle(TextStyle baseStyle, domain.TextStyle spanStyle) {
    return baseStyle.copyWith(
      fontWeight: spanStyle.bold ? FontWeight.bold : null,
      fontStyle: spanStyle.italic ? FontStyle.italic : null,
      decoration: spanStyle.underline ? TextDecoration.underline : null,
      fontSize: spanStyle.fontSize,
      color: _parseColor(spanStyle.textColor),
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
