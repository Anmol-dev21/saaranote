import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/rich_text_content.dart' as domain;
import '../../domain/entities/drawing.dart';
import '../../core/services/rich_text_service.dart';
import '../../core/services/drawing_service.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/drawing_local_data_source.dart';

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
  final List<DrawingStroke> _currentStrokes = [];
  DrawingStroke? _activeStroke;
  int _drawingRevision = 0;
  
  List<Drawing> get drawings => _drawings;
  bool get hasDrawings => _drawings.any((drawing) => drawing.strokes.isNotEmpty);
  bool get hasPendingStrokes =>
      _currentStrokes.isNotEmpty || _activeStroke != null;
  bool get hasActiveDrawing =>
      _currentStrokes.isNotEmpty || _activeStroke != null || hasDrawings;
  int get drawingRevision => _drawingRevision;
  bool get hasEraserStrokes =>
      _activeStroke?.style.type == StrokeType.eraser ||
      _currentStrokes.any((stroke) => stroke.style.type == StrokeType.eraser) ||
      _drawings.any(
        (drawing) => drawing.strokes.any(
          (stroke) => stroke.style.type == StrokeType.eraser,
        ),
      );
  DrawingStroke? get activeStroke => _activeStroke;

  // Drawing tool settings
  Color _penColor = Colors.black;
  double _penWidth = 2.0;
  StrokeType _strokeType = StrokeType.pen;
  double _penOpacity = 1.0;

  Color get penColor => _penColor;
  double get penWidth => _penWidth;
  StrokeType get strokeType => _strokeType;
  double get penOpacity => _penOpacity;

  // Undo/Redo history for drawing
  final List<_DrawingHistoryEntry> _undoStack = [];
  final List<_DrawingHistoryEntry> _redoStack = [];
  
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // Content type tracking
  ContentType get contentType {
    final hasText = _plainText.isNotEmpty;
    final hasDrawing = hasDrawings;
    final hasRichFormatting = _textSpans.any((span) => span.style.hasFormatting);
    
    if (hasText && hasDrawing) return ContentType.hybrid;
    if (hasDrawing) return ContentType.drawing;
    if (hasRichFormatting) return ContentType.rich;
    return ContentType.plain;
  }

  /// Set editor mode
  void setMode(EditorMode mode) {
    if (_activeStroke != null) {
      endStroke();
    }

    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
  }

  /// Update plain text content
  void updateText(String text) {
    _plainText = text;
    notifyListeners();
  }

  /// Update text and selection from controller
  void updateTextEditingValue(TextEditingValue value) {
    final newText = value.text;
    final oldText = _plainText;

    if (newText == oldText && value.selection == _textSelection) {
      return;
    }

    _textSelection = value.selection;

    if (newText == oldText) {
      _updateFormattingState();
      notifyListeners();
      return;
    }

    if (_textSpans.isEmpty && oldText.isNotEmpty) {
      _textSpans = [
        domain.TextSpan(
          start: 0,
          end: oldText.length,
          style: const domain.TextStyle(),
        ),
      ];
    }

    final oldLength = oldText.length;
    final newLength = newText.length;

    int prefix = 0;
    while (prefix < oldLength &&
        prefix < newLength &&
        oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }

    int suffix = 0;
    while (suffix < oldLength - prefix &&
        suffix < newLength - prefix &&
        oldText.codeUnitAt(oldLength - 1 - suffix) ==
            newText.codeUnitAt(newLength - 1 - suffix)) {
      suffix++;
    }

    final oldChangeEnd = oldLength - suffix;
    final newChangeEnd = newLength - suffix;
    final removedLength = oldChangeEnd - prefix;
    final insertedLength = newChangeEnd - prefix;
    final delta = insertedLength - removedLength;

    final updatedSpans = <domain.TextSpan>[];
    for (final span in _textSpans) {
      if (span.end <= prefix) {
        updatedSpans.add(span);
      } else if (span.start >= oldChangeEnd) {
        updatedSpans.add(domain.TextSpan(
          start: span.start + delta,
          end: span.end + delta,
          style: span.style,
        ));
      } else {
        if (span.start < prefix) {
          updatedSpans.add(domain.TextSpan(
            start: span.start,
            end: prefix,
            style: span.style,
          ));
        }
        if (span.end > oldChangeEnd) {
          updatedSpans.add(domain.TextSpan(
            start: oldChangeEnd + delta,
            end: span.end + delta,
            style: span.style,
          ));
        }
      }
    }

    if (insertedLength > 0) {
      updatedSpans.add(domain.TextSpan(
        start: prefix,
        end: prefix + insertedLength,
        style: _currentTypingStyle(),
      ));
    }

    _plainText = newText;
    _textSpans = _normalizeSpans(updatedSpans, newLength);
    _updateFormattingState();
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

    if (_textSpans.isEmpty) {
      _textSpans = [
        domain.TextSpan(
          start: 0,
          end: _plainText.length,
          style: const domain.TextStyle(),
        ),
      ];
    }

    final style = _currentTypingStyle();

    final richContent = domain.RichTextContent(
      plainText: _plainText,
      spans: _textSpans,
    );

    final updated = _richTextService.applyFormatting(richContent, start, end, style);
    _textSpans = _normalizeSpans(updated.spans, _plainText.length);
  }

  /// Update formatting state based on current selection
  void _updateFormattingState() {
    if (_textSelection == null || !_textSelection!.isValid || _plainText.isEmpty) {
      return;
    }

    // Find spans at cursor position
    final position = _textSelection!.start;
    domain.TextSpan? spanAtCursor;

    for (final span in _textSpans) {
      if (span.start <= position && span.end > position) {
        spanAtCursor = span;
        break;
      }
    }

    if (spanAtCursor == null && _textSelection!.isCollapsed && position > 0) {
      final fallbackPosition = position - 1;
      for (final span in _textSpans) {
        if (span.start <= fallbackPosition && span.end > fallbackPosition) {
          spanAtCursor = span;
          break;
        }
      }
    }

    spanAtCursor ??= const domain.TextSpan(
      start: 0,
      end: 0,
      style: domain.TextStyle(),
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
    if (_activeStroke != null) {
      endStroke();
    }

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
        color: '#${_penColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        width: _penWidth,
        type: _strokeType,
        opacity: _penOpacity,
      ),
      createdAt: DateTime.now(),
    );

    _activeStroke = stroke;
    _bumpDrawingRevision();
    notifyListeners();
  }

  /// Add point to current stroke
  void addPointToStroke(Offset point, {double? pressure}) {
    if (_activeStroke == null) return;

    _activeStroke!.points.add(
      StrokePoint(
        x: point.dx,
        y: point.dy,
        pressure: pressure,
        timestamp: DateTime.now(),
      ),
    );

    _bumpDrawingRevision();
    notifyListeners();
  }

  /// End current stroke
  void endStroke() {
    if (_activeStroke == null) return;

    final lastStroke = _activeStroke!;
    final optimized = _drawingService.optimizeStroke(lastStroke);
    final index = _currentStrokes.length;
    _currentStrokes.add(optimized);
    _pushUndoEntry(
      _DrawingHistoryEntry.addStroke(
        stroke: optimized,
        drawingId: null,
        strokeIndex: index,
      ),
    );

    _activeStroke = null;
    _bumpDrawingRevision();
    notifyListeners();
  }

  /// Save current strokes as a drawing
  void saveDrawing() {
    endStroke();
    if (_currentStrokes.isEmpty) return;

    final drawing = Drawing(
      id: 'drawing-${DateTime.now().millisecondsSinceEpoch}',
      strokes: List.from(_currentStrokes),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _drawings.add(drawing);
    _relocateHistoryEntries(drawing);
    _currentStrokes.clear();

    _bumpDrawingRevision();
    notifyListeners();
  }

  /// Undo last stroke
  void undo() {
    if (_undoStack.isEmpty) return;

    final entry = _undoStack.removeLast();
    switch (entry.type) {
      case _HistoryType.addStroke:
        _removeStrokeByEntry(entry);
        _redoStack.add(entry);
        break;
      case _HistoryType.clear:
        _restoreFromClear(entry);
        _redoStack.add(entry);
        break;
    }

    _bumpDrawingRevision();
    notifyListeners();
  }

  /// Redo last undone stroke
  void redo() {
    if (_redoStack.isEmpty) return;

    final entry = _redoStack.removeLast();
    switch (entry.type) {
      case _HistoryType.addStroke:
        _reinsertStroke(entry);
        _undoStack.add(entry);
        break;
      case _HistoryType.clear:
        _applyClear();
        _undoStack.add(entry);
        break;
    }

    _bumpDrawingRevision();
    notifyListeners();
  }

  /// Clear current drawing
  void clearDrawing() {
    if (_currentStrokes.isEmpty && _drawings.isEmpty) return;

    endStroke();

    _pushUndoEntry(
      _DrawingHistoryEntry.clear(
        previousCurrentStrokes: List.from(_currentStrokes),
        previousDrawings: _cloneDrawings(_drawings),
      ),
    );
    _applyClear();

    _bumpDrawingRevision();
    notifyListeners();
  }

  /// Get current strokes for rendering
  List<DrawingStroke> get currentStrokes => _currentStrokes;

  /// Build rich text content for saving
  domain.RichTextContent? getRichTextContent() {
    if (_plainText.isEmpty) return null;
    if (_textSpans.isEmpty) return null;
    if (!_textSpans.any((span) => span.style.hasFormatting)) return null;
    
    return domain.RichTextContent(
      plainText: _plainText,
      spans: _textSpans,
    );
  }

  /// Get drawing IDs for saving
  List<String> getDrawingIds() {
    return _drawings
        .where((drawing) => drawing.strokes.isNotEmpty)
        .map((drawing) => drawing.id)
        .toList();
  }

  Future<void> persistDrawings(int noteId) async {
    final drawingsToSave = _drawings
        .where((drawing) => drawing.strokes.isNotEmpty)
        .toList();
    if (drawingsToSave.isEmpty) return;

    final dataSource = DrawingLocalDataSource(
      DatabaseHelper.instance,
      _drawingService,
    );

    final savedDrawings = <Drawing>[];
    for (final drawing in drawingsToSave) {
      final saved = await dataSource.saveDrawing(drawing, noteId);
      savedDrawings.add(saved);
    }

    _drawings
      ..clear()
      ..addAll(savedDrawings);
    _bumpDrawingRevision();
    notifyListeners();
  }

  Future<void> loadDrawings(int noteId) async {
    final dataSource = DrawingLocalDataSource(
      DatabaseHelper.instance,
      _drawingService,
    );

    final loaded = await dataSource.getDrawingsByNoteId(noteId);
    _drawings
      ..clear()
      ..addAll(loaded);
    _currentStrokes.clear();
    _activeStroke = null;
    _undoStack.clear();
    _redoStack.clear();
    _bumpDrawingRevision();
    notifyListeners();
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
    _activeStroke = null;
    _undoStack.clear();
    _redoStack.clear();
    _drawingRevision = 0;
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
    
    _textSpans = _normalizeSpans(_textSpans, _plainText.length);
    notifyListeners();
  }

  domain.TextStyle _currentTypingStyle() {
    return domain.TextStyle(
      bold: _isBold,
      italic: _isItalic,
      underline: _isUnderline,
      fontSize: _fontSize != 16.0 ? _fontSize : null,
      textColor: _textColor != null
          ? '#${_textColor!.value.toRadixString(16).padLeft(8, '0').substring(2)}'
          : null,
      highlightColor: _highlightColor != null
          ? '#${_highlightColor!.value.toRadixString(16).padLeft(8, '0').substring(2)}'
          : null,
    );
  }

  List<domain.TextSpan> _normalizeSpans(
    List<domain.TextSpan> spans,
    int textLength,
  ) {
    if (textLength == 0) {
      return [];
    }

    final sorted = spans
        .where((span) => span.start < span.end)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final normalized = <domain.TextSpan>[];
    int cursor = 0;

    for (final span in sorted) {
      final start = span.start.clamp(0, textLength);
      final end = span.end.clamp(0, textLength);
      if (end <= start) continue;

      if (start > cursor) {
        normalized.add(domain.TextSpan(
          start: cursor,
          end: start,
          style: const domain.TextStyle(),
        ));
      }

      normalized.add(domain.TextSpan(
        start: start,
        end: end,
        style: span.style,
      ));
      cursor = end;
    }

    if (cursor < textLength) {
      normalized.add(domain.TextSpan(
        start: cursor,
        end: textLength,
        style: const domain.TextStyle(),
      ));
    }

    return _mergeAdjacentSpans(normalized);
  }

  List<domain.TextSpan> _mergeAdjacentSpans(List<domain.TextSpan> spans) {
    if (spans.length <= 1) return spans;

    final merged = <domain.TextSpan>[];
    var current = spans.first;

    for (int i = 1; i < spans.length; i++) {
      final next = spans[i];
      if (current.end == next.start && current.style == next.style) {
        current = domain.TextSpan(
          start: current.start,
          end: next.end,
          style: current.style,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }

    merged.add(current);
    return merged;
  }

  void _bumpDrawingRevision() {
    _drawingRevision++;
  }

  void _pushUndoEntry(_DrawingHistoryEntry entry) {
    _undoStack.add(entry);
    _redoStack.clear();

    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void _relocateHistoryEntries(Drawing drawing) {
    if (drawing.strokes.isEmpty) return;

    for (int i = 0; i < drawing.strokes.length; i++) {
      final strokeId = drawing.strokes[i].id;
      _updateHistoryEntryLocation(_undoStack, strokeId, drawing.id, i);
      _updateHistoryEntryLocation(_redoStack, strokeId, drawing.id, i);
    }
  }

  void _updateHistoryEntryLocation(
    List<_DrawingHistoryEntry> stack,
    String strokeId,
    String drawingId,
    int strokeIndex,
  ) {
    for (final entry in stack) {
      if (entry.type != _HistoryType.addStroke) continue;
      if (entry.stroke?.id != strokeId) continue;

      entry.drawingId = drawingId;
      entry.strokeIndex = strokeIndex;
    }
  }

  void _removeStrokeByEntry(_DrawingHistoryEntry entry) {
    final strokeId = entry.stroke?.id;
    if (strokeId == null) return;

    if (entry.drawingId == null) {
      _currentStrokes.removeWhere((stroke) => stroke.id == strokeId);
      return;
    }

    final drawing = _drawings.firstWhere(
      (d) => d.id == entry.drawingId,
      orElse: () => Drawing(
        id: entry.drawingId!,
        strokes: <DrawingStroke>[],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (!_drawings.contains(drawing)) {
      _drawings.add(drawing);
    }

    drawing.strokes.removeWhere((stroke) => stroke.id == strokeId);
  }

  void _reinsertStroke(_DrawingHistoryEntry entry) {
    final stroke = entry.stroke;
    if (stroke == null) return;

    if (entry.drawingId == null) {
      final insertIndex = entry.strokeIndex ?? _currentStrokes.length;
      final safeIndex = insertIndex.clamp(0, _currentStrokes.length);
      _currentStrokes.insert(safeIndex, stroke);
      return;
    }

    final drawingIndex = _drawings.indexWhere((d) => d.id == entry.drawingId);
    if (drawingIndex == -1) {
      _drawings.add(
        Drawing(
          id: entry.drawingId!,
          strokes: [stroke],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }

    final drawing = _drawings[drawingIndex];
    final insertIndex = entry.strokeIndex ?? drawing.strokes.length;
    final safeIndex = insertIndex.clamp(0, drawing.strokes.length);
    drawing.strokes.insert(safeIndex, stroke);
  }

  void _applyClear() {
    _currentStrokes.clear();
    _drawings.clear();
    _activeStroke = null;
  }

  void _restoreFromClear(_DrawingHistoryEntry entry) {
    _currentStrokes
      ..clear()
      ..addAll(entry.previousCurrentStrokes ?? const []);
    _drawings
      ..clear()
      ..addAll(entry.previousDrawings ?? const []);
    _activeStroke = null;
  }

  List<Drawing> _cloneDrawings(List<Drawing> drawings) {
    return drawings
        .map(
          (drawing) => Drawing(
            id: drawing.id,
            strokes: List.from(drawing.strokes),
            createdAt: drawing.createdAt,
            updatedAt: drawing.updatedAt,
          ),
        )
        .toList();
  }
}

enum _HistoryType {
  addStroke,
  clear,
}

class _DrawingHistoryEntry {
  final _HistoryType type;
  final DrawingStroke? stroke;
  String? drawingId;
  int? strokeIndex;
  final List<DrawingStroke>? previousCurrentStrokes;
  final List<Drawing>? previousDrawings;

  _DrawingHistoryEntry._({
    required this.type,
    this.stroke,
    this.drawingId,
    this.strokeIndex,
    this.previousCurrentStrokes,
    this.previousDrawings,
  });

  factory _DrawingHistoryEntry.addStroke({
    required DrawingStroke stroke,
    required String? drawingId,
    required int strokeIndex,
  }) {
    return _DrawingHistoryEntry._(
      type: _HistoryType.addStroke,
      stroke: stroke,
      drawingId: drawingId,
      strokeIndex: strokeIndex,
    );
  }

  factory _DrawingHistoryEntry.clear({
    required List<DrawingStroke> previousCurrentStrokes,
    required List<Drawing> previousDrawings,
  }) {
    return _DrawingHistoryEntry._(
      type: _HistoryType.clear,
      previousCurrentStrokes: previousCurrentStrokes,
      previousDrawings: previousDrawings,
    );
  }
}
