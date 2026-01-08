/// Drawing stroke entity representing a single pen/brush stroke
/// Used for handwriting and free-draw canvas
class DrawingStroke {
  final String id;
  final List<StrokePoint> points;
  final StrokeStyle style;
  final DateTime createdAt;

  const DrawingStroke({
    required this.id,
    required this.points,
    required this.style,
    required this.createdAt,
  });

  /// Check if stroke is empty
  bool get isEmpty => points.isEmpty;

  /// Get bounding box of the stroke
  StrokeBounds get bounds {
    if (isEmpty) {
      return const StrokeBounds(
        minX: 0,
        minY: 0,
        maxX: 0,
        maxY: 0,
      );
    }

    double minX = points.first.x;
    double minY = points.first.y;
    double maxX = points.first.x;
    double maxY = points.first.y;

    for (final point in points) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }

    return StrokeBounds(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingStroke &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Point in a stroke with coordinates and optional pressure
class StrokePoint {
  final double x;
  final double y;
  final double? pressure; // 0.0 to 1.0, null if not supported
  final DateTime? timestamp;

  const StrokePoint({
    required this.x,
    required this.y,
    this.pressure,
    this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokePoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          pressure == other.pressure;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ pressure.hashCode;
}

/// Stroke style (pen color, width, etc.)
class StrokeStyle {
  final String color; // Hex color string
  final double width;
  final StrokeType type;
  final double opacity;

  const StrokeStyle({
    required this.color,
    required this.width,
    this.type = StrokeType.pen,
    this.opacity = 1.0,
  });

  /// Default pen style (black, 2px)
  static const StrokeStyle defaultPen = StrokeStyle(
    color: '#000000',
    width: 2.0,
    type: StrokeType.pen,
  );

  /// Default highlighter style (yellow, 8px, semi-transparent)
  static const StrokeStyle defaultHighlighter = StrokeStyle(
    color: '#FFFF00',
    width: 8.0,
    type: StrokeType.highlighter,
    opacity: 0.5,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokeStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          width == other.width &&
          type == other.type &&
          opacity == other.opacity;

  @override
  int get hashCode =>
      color.hashCode ^ width.hashCode ^ type.hashCode ^ opacity.hashCode;
}

/// Type of drawing stroke
enum StrokeType {
  pen,
  highlighter,
  eraser,
}

/// Bounding box for a stroke
class StrokeBounds {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  const StrokeBounds({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  double get width => maxX - minX;
  double get height => maxY - minY;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokeBounds &&
          runtimeType == other.runtimeType &&
          minX == other.minX &&
          minY == other.minY &&
          maxX == other.maxX &&
          maxY == other.maxY;

  @override
  int get hashCode =>
      minX.hashCode ^ minY.hashCode ^ maxX.hashCode ^ maxY.hashCode;
}

/// Complete drawing containing multiple strokes
class Drawing {
  final String id;
  final List<DrawingStroke> strokes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Drawing({
    required this.id,
    required this.strokes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if drawing is empty
  bool get isEmpty => strokes.isEmpty;

  /// Get total number of points in all strokes
  int get totalPoints => strokes.fold(0, (sum, stroke) => sum + stroke.points.length);

  /// Get bounding box of entire drawing
  StrokeBounds? get bounds {
    if (isEmpty) return null;

    final allBounds = strokes.map((s) => s.bounds).toList();
    
    double minX = allBounds.first.minX;
    double minY = allBounds.first.minY;
    double maxX = allBounds.first.maxX;
    double maxY = allBounds.first.maxY;

    for (final bound in allBounds) {
      if (bound.minX < minX) minX = bound.minX;
      if (bound.minY < minY) minY = bound.minY;
      if (bound.maxX > maxX) maxX = bound.maxX;
      if (bound.maxY > maxY) maxY = bound.maxY;
    }

    return StrokeBounds(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Drawing &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Create a copy of this drawing with optional modifications
  Drawing copyWith({
    String? id,
    List<DrawingStroke>? strokes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Drawing(
      id: id ?? this.id,
      strokes: strokes ?? this.strokes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
