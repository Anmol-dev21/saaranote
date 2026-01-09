import 'dart:io';
import 'package:path/path.dart' as path;
import '../../domain/entities/file_metadata.dart';

/// Core service for automatic file organization
/// Handles folder creation, file moving, and indexing
class FileOrganizationService {
  final String baseStoragePath;

  FileOrganizationService(this.baseStoragePath);

  /// Organize a file according to the target folder structure
  /// Returns the new file path after organization
  Future<String> organizeFile(FileMetadata metadata) async {
    final file = File(metadata.filePath);
    
    if (!await file.exists()) {
      throw FileSystemException('File not found', metadata.filePath);
    }

    // Get target folder path
    final targetFolder = metadata.getTargetFolder();
    final fullTargetPath = path.join(baseStoragePath, targetFolder);

    // Create folder structure
    await createFolderStructure(fullTargetPath);

    // Generate unique filename if conflict exists
    final targetFilePath = await _getUniqueFilePath(
      fullTargetPath,
      metadata.fileName,
    );

    // Move file to organized location
    await file.copy(targetFilePath);
    await file.delete(); // Remove original

    return targetFilePath;
  }

  /// Create folder structure recursively
  Future<void> createFolderStructure(String folderPath) async {
    final directory = Directory(folderPath);
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// Detect subject from file name or content
  Future<String?> detectSubject(String fileName, {String? content}) async {
    // Extract potential subject from filename
    final subject = _extractSubjectFromFileName(fileName);
    
    if (subject != null) return subject;

    // If content provided, analyze it
    if (content != null) {
      return _extractSubjectFromContent(content);
    }

    return null;
  }

  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Check if path is valid and writable
  Future<bool> isPathValid(String folderPath) async {
    try {
      final directory = Directory(folderPath);
      
      // Try to create a test file
      final testFile = File(path.join(folderPath, '.test'));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      await testFile.writeAsString('test');
      await testFile.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get storage usage for a folder
  Future<int> getFolderSize(String folderPath) async {
    final directory = Directory(folderPath);
    
    if (!await directory.exists()) {
      return 0;
    }

    int totalSize = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// List all files in a folder
  Future<List<String>> listFilesInFolder(String folderPath) async {
    final directory = Directory(folderPath);
    
    if (!await directory.exists()) {
      return [];
    }

    final files = <String>[];
    await for (final entity in directory.list(recursive: false)) {
      if (entity is File) {
        files.add(entity.path);
      }
    }

    return files;
  }

  /// Move file to custom location (manual override)
  Future<String> moveFileManually(
    String sourcePath,
    String targetFolder,
    String fileName,
  ) async {
    final sourceFile = File(sourcePath);
    
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file not found', sourcePath);
    }

    // Create target folder
    final fullTargetPath = path.join(baseStoragePath, targetFolder);
    await createFolderStructure(fullTargetPath);

    // Get unique filename
    final targetFilePath = await _getUniqueFilePath(fullTargetPath, fileName);

    // Move file
    await sourceFile.copy(targetFilePath);
    await sourceFile.delete();

    return targetFilePath;
  }

  /// Rename file in place
  Future<String> renameFile(String filePath, String newName) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final directory = path.dirname(filePath);
    final newPath = path.join(directory, newName);

    // Check for conflicts
    if (await File(newPath).exists()) {
      throw FileSystemException('File with that name already exists', newPath);
    }

    final renamed = await file.rename(newPath);
    return renamed.path;
  }

  /// Delete file from storage
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get available storage space
  Future<int> getAvailableSpace() async {
    // This is a simplified version. In production, use platform-specific APIs
    final directory = Directory(baseStoragePath);
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Placeholder - would need platform channels for real implementation
    return 1024 * 1024 * 1024; // 1GB placeholder
  }

  /// Clean up empty folders
  Future<void> cleanupEmptyFolders(String folderPath) async {
    final directory = Directory(folderPath);
    
    if (!await directory.exists()) return;

    await for (final entity in directory.list(recursive: true)) {
      if (entity is Directory) {
        final contents = await entity.list().toList();
        if (contents.isEmpty) {
          try {
            await entity.delete();
          } catch (e) {
            // Ignore deletion errors
          }
        }
      }
    }
  }

  /// Extract subject from filename using common patterns
  String? _extractSubjectFromFileName(String fileName) {
    // Remove extension
    final nameWithoutExt = path.basenameWithoutExtension(fileName);

    // Common subject patterns
    final patterns = [
      RegExp(r'^([A-Z][a-z]+)\s*[-_]', caseSensitive: false), // "Math - Chapter 1"
      RegExp(r'\[([A-Za-z\s]+)\]'), // "[Mathematics]"
      RegExp(r'\(([A-Za-z\s]+)\)'), // "(Physics)"
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(nameWithoutExt);
      if (match != null && match.groupCount > 0) {
        return match.group(1)?.trim();
      }
    }

    // Check if filename starts with common subject names
    final commonSubjects = [
      'Mathematics', 'Math', 'Physics', 'Chemistry', 'Biology',
      'English', 'History', 'Geography', 'Computer Science', 'CS',
      'Economics', 'Business', 'Accounting', 'Statistics',
    ];

    for (final subject in commonSubjects) {
      if (nameWithoutExt.toLowerCase().startsWith(subject.toLowerCase())) {
        return subject;
      }
    }

    return null;
  }

  /// Extract subject from content using keywords
  String? _extractSubjectFromContent(String content) {
    // Analyze first 500 characters for subject keywords
    final snippet = content.length > 500 ? content.substring(0, 500) : content;

    final subjectKeywords = {
      'Mathematics': ['equation', 'theorem', 'algebra', 'geometry', 'calculus'],
      'Physics': ['force', 'energy', 'motion', 'velocity', 'acceleration'],
      'Chemistry': ['molecule', 'reaction', 'element', 'compound', 'atom'],
      'Biology': ['cell', 'organism', 'species', 'evolution', 'genetic'],
      'Computer Science': ['algorithm', 'programming', 'code', 'function', 'class'],
    };

    final lowerContent = snippet.toLowerCase();
    int maxMatches = 0;
    String? detectedSubject;

    for (final entry in subjectKeywords.entries) {
      int matches = 0;
      for (final keyword in entry.value) {
        if (lowerContent.contains(keyword)) {
          matches++;
        }
      }

      if (matches > maxMatches) {
        maxMatches = matches;
        detectedSubject = entry.key;
      }
    }

    return maxMatches >= 2 ? detectedSubject : null;
  }

  /// Get unique file path to avoid conflicts
  Future<String> _getUniqueFilePath(String directory, String fileName) async {
    String targetPath = path.join(directory, fileName);
    
    if (!await File(targetPath).exists()) {
      return targetPath;
    }

    // Add counter to filename
    final extension = path.extension(fileName);
    final nameWithoutExt = path.basenameWithoutExtension(fileName);

    int counter = 1;
    while (true) {
      final newName = '${nameWithoutExt}_$counter$extension';
      targetPath = path.join(directory, newName);
      
      if (!await File(targetPath).exists()) {
        return targetPath;
      }
      
      counter++;
      
      // Safety limit
      if (counter > 1000) {
        throw Exception('Too many file conflicts');
      }
    }
  }

  /// Format bytes to human-readable size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
