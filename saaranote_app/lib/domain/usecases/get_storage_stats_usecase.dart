import '../../domain/repositories/file_organization_repository.dart';
import '../../core/services/file_organization_service.dart';

/// Use case for getting storage statistics
class GetStorageStatsUseCase {
  final FileOrganizationRepository _repository;
  final FileOrganizationService _service;

  GetStorageStatsUseCase(this._repository, this._service);

  Future<StorageStats> execute() async {
    final dbStats = await _repository.getStorageStats();
    
    final totalFiles = dbStats['total_files'] as int? ?? 0;
    final totalSize = dbStats['total_size'] as int? ?? 0;
    final byType = dbStats['by_type'] as Map<String, int>? ?? {};
    final bySubject = dbStats['by_subject'] as Map<String, int>? ?? {};

    // Get available space
    final availableSpace = await _service.getAvailableSpace();

    return StorageStats(
      totalFiles: totalFiles,
      totalSize: totalSize,
      availableSpace: availableSpace,
      filesByType: byType,
      filesBySubject: bySubject,
    );
  }
}

class StorageStats {
  final int totalFiles;
  final int totalSize;
  final int availableSpace;
  final Map<String, int> filesByType;
  final Map<String, int> filesBySubject;

  StorageStats({
    required this.totalFiles,
    required this.totalSize,
    required this.availableSpace,
    required this.filesByType,
    required this.filesBySubject,
  });

  double get usedSpacePercentage {
    final total = totalSize + availableSpace;
    return total > 0 ? (totalSize / total) * 100 : 0;
  }

  String formatTotalSize() {
    return _formatBytes(totalSize);
  }

  String formatAvailableSpace() {
    return _formatBytes(availableSpace);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
