import '../../domain/entities/drawing.dart';

/// Data model for Drawing entity
class DrawingModel {
  final String id;
  final List<StrokeModel> strokes;
  final String createdAt;
  final String updatedAt;

  const DrawingModel({
    required this.id,
    required this.strokes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from domain entity
  factory DrawingModel.fromEntity(Drawing drawing) {
    return DrawingModel(
      id: drawing.id,
      strokes: drawing.strokes.map((s) => StrokeModel.fromEntity(s)).toList(),
      createdAt: drawing.createdAt.toIso8601String(),
      updatedAt: drawing.updatedAt.toIso8601String(),
    );
  }

  /// Convert to domain entity
  Drawing toEntity() {
    return Drawing(
      id: id,
      strokes: strokes.map((s) => s.toEntity()).toList(),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  /// Convert from JSON map
  factory DrawingModel.fromMap(Map<String, dynamic> map) {
    return DrawingModel(
      id: map['id'] as String,
      strokes: (map['strokes'] as List)
          .map((s) => StrokeModel.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'strokes': strokes.map((s) => s.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

/// Data model for DrawingStroke
class StrokeModel {
  final String id;
  final List<PointModel> points;
  final StyleModel style;
  final String createdAt;

  const StrokeModel({
    required this.id,
    required this.points,
    required this.style,
    required this.createdAt,
  });

  factory StrokeModel.fromEntity(DrawingStroke stroke) {
    return StrokeModel(
      id: stroke.id,
      points: stroke.points.map((p) => PointModel.fromEntity(p)).toList(),
      style: StyleModel.fromEntity(stroke.style),
      createdAt: stroke.createdAt.toIso8601String(),
    );
  }

  DrawingStroke toEntity() {
    return DrawingStroke(
      id: id,
      points: points.map((p) => p.toEntity()).toList(),
      style: style.toEntity(),
      createdAt: DateTime.parse(createdAt),
    );
  }

  factory StrokeModel.fromMap(Map<String, dynamic> map) {
    return StrokeModel(
      id: map['id'] as String,
      points: (map['points'] as List)
          .map((p) => PointModel.fromMap(p as Map<String, dynamic>))
          .toList(),
      style: StyleModel.fromMap(map['style'] as Map<String, dynamic>),
      createdAt: map['createdAt'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'points': points.map((p) => p.toMap()).toList(),
      'style': style.toMap(),
      'createdAt': createdAt,
    };
  }
}

/// Data model for StrokePoint
class PointModel {
  final double x;
  final double y;
  final double? pressure;
  final String? timestamp;

  const PointModel({
    required this.x,
    required this.y,
    this.pressure,
    this.timestamp,
  });

  factory PointModel.fromEntity(StrokePoint point) {
    return PointModel(
      x: point.x,
      y: point.y,
      pressure: point.pressure,
      timestamp: point.timestamp?.toIso8601String(),
    );
  }

  StrokePoint toEntity() {
    return StrokePoint(
      x: x,
      y: y,
      pressure: pressure,
      timestamp: timestamp != null ? DateTime.parse(timestamp!) : null,
    );
  }

  factory PointModel.fromMap(Map<String, dynamic> map) {
    return PointModel(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      pressure: map['pressure'] != null ? (map['pressure'] as num).toDouble() : null,
      timestamp: map['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      if (pressure != null) 'pressure': pressure,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }
}

/// Data model for StrokeStyle
class StyleModel {
  final String color;
  final double width;
  final String type;
  final double opacity;

  const StyleModel({
    required this.color,
    required this.width,
    required this.type,
    required this.opacity,
  });

  factory StyleModel.fromEntity(StrokeStyle style) {
    return StyleModel(
      color: style.color,
      width: style.width,
      type: style.type.name,
      opacity: style.opacity,
    );
  }

  StrokeStyle toEntity() {
    return StrokeStyle(
      color: color,
      width: width,
      type: StrokeType.values.firstWhere(
        (t) => t.name == type,
        orElse: () => StrokeType.pen,
      ),
      opacity: opacity,
    );
  }

  factory StyleModel.fromMap(Map<String, dynamic> map) {
    return StyleModel(
      color: map['color'] as String,
      width: (map['width'] as num).toDouble(),
      type: map['type'] as String,
      opacity: (map['opacity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'width': width,
      'type': type,
      'opacity': opacity,
    };
  }
}
