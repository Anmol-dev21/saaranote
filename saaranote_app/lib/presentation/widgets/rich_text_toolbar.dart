import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/note_editor_viewmodel.dart';
import '../../core/design_system/app_spacing.dart';

/// Rich text formatting toolbar
/// Provides buttons for bold, italic, underline, font size, and colors
class RichTextToolbar extends StatelessWidget {
  const RichTextToolbar({super.key});

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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bold
                _ToolbarButton(
                  icon: Icons.format_bold,
                  isActive: viewModel.isBold,
                  onPressed: viewModel.toggleBold,
                  tooltip: 'Bold',
                ),
                
                // Italic
                _ToolbarButton(
                  icon: Icons.format_italic,
                  isActive: viewModel.isItalic,
                  onPressed: viewModel.toggleItalic,
                  tooltip: 'Italic',
                ),
                
                // Underline
                _ToolbarButton(
                  icon: Icons.format_underline,
                  isActive: viewModel.isUnderline,
                  onPressed: viewModel.toggleUnderline,
                  tooltip: 'Underline',
                ),
                
                SizedBox(width: AppSpacing.xs),
                _VerticalDivider(),
                SizedBox(width: AppSpacing.xs),
                
                // Font size
                _FontSizeButton(
                  currentSize: viewModel.fontSize,
                  onSizeChanged: viewModel.setFontSize,
                ),
                
                SizedBox(width: AppSpacing.xs),
                _VerticalDivider(),
                SizedBox(width: AppSpacing.xs),
                
                // Text color
                _ColorButton(
                  icon: Icons.format_color_text,
                  currentColor: viewModel.textColor,
                  onColorChanged: viewModel.setTextColor,
                  tooltip: 'Text Color',
                ),
                
                // Highlight color
                _ColorButton(
                  icon: Icons.format_color_fill,
                  currentColor: viewModel.highlightColor,
                  onColorChanged: viewModel.setHighlightColor,
                  tooltip: 'Highlight',
                ),
                
                SizedBox(width: AppSpacing.xs),
                _VerticalDivider(),
                SizedBox(width: AppSpacing.xs),
                
                // Clear formatting
                _ToolbarButton(
                  icon: Icons.format_clear,
                  isActive: false,
                  onPressed: viewModel.clearFormatting,
                  tooltip: 'Clear Formatting',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Toolbar button widget
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final String tooltip;

  const _ToolbarButton({
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

/// Font size selector button
class _FontSizeButton extends StatelessWidget {
  final double currentSize;
  final ValueChanged<double> onSizeChanged;

  const _FontSizeButton({
    required this.currentSize,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: 'Font Size',
      itemBuilder: (context) => [
        _buildFontSizeItem(12),
        _buildFontSizeItem(14),
        _buildFontSizeItem(16),
        _buildFontSizeItem(18),
        _buildFontSizeItem(20),
        _buildFontSizeItem(24),
        _buildFontSizeItem(28),
        _buildFontSizeItem(32),
      ],
      onSelected: onSizeChanged,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${currentSize.toInt()}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<double> _buildFontSizeItem(double size) {
    return PopupMenuItem<double>(
      value: size,
      child: Text('${size.toInt()}'),
    );
  }
}

/// Color picker button
class _ColorButton extends StatelessWidget {
  final IconData icon;
  final Color? currentColor;
  final ValueChanged<Color?> onColorChanged;
  final String tooltip;

  const _ColorButton({
    required this.icon,
    required this.currentColor,
    required this.onColorChanged,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Color?>(
      tooltip: tooltip,
      itemBuilder: (context) => [
        PopupMenuItem<Color?>(
          value: null,
          child: Row(
            children: [
              Icon(Icons.clear, size: 20),
              SizedBox(width: AppSpacing.xs),
              Text('None'),
            ],
          ),
        ),
        ..._buildColorItems(),
      ],
      onSelected: onColorChanged,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            if (currentColor != null)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: currentColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
          ],
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
      Colors.blue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lime,
      Colors.yellow,
      Colors.orange,
      Colors.brown,
      Colors.grey,
    ];

    return colors.map((color) {
      return PopupMenuItem<Color>(
        value: color,
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Text(_getColorName(color)),
          ],
        ),
      );
    }).toList();
  }

  String _getColorName(Color color) {
    if (color == Colors.black) return 'Black';
    if (color == Colors.red) return 'Red';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.cyan) return 'Cyan';
    if (color == Colors.teal) return 'Teal';
    if (color == Colors.green) return 'Green';
    if (color == Colors.lime) return 'Lime';
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.brown) return 'Brown';
    if (color == Colors.grey) return 'Grey';
    return 'Custom';
  }
}

/// Vertical divider for toolbar
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Theme.of(context).dividerColor,
    );
  }
}
