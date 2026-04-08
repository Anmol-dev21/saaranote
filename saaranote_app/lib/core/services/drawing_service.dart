import 'dart:convert';
import 'dart:math' as math;
import '../../domain/entities/drawing.dart';

/// Service for handling drawing operations
/// Provides stroke optimization, serialization, and utilities
class DrawingService {
  /// Optimize stroke by reducing points using Douglas-Peucker algorithm
  /// Tolerance: maximum distance a point can be from the simplified line
  DrawingStroke optimizeStroke(DrawingStroke stroke, {double tolerance = 2.0}) {
    if (stroke.points.length <= 2) {
      return stroke; // Can't optimize 2 or fewer points
    }

    final optimizedPoints = _douglasPeucker(stroke.points, tolerance);

    return DrawingStroke(
      id: stroke.id,
      points: optimizedPoints,
      style: stroke.style,
      createdAt: stroke.createdAt,
    );
  }

  /// Optimize entire drawing
  Drawing optimizeDrawing(Drawing drawing, {double tolerance = 2.0}) {
    final optimizedStrokes = drawing.strokes
        .map((stroke) => optimizeStroke(stroke, tolerance: tolerance))
        .toList();

    return Drawing(
      id: drawing.id,
      strokes: optimizedStrokes,
      createdAt: drawing.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Serialize drawing to JSON string
  String serializeDrawing(Drawing drawing) {
    final data = {
      'id': drawing.id,
      'strokes': drawing.strokes.map((stroke) => _serializeStroke(stroke)).toList(),
      'createdAt': drawing.createdAt.toIso8601String(),
      'updatedAt': drawing.updatedAt.toIso8601String(),
    };

    return jsonEncode(data);
  }

  /// Deserialize drawing from JSON string
  Drawing? deserializeDrawing(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final strokes = (data['strokes'] as List)
          .map((strokeData) => _deserializeStroke(strokeData))
          .whereType<DrawingStroke>()
          .toList();

      return Drawing(
        id: data['id'] as String,
        strokes: strokes,
        createdAt: DateTime.parse(data['createdAt'] as String),
        updatedAt: DateTime.parse(data['updatedAt'] as String),
      );
    } catch (e) {
      return null; // Invalid JSON
    }
  }

  /// Calculate estimated size in bytes
  int estimateSize(Drawing drawing) {
    // Rough estimate: each point is ~32 bytes (x, y, pressure, timestamp)
    // Plus overhead for stroke metadata
    int pointsSize = drawing.totalPoints * 32;
    int strokesOverhead = drawing.strokes.length * 64;
    return pointsSize + strokesOverhead;
  }

  /// Check if drawing exceeds recommended size
  bool exceedsRecommendedSize(Drawing drawing, {int maxBytes = 1024 * 1024}) {
    return estimateSize(drawing) > maxBytes;
  }

  // Private helper: Douglas-Peucker algorithm for line simplification
  List<StrokePoint> _douglasPeucker(List<StrokePoint> points, double tolerance) {
    if (points.length <= 2) return points;

    // Find point with maximum distance from line between first and last
    double maxDistance = 0.0;
    int index = 0;

    final first = points.first;
    final last = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], first, last);
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }

    // If max distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      final left = _douglasPeucker(points.sublist(0, index + 1), tolerance);
      final right = _douglasPeucker(points.sublist(index), tolerance);

      // Combine results (removing duplicate point at junction)
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      // All points can be removed except endpoints
      return [first, last];
    }
  }

  // Calculate perpendicular distance from point to line
  double _perpendicularDistance(StrokePoint point, StrokePoint lineStart, StrokePoint lineEnd) {
    final dx = lineEnd.x - lineStart.x;
    final dy = lineEnd.y - lineStart.y;

    if (dx == 0 && dy == 0) {
      // Line is a point
      return _euclideanDistance(point, lineStart);
    }

    final numerator = ((point.x - lineStart.x) * dy - (point.y - lineStart.y) * dx).abs();
    final denominator = _euclideanDistance(lineStart, lineEnd);

    return numerator / denominator;
  }

  // Calculate Euclidean distance between two points
  double _euclideanDistance(StrokePoint a, StrokePoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  // Serialize stroke to map
  Map<String, dynamic> _serializeStroke(DrawingStroke stroke) {
    return {
      'id': stroke.id,
      'points': stroke.points.map((p) => _serializePoint(p)).toList(),
      'style': _serializeStyle(stroke.style),
      'createdAt': stroke.createdAt.toIso8601String(),
    };
  }

  // Deserialize stroke from map
  DrawingStroke? _deserializeStroke(dynamic data) {
    try {
      final strokeData = data as Map<String, dynamic>;
      
      final points = (strokeData['points'] as List)
          .map((p) => _deserializePoint(p))
          .whereType<StrokePoint>()
          .toList();

      final style = _deserializeStyle(strokeData['style']);
      if (style == null) return null;

      return DrawingStroke(
        id: strokeData['id'] as String,
        points: points,
        style: style,
        createdAt: DateTime.parse(strokeData['createdAt'] as String),
      );
    } catch (e) {
      return null;
    }
  }

  // Serialize point to map
  Map<String, dynamic> _serializePoint(StrokePoint point) {
    return {
      'x': point.x,
      'y': point.y,
      if (point.pressure != null) 'pressure': point.pressure,
      if (point.timestamp != null) 'timestamp': point.timestamp!.toIso8601String(),
    };
  }

  // Deserialize point from map
  StrokePoint? _deserializePoint(dynamic data) {
    try {
      final pointData = data as Map<String, dynamic>;
      return StrokePoint(
        x: (pointData['x'] as num).toDouble(),
        y: (pointData['y'] as num).toDouble(),
        pressure: pointData['pressure'] != null 
            ? (pointData['pressure'] as num).toDouble() 
            : null,
        timestamp: pointData['timestamp'] != null
            ? DateTime.parse(pointData['timestamp'] as String)
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  // Serialize style to map
  Map<String, dynamic> _serializeStyle(StrokeStyle style) {
    return {
      'color': style.color,
      'width': style.width,
      'type': style.type.name,
      'opacity': style.opacity,
    };
  }

  // Deserialize style from map
  StrokeStyle? _deserializeStyle(dynamic data) {
    try {
      final styleData = data as Map<String, dynamic>;
      return StrokeStyle(
        color: styleData['color'] as String,
        width: (styleData['width'] as num).toDouble(),
        type: StrokeType.values.firstWhere(
          (t) => t.name == styleData['type'],
          orElse: () => StrokeType.pen,
        ),
        opacity: (styleData['opacity'] as num).toDouble(),
      );
    } catch (e) {
      return null;
    }
  }
}
