import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/note_editor_viewmodel.dart';
import '../../domain/entities/drawing.dart';

/// Drawing canvas widget for handwriting and free-draw
/// Optimized for performance on low-end devices
class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  @override
  Widget build(BuildContext context) {
    return Consumer<NoteEditorViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          color: Colors.white,
          child: GestureDetector(
            onPanStart: (details) => _handlePanStart(context, details),
            onPanUpdate: (details) => _handlePanUpdate(context, details),
            onPanEnd: (details) => _handlePanEnd(context, details),
            child: CustomPaint(
              size: Size.infinite,
              painter: _DrawingPainter(
                strokes: viewModel.currentStrokes,
                drawings: viewModel.drawings,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePanStart(BuildContext context, DragStartDetails details) {
    final viewModel = context.read<NoteEditorViewModel>();
    viewModel.startStroke(details.localPosition);
  }

  void _handlePanUpdate(BuildContext context, DragUpdateDetails details) {
    final viewModel = context.read<NoteEditorViewModel>();
    viewModel.addPointToStroke(
      details.localPosition,
      // pressure: details.pressure, // Not available in DragUpdateDetails
    );
  }

  void _handlePanEnd(BuildContext context, DragEndDetails details) {
    final viewModel = context.read<NoteEditorViewModel>();
    viewModel.endStroke();
  }
}

/// Custom painter for drawing strokes
/// Uses efficient path rendering for smooth performance
class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Drawing> drawings;

  _DrawingPainter({
    required this.strokes,
    required this.drawings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed drawings first
    for (final drawing in drawings) {
      for (final stroke in drawing.strokes) {
        _drawStroke(canvas, stroke);
      }
    }

    // Draw current strokes on top
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.style.width;

    // Parse color from hex string
    final colorHex = stroke.style.color.replaceFirst('#', '');
    final colorValue = int.parse(colorHex, radix: 16);
    final baseColor = Color(0xFF000000 | colorValue);

    // Apply opacity
    paint.color = baseColor.withOpacity(stroke.style.opacity);

    // Apply stroke type specific styles
    switch (stroke.style.type) {
      case StrokeType.pen:
        // Standard pen stroke
        break;
      case StrokeType.highlighter:
        // Highlighter with lower opacity and wider stroke
        paint.strokeWidth = stroke.style.width * 1.5;
        paint.color = paint.color.withOpacity(0.4);
        break;
      case StrokeType.eraser:
        // Eraser uses white color with blend mode
        paint.color = Colors.white;
        paint.blendMode = BlendMode.clear;
        break;
    }

    // Build path from points
    final path = Path();
    
    if (stroke.points.length == 1) {
      // Single point - draw a circle
      final point = stroke.points.first;
      canvas.drawCircle(
        Offset(point.x, point.y),
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
    } else {
      // Multiple points - draw smooth path
      path.moveTo(stroke.points.first.x, stroke.points.first.y);

      // Use quadratic bezier curves for smoothness
      for (int i = 1; i < stroke.points.length - 1; i++) {
        final current = stroke.points[i];
        final next = stroke.points[i + 1];
        
        // Calculate control point
        final controlX = (current.x + next.x) / 2;
        final controlY = (current.y + next.y) / 2;
        
        path.quadraticBezierTo(
          current.x,
          current.y,
          controlX,
          controlY,
        );
      }

      // Draw last segment
      final lastPoint = stroke.points.last;
      path.lineTo(lastPoint.x, lastPoint.y);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    // Repaint if strokes or drawings changed
    return strokes.length != oldDelegate.strokes.length ||
        drawings.length != oldDelegate.drawings.length;
  }
}
