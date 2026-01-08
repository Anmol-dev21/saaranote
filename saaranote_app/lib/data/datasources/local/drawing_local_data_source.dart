import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/drawing.dart';
import '../../../core/services/drawing_service.dart';
import 'database_helper.dart';

/// Local data source for managing drawing data in SQLite
/// 
/// Drawings are stored separately from notes to optimize performance
/// and enable efficient storage management for large drawing data.
class DrawingLocalDataSource {
  final DatabaseHelper _databaseHelper;
  final DrawingService _drawingService;

  DrawingLocalDataSource(this._databaseHelper, this._drawingService);

  Future<Database> get _db async => await _databaseHelper.database;

  /// Save a drawing to the database
  /// 
  /// The drawing is serialized to JSON and optimized before storage.
  /// Returns the saved drawing with updated timestamp.
  Future<Drawing> saveDrawing(Drawing drawing, int noteId) async {
    final db = await _db;
    
    // Optimize the drawing to reduce storage size
    final optimized = _drawingService.optimizeDrawing(drawing);
    final serialized = _drawingService.serializeDrawing(optimized);
    
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final map = {
      'id': optimized.id,
      'note_id': noteId,
      'drawing_data': serialized,
      'created_at': optimized.createdAt.millisecondsSinceEpoch,
      'updated_at': now,
    };
    
    // Use INSERT OR REPLACE to handle both create and update
    await db.insert(
      'drawings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return optimized.copyWith(
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  /// Get a drawing by its ID
  Future<Drawing?> getDrawingById(String id) async {
    final db = await _db;
    
    final maps = await db.query(
      'drawings',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    final data = maps.first['drawing_data'] as String;
    return _drawingService.deserializeDrawing(data);
  }

  /// Get all drawings for a specific note
  Future<List<Drawing>> getDrawingsByNoteId(int noteId) async {
    final db = await _db;
    
    final maps = await db.query(
      'drawings',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at ASC',
    );
    
    return maps
        .map((map) {
          final data = map['drawing_data'] as String;
          return _drawingService.deserializeDrawing(data);
        })
        .whereType<Drawing>() // Filter out any null results
        .toList();
  }

  /// Get multiple drawings by their IDs
  Future<List<Drawing>> getDrawingsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    final db = await _db;
    
    // Create placeholders for the IN clause
    final placeholders = List.filled(ids.length, '?').join(',');
    
    final maps = await db.query(
      'drawings',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    
    return maps
        .map((map) {
          final data = map['drawing_data'] as String;
          return _drawingService.deserializeDrawing(data);
        })
        .whereType<Drawing>() // Filter out any null results
        .toList();
  }

  /// Delete a drawing by its ID
  Future<void> deleteDrawing(String id) async {
    final db = await _db;
    
    await db.delete(
      'drawings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all drawings for a specific note
  /// 
  /// This is typically called when a note is deleted to clean up
  /// associated drawing data.
  Future<void> deleteDrawingsByNoteId(int noteId) async {
    final db = await _db;
    
    await db.delete(
      'drawings',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }

  /// Get the total storage size used by a note's drawings
  /// 
  /// Returns the size in bytes. Useful for managing storage limits
  /// and displaying storage information to users.
  Future<int> getDrawingsStorageSize(int noteId) async {
    final db = await _db;
    
    final maps = await db.query(
      'drawings',
      columns: ['drawing_data'],
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
    
    int totalSize = 0;
    for (final map in maps) {
      final data = map['drawing_data'] as String;
      totalSize += data.length; // Approximate size in bytes
    }
    
    return totalSize;
  }

  /// Check if a note has any drawings
  Future<bool> hasDrawings(int noteId) async {
    final db = await _db;
    
    final result = await db.query(
      'drawings',
      columns: ['COUNT(*) as count'],
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
    
    final count = result.first['count'] as int;
    return count > 0;
  }
}
