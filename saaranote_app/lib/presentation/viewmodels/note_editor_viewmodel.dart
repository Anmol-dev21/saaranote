import 'package:flutter/material.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/rich_text_content.dart' as domain;
import '../../domain/entities/drawing.dart';
import '../../core/services/rich_text_service.dart';
import '../../core/services/drawing_service.dart';

/// Modes for the note editor
enum EditorMode {
  text,     // Text only mode
  draw,     // Drawing only mode
  hybrid,   // Both text and drawing mode
}

/// ViewModel for the note editor screen
/// Handles state for rich text editing, drawing, and mode switching
class NoteEditorViewModel extends ChangeNotifier {
  final RichTextService _richTextService;
  final DrawingService _drawingService;

  NoteEditorViewModel(this._richTextService, this._drawingService);

  // Editor mode
  EditorMode _mode = EditorMode.text;
  EditorMode get mode => _mode;

  // Text content
  String _plainText = '';
  List<domain.TextSpan> _textSpans = [];
  
  String get plainText => _plainText;
  List<domain.TextSpan> get textSpans => _textSpans;

  // Text selection for formatting
  TextSelection? _textSelection;
  TextSelection? get textSelection => _textSelection;

  // Current text formatting style
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  double _fontSize = 16.0;
  Color? _textColor;
  Color? _highlightColor;

  bool get isBold => _isBold;
  bool get isItalic => _isItalic;
  bool get isUnderline => _isUnderline;
  double get fontSize => _fontSize;
  Color? get textColor => _textColor;
  Color? get highlightColor => _highlightColor;

  // Drawing state
  final List<Drawing> _drawings = [];
  List<DrawingStroke> _currentStrokes = [];
  
  List<Drawing> get drawings => _drawings;
  bool get hasDrawings => _drawings.isNotEmpty;

  // Drawing tool settings
  Color _penColor = Colors.black;
  double _penWidth = 2.0;
  StrokeType _strokeType = StrokeType.pen;
  double _penOpacity = 1.0;

  Color get penColor => _penColor;
  double get penWidth => _penWidth;
  StrokeType get strokeType => _strokeType;
  double get penOpacity => _penOpacity;

  // Undo/Redo stacks for drawing
  final List<List<DrawingStroke>> _undoStack = [];
  final List<List<DrawingStroke>> _redoStack = [];
  
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // Content type tracking
  ContentType get contentType {
    final hasText = _plainText.isNotEmpty;
    final hasDrawing = _drawings.isNotEmpty;
    
    if (hasText && hasDrawing) return ContentType.hybrid;
    if (hasDrawing) return ContentType.drawing;
    if (_textSpans.isNotEmpty) return ContentType.rich;
    return ContentType.plain;
  }

  /// Set editor mode
  void setMode(EditorMode mode) {
    _mode = mode;
    notifyListeners();
  }

  /// Update plain text content
  void updateText(String text) {
    _plainText = text;
    notifyListeners();
  }

  /// Update text selection (for formatting)
  void updateTextSelection(TextSelection? selection) {
    _textSelection = selection;
    _updateFormattingState();
    notifyListeners();
  }

  /// Toggle bold formatting
  void toggleBold() {
    _isBold = !_isBold;
    _applyFormatting();
    notifyListeners();
  }

  /// Toggle italic formatting
  void toggleItalic() {
    _isItalic = !_isItalic;
    _applyFormatting();
    notifyListeners();
  }

  /// Toggle underline formatting
  void toggleUnderline() {
    _isUnderline = !_isUnderline;
    _applyFormatting();
    notifyListeners();
  }

  /// Set font size
  void setFontSize(double size) {
    _fontSize = size;
    _applyFormatting();
    notifyListeners();
  }

  /// Set text color
  void setTextColor(Color? color) {
    _textColor = color;
    _applyFormatting();
    notifyListeners();
  }

  /// Set highlight color
  void setHighlightColor(Color? color) {
    _highlightColor = color;
    _applyFormatting();
    notifyListeners();
  }

  /// Clear all formatting
  void clearFormatting() {
    _isBold = false;
    _isItalic = false;
    _isUnderline = false;
    _fontSize = 16.0;
    _textColor = null;
    _highlightColor = null;
    _applyFormatting();
    notifyListeners();
  }

  /// Apply current formatting to selected text
  void _applyFormatting() {
    if (_textSelection == null || !_textSelection!.isValid || _plainText.isEmpty) {
      return;
    }

    final start = _textSelection!.start;
    final end = _textSelection!.end;

    if (start >= end || start < 0 || end > _plainText.length) {
      return;
    }

    final style = domain.TextStyle(
      bold: _isBold,
      italic: _isItalic,
      underline: _isUnderline,
      fontSize: _fontSize != 16.0 ? _fontSize : null,
        textColor: _textColor != null
          ? '#${_textColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}'
          : null,
        highlightColor: _highlightColor != null
          ? '#${_highlightColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}'
          : null,
    );

    final richContent = domain.RichTextContent(
      plainText: _plainText,
      spans: _textSpans,
    );

    final updated = _richTextService.applyFormatting(richContent, start, end, style);
    _textSpans = updated.spans;
  }

