import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/note_editor_viewmodel.dart';
import '../viewmodels/create_note_viewmodel.dart';
import '../viewmodels/note_viewmodel.dart';
import '../widgets/rich_text_toolbar.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/drawing_tools_panel.dart';
import '../widgets/rich_text_editing_controller.dart';
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
  late final RichTextEditingController _contentController;
  final _contentFocusNode = FocusNode();
  TextEditingValue _lastContentValue = const TextEditingValue();
  bool _suppressControllerListener = false;

  @override
  void initState() {
    super.initState();

    _contentController = RichTextEditingController();
    _contentController.addListener(_handleContentChanged);
    
    // Load existing note if editing
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!.title;
      _contentController.text = widget.existingNote!.content;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final viewModel = context.read<NoteEditorViewModel>();
        viewModel.loadNote(widget.existingNote!);
        if (widget.existingNote!.id != null) {
          viewModel.loadDrawings(widget.existingNote!.id!);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _handleContentChanged() {
    if (_suppressControllerListener || !mounted) {
      return;
    }

    final value = _contentController.value;
    if (value == _lastContentValue) {
      return;
    }

    final viewModel = context.read<NoteEditorViewModel>();
    viewModel.updateTextEditingValue(value);
    _lastContentValue = value;
  }

  void _syncControllerSpans(NoteEditorViewModel viewModel) {
    _suppressControllerListener = true;
    _contentController.updateSpans(viewModel.textSpans);
    _suppressControllerListener = false;
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
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Title input
              _buildTitleInput(),

              // Content and drawing sections
              Expanded(
                child: _buildMainContent(),
              ),

              // Inline toolbar for draw mode
              Consumer<NoteEditorViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.mode != EditorMode.draw) {
                    return const SizedBox.shrink();
                  }
                  return _buildToolbar(mode: viewModel.mode);
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Consumer<NoteEditorViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.mode == EditorMode.draw) {
            return const SizedBox.shrink();
          }
          return _buildToolbar(mode: viewModel.mode);
        },
      ),
    );
  }

  Widget _buildModeSelector({EdgeInsetsGeometry? outerPadding}) {
    return Consumer<NoteEditorViewModel>(
      builder: (context, viewModel, child) {
        final theme = Theme.of(context);
        return Container(
          margin: outerPadding ?? AppSpacing.pagePadding.add(AppSpacing.verticalSm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
          ),
          padding: AppSpacing.paddingSm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mode',
                style: AppTypography.bodySmall(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGapXs,
              SegmentedButton<EditorMode>(
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleInput() {
    final theme = Theme.of(context);
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Title',
            style: AppTypography.bodySmall(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapXs,
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            ),
            child: TextFormField(
              controller: _titleController,
              style: AppTypography.h3(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Note Title',
                hintStyle: AppTypography.h3(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<NoteEditorViewModel>(
      builder: (context, viewModel, child) {
        switch (viewModel.mode) {
          case EditorMode.text:
            return Column(
              children: [
                Expanded(
                  child: _buildTextEditor(),
                ),
                _buildModeSelector(),
              ],
            );
          case EditorMode.draw:
            return Column(
              children: [
                _buildModeSelector(),
                Expanded(
                  child: _buildDrawingSurface(),
                ),
              ],
            );
          case EditorMode.hybrid:
            return _buildHybridEditor();
        }
      },
    );
  }

  Widget _buildTextEditor({EdgeInsetsGeometry? outerPadding}) {
    return Consumer<NoteEditorViewModel>(
      builder: (context, viewModel, child) {
        final theme = Theme.of(context);
        final viewInsets = MediaQuery.of(context).viewInsets;
        _syncControllerSpans(viewModel);
        return Container(
          margin: outerPadding ?? AppSpacing.pagePadding.add(AppSpacing.verticalSm),
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Content',
                style: AppTypography.bodySmall(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGapXs,
              Expanded(
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  style: AppTypography.noteContent(
                    color: theme.colorScheme.onSurface,
                  ),
                  scrollPadding: EdgeInsets.only(
                    bottom: viewInsets.bottom + 120,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Start typing or tap formatting buttons below...',
                    hintStyle: AppTypography.noteContent(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHybridEditor() {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        const minTextHeight = 200.0;
        final minDrawingHeight = isKeyboardOpen ? 120.0 : 200.0;
        const modeSelectorHeight = 96.0;

        double textHeight = availableHeight * (isKeyboardOpen ? 0.6 : 0.5);
        double drawingHeight =
            availableHeight - textHeight - modeSelectorHeight - AppSpacing.sm * 2;

        if (drawingHeight < minDrawingHeight) {
          drawingHeight = minDrawingHeight;
          textHeight =
              availableHeight - drawingHeight - modeSelectorHeight - AppSpacing.sm * 2;
        }

        if (textHeight < minTextHeight) {
          textHeight = minTextHeight;
        }

        return SingleChildScrollView(
          padding: AppSpacing.pagePadding.add(AppSpacing.verticalSm),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Column(
              children: [
                SizedBox(
                  height: textHeight,
                  child: _buildTextEditor(outerPadding: EdgeInsets.zero),
                ),
                AppSpacing.vGapSm,
                _buildModeSelector(outerPadding: EdgeInsets.zero),
                SizedBox(
                  height: drawingHeight,
                  child: _buildDrawingSurface(outerPadding: EdgeInsets.zero),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar({required EditorMode mode}) {
    final content = switch (mode) {
      EditorMode.text => const RichTextToolbar(),
      EditorMode.draw => const DrawingToolsPanel(),
      EditorMode.hybrid => Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            RichTextToolbar(),
            DrawingToolsPanel(),
          ],
        ),
    };

    return SafeArea(top: false, child: content);
  }

  Widget _buildDrawingSurface({EdgeInsetsGeometry? outerPadding}) {
    final theme = Theme.of(context);
    return Container(
      margin: outerPadding ?? AppSpacing.pagePadding.add(AppSpacing.verticalSm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.paddingSm,
            child: Text(
              'Drawing',
              style: AppTypography.bodySmall(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusMd,
              child: const DrawingCanvas(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    final editorViewModel = context.read<NoteEditorViewModel>();
    final createViewModel = context.read<CreateNoteViewModel>();
    final noteViewModel = context.read<NoteViewModel>();

    final hasDrawing = editorViewModel.hasActiveDrawing;

    if (content.isEmpty && !hasDrawing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add content or a drawing before saving')),
      );
      return;
    }

    final safeContent = content.isEmpty && hasDrawing
        ? 'Drawing note'
        : content;

    try {
      if (editorViewModel.hasPendingStrokes) {
        editorViewModel.saveDrawing();
      }

      final success = await createViewModel.createNoteFromText(
        title: title,
        content: safeContent,
        generateSummary: true,
        generateFlashcards: true,
      );

      if (!mounted) return;

      if (success) {
        final createdNote = createViewModel.createdNote;
        if (createdNote != null) {
          if (editorViewModel.hasDrawings) {
            await editorViewModel.persistDrawings(createdNote.id!);
            if (!mounted) return;
          }

          final richContent = editorViewModel.getRichTextContent();
          final drawingIds = editorViewModel.getDrawingIds();
          final contentType = editorViewModel.contentType;

          if (drawingIds.isNotEmpty || richContent != null) {
            await noteViewModel.updateNote(
              noteId: createdNote.id!,
              drawingIds: drawingIds.isEmpty ? null : drawingIds,
              richContent: richContent,
              contentType: contentType,
            );
            if (!mounted) return;
          }
        }

        editorViewModel.reset();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully')),
        );

        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(createViewModel.errorMessage ?? 'Failed to save note'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
