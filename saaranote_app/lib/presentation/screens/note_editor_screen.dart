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
  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
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
    bool dialogShown = false;

    try {
      // Save drawing if in draw or hybrid mode
      if (editorViewModel.mode == EditorMode.draw || 
          editorViewModel.mode == EditorMode.hybrid) {
        editorViewModel.saveDrawing();
      }

      // Get rich text content if available
      // TODO: In the future, create a new use case that accepts richContent and drawingIds
      // final richContent = editorViewModel.getRichTextContent();
      // final drawingIds = editorViewModel.getDrawingIds();

      // For now, use the existing createNoteFromText method
      // In a real implementation, you'd create a new use case that accepts
      // richContent and drawingIds parameters

      if (mounted) {
        dialogShown = true;
        await _showSavingDialog();
      }
      
      final success = await createViewModel.createNoteFromText(
        title: title,
        content: content,
        generateSummary: true,
        useAiEnhancement: true,
        generateFlashcards: true,
      );

      if (dialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

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
      if (dialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
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

  Future<void> _showSavingDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating smart summary...'),
          ],
        ),
      ),
    );
  }
}