  /// Update formatting state based on current selection
  void _updateFormattingState() {
    if (_textSelection == null || !_textSelection!.isValid || _plainText.isEmpty) {
      return;
    }

    // Find spans at cursor position
    final position = _textSelection!.start;
    final spanAtCursor = _textSpans.firstWhere(
      (span) => span.start <= position && span.end > position,
      orElse: () => domain.TextSpan(
        start: 0,
        end: 0,
        style: const domain.TextStyle(),
      ),
    );

    _isBold = spanAtCursor.style.bold;
    _isItalic = spanAtCursor.style.italic;
    _isUnderline = spanAtCursor.style.underline;
    _fontSize = spanAtCursor.style.fontSize ?? 16.0;
    
    // Parse colors
    if (spanAtCursor.style.textColor != null) {
      try {
        final colorValue = int.parse(spanAtCursor.style.textColor!.substring(1), radix: 16);
        _textColor = Color(0xFF000000 | colorValue);
      } catch (_) {
        _textColor = null;
      }
    } else {
      _textColor = null;
    }

    if (spanAtCursor.style.highlightColor != null) {
      try {
        final colorValue = int.parse(spanAtCursor.style.highlightColor!.substring(1), radix: 16);
        _highlightColor = Color(0xFF000000 | colorValue);
      } catch (_) {
        _highlightColor = null;
      }
    } else {
      _highlightColor = null;
    }
  }

  /// Set pen color for drawing
  void setPenColor(Color color) {
    _penColor = color;
    notifyListeners();
  }

  /// Set pen width for drawing
  void setPenWidth(double width) {
    _penWidth = width;
    notifyListeners();
  }

  /// Set stroke type (pen, highlighter, eraser)
  void setStrokeType(StrokeType type) {
    _strokeType = type;
    notifyListeners();
  }

  /// Set pen opacity
  void setPenOpacity(double opacity) {
    _penOpacity = opacity;
    notifyListeners();
  }

  /// Start a new stroke
  void startStroke(Offset point) {
    _saveStateForUndo();
    
    final stroke = DrawingStroke(
      id: 'stroke-${DateTime.now().millisecondsSinceEpoch}',
      points: [
        StrokePoint(
          x: point.dx,
          y: point.dy,
          timestamp: DateTime.now(),
        ),
      ],
      style: StrokeStyle(
        color: '#${_penColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        width: _penWidth,
        type: _strokeType,
        opacity: _penOpacity,
      ),
      createdAt: DateTime.now(),
    );
    
    _currentStrokes.add(stroke);
    notifyListeners();
  }

  /// Add point to current stroke
  void addPointToStroke(Offset point, {double? pressure}) {
    if (_currentStrokes.isEmpty) return;
    
    final lastStroke = _currentStrokes.last;
    final updatedPoints = [
      ...lastStroke.points,
      StrokePoint(
        x: point.dx,
        y: point.dy,
        pressure: pressure,
        timestamp: DateTime.now(),
      ),
    ];
    
    _currentStrokes[_currentStrokes.length - 1] = DrawingStroke(
      id: lastStroke.id,
      points: updatedPoints,
      style: lastStroke.style,
      createdAt: lastStroke.createdAt,
    );
    
    notifyListeners();
  }

  /// End current stroke
  void endStroke() {
    if (_currentStrokes.isEmpty) return;
    
    // Optimize the stroke before saving
    final lastStroke = _currentStrokes.last;
    final optimized = _drawingService.optimizeStroke(lastStroke);
    _currentStrokes[_currentStrokes.length - 1] = optimized;
    
    notifyListeners();
  }

  /// Save current strokes as a drawing
  void saveDrawing() {
    if (_currentStrokes.isEmpty) return;
    
    final drawing = Drawing(
      id: 'drawing-${DateTime.now().millisecondsSinceEpoch}',
      strokes: List.from(_currentStrokes),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _drawings.add(drawing);
    _currentStrokes.clear();
    _undoStack.clear();
    _redoStack.clear();
    
    notifyListeners();
  }

  /// Undo last stroke
  void undo() {
    if (_currentStrokes.isEmpty) return;
    
    _redoStack.add(List.from(_currentStrokes));
    _currentStrokes.removeLast();
    notifyListeners();
  }

  /// Redo last undone stroke
  void redo() {
    if (_redoStack.isEmpty) return;
    
    final strokes = _redoStack.removeLast();
    _currentStrokes = strokes;
    notifyListeners();
  }

  /// Clear current drawing
  void clearDrawing() {
    if (_currentStrokes.isEmpty) return;
    
    _saveStateForUndo();
    _currentStrokes.clear();
    notifyListeners();
  }

  /// Save current state for undo
  void _saveStateForUndo() {
    _undoStack.add(List.from(_currentStrokes));
    _redoStack.clear();
    
    // Limit undo stack size
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  /// Get current strokes for rendering
  List<DrawingStroke> get currentStrokes => _currentStrokes;

  /// Build rich text content for saving
  domain.RichTextContent? getRichTextContent() {
    if (_plainText.isEmpty) return null;
    if (_textSpans.isEmpty) return null;
    
    return domain.RichTextContent(
      plainText: _plainText,
      spans: _textSpans,
    );
  }

  /// Get drawing IDs for saving
  List<String> getDrawingIds() {
    return _drawings.map((d) => d.id).toList();
  }

  /// Reset editor state
  void reset() {
    _mode = EditorMode.text;
    _plainText = '';
    _textSpans = [];
    _textSelection = null;
    _isBold = false;
    _isItalic = false;
    _isUnderline = false;
    _fontSize = 16.0;
    _textColor = null;
    _highlightColor = null;
    _drawings.clear();
    _currentStrokes.clear();
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  /// Load existing note for editing
  void loadNote(Note note) {
    _plainText = note.content;
    
    if (note.richContent != null) {
      _textSpans = note.richContent!.spans;
    } else {
      _textSpans = [];
    }
    
    // Drawings would be loaded separately via repository
    // This is just for editing text content
    
    notifyListeners();
  }
}
