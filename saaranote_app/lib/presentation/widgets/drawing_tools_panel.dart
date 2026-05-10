import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/note_editor_viewmodel.dart';
import '../../domain/entities/drawing.dart';
import '../../core/design_system/app_spacing.dart';

/// Drawing tools panel for pen, color, thickness, and eraser
class DrawingToolsPanel extends StatelessWidget {
  const DrawingToolsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteEditorViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Pen tool
                _ToolButton(
                  icon: Icons.edit,
                  isActive: viewModel.strokeType == StrokeType.pen,
                  onPressed: () => viewModel.setStrokeType(StrokeType.pen),
                  tooltip: 'Pen',
                ),

                SizedBox(width: AppSpacing.xs),

                // Highlighter tool
                _ToolButton(
                  icon: Icons.highlight,
                  isActive: viewModel.strokeType == StrokeType.highlighter,
                  onPressed: () => viewModel.setStrokeType(StrokeType.highlighter),
                  tooltip: 'Highlighter',
                ),

                SizedBox(width: AppSpacing.xs),

                // Eraser tool
                _ToolButton(
                  icon: Icons.auto_fix_high,
                  isActive: viewModel.strokeType == StrokeType.eraser,
                  onPressed: () => viewModel.setStrokeType(StrokeType.eraser),
                  tooltip: 'Eraser',
                ),

                SizedBox(width: AppSpacing.sm),
                _VerticalDivider(),
                SizedBox(width: AppSpacing.sm),

                // Color picker
                _ColorPicker(
                  currentColor: viewModel.penColor,
                  onColorChanged: viewModel.setPenColor,
                ),

                SizedBox(width: AppSpacing.sm),
                _VerticalDivider(),
                SizedBox(width: AppSpacing.sm),

                // Thickness slider
                SizedBox(
                  width: 140,
                  child: _ThicknessSlider(
                    currentWidth: viewModel.penWidth,
                    onWidthChanged: viewModel.setPenWidth,
                  ),
                ),

                SizedBox(width: AppSpacing.sm),
                _VerticalDivider(),
                SizedBox(width: AppSpacing.sm),

                // Undo
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: viewModel.canUndo ? viewModel.undo : null,
                  tooltip: 'Undo',
                  iconSize: 20,
                ),

                // Redo
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: viewModel.canRedo ? viewModel.redo : null,
                  tooltip: 'Redo',
                  iconSize: 20,
                ),

                // Clear
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: viewModel.clearDrawing,
                  tooltip: 'Clear Canvas',
                  iconSize: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tool button widget
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final String tooltip;

  const _ToolButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Color picker widget
class _ColorPicker extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  const _ColorPicker({
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Color>(
      tooltip: 'Pen Color',
      itemBuilder: (context) => _buildColorItems(),
      onSelected: onColorChanged,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: currentColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  List<PopupMenuItem<Color>> _buildColorItems() {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
    ];

    return colors.map((color) {
      return PopupMenuItem<Color>(
        value: color,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }).toList();
  }
}

/// Thickness slider widget
class _ThicknessSlider extends StatelessWidget {
  final double currentWidth;
  final ValueChanged<double> onWidthChanged;

  const _ThicknessSlider({
    required this.currentWidth,
    required this.onWidthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.fiber_manual_record,
          size: 12,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: currentWidth,
              min: 1.0,
              max: 20.0,
              divisions: 19,
              onChanged: onWidthChanged,
            ),
          ),
        ),
        Icon(
          Icons.fiber_manual_record,
          size: 24,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ],
    );
  }
}

/// Vertical divider
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Theme.of(context).dividerColor,
    );
  }
}
