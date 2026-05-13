import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SourceFileService {
  final String _rootFolderName;

  SourceFileService({String rootFolderName = 'saaranote'})
      : _rootFolderName = rootFolderName;

  Future<File> persistFile(
    File sourceFile, {
    required String category,
    String? preferredName,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final folder = Directory(
      path.join(appDir.path, _rootFolderName, 'source_files', category),
    );

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final baseName = preferredName != null && preferredName.trim().isNotEmpty
        ? preferredName.trim()
        : path.basename(sourceFile.path);

    final ext = path.extension(baseName);
    final stem = path.basenameWithoutExtension(baseName).trim();
    final safeStem = stem.isEmpty ? 'source' : stem;

    var targetPath = path.join(folder.path, '$safeStem$ext');
    if (await File(targetPath).exists()) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      targetPath = path.join(folder.path, '${safeStem}_$timestamp$ext');
    }

    return sourceFile.copy(targetPath);
  }
}
