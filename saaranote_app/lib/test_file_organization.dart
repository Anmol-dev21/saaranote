import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../domain/entities/file_metadata.dart';
import '../domain/repositories/file_organization_repository.dart';
import '../core/services/file_organization_service.dart';
import '../domain/usecases/organize_file_usecase.dart';
import '../domain/usecases/get_storage_stats_usecase.dart';
import '../data/repositories/file_organization_repository_impl.dart';
import '../data/datasources/local/database_helper.dart';

/// Quick integration test for file organization system
/// Run this to verify the system works end-to-end
Future<void> testFileOrganizationSystem() async {
  print('🧪 Testing File Organization System...\n');

  try {
    // 1. Setup
    print('1️⃣ Setting up dependencies...');
    final databaseHelper = DatabaseHelper.instance;
    final repository = FileOrganizationRepositoryImpl(databaseHelper);
    final appDir = await getApplicationDocumentsDirectory();
    final baseStoragePath = '${appDir.path}/saaranote/organized_files';
    final fileService = FileOrganizationService(baseStoragePath);
    
    final organizeUseCase = OrganizeFileUseCase(
      repository: repository,
      fileService: fileService,
    );
    
    final statsUseCase = GetStorageStatsUseCase(
      repository: repository,
      fileService: fileService,
    );
    print('   ✅ Dependencies initialized\n');

    // 2. Test subject detection
    print('2️⃣ Testing subject detection...');
    final mathSubject = fileService.detectSubject('calculus_homework.pdf', null);
    final physicsSubject = fileService.detectSubject('physics_lab_report.pdf', null);
    final unknownSubject = fileService.detectSubject('random_file.txt', null);
    
    print('   • calculus_homework.pdf → $mathSubject');
    print('   • physics_lab_report.pdf → $physicsSubject');
    print('   • random_file.txt → $unknownSubject');
    
    assert(mathSubject == 'Mathematics', 'Math detection failed');
    assert(physicsSubject == 'Physics', 'Physics detection failed');
    assert(unknownSubject == 'General', 'Unknown detection failed');
    print('   ✅ Subject detection working\n');

    // 3. Test folder structure generation
    print('3️⃣ Testing folder structure...');
    final testMetadata = FileMetadata(
      filePath: '/tmp/test.pdf',
      fileName: 'test.pdf',
      fileType: FileType.pdf,
      subject: 'Mathematics',
      createdAt: DateTime.now(),
      fileSize: 1024,
    );
    
    final targetFolder = testMetadata.getTargetFolder(baseStoragePath);
    print('   • Target folder: $targetFolder');
    
    final expectedPattern = RegExp(r'.*/Mathematics/\d{4}-\d{2}/pdf$');
    assert(expectedPattern.hasMatch(targetFolder), 'Folder structure incorrect');
    print('   ✅ Folder structure correct\n');

    // 4. Test database operations
    print('4️⃣ Testing database operations...');
    
    // Add a test file
    final testFile = FileMetadata(
      filePath: '/test/sample.pdf',
      fileName: 'sample.pdf',
      fileType: FileType.pdf,
      subject: 'Testing',
      createdAt: DateTime.now(),
      fileSize: 2048,
      organizationStatus: OrganizationStatus.organized,
      tags: {'test': 'true', 'category': 'integration'},
    );
    
    final addedFile = await repository.addFile(testFile);
    print('   • Added file with ID: ${addedFile.id}');
    
    // Retrieve file
    final retrievedFile = await repository.getFileById(addedFile.id!);
    assert(retrievedFile != null, 'File not found');
    assert(retrievedFile!.fileName == 'sample.pdf', 'File name mismatch');
    print('   • Retrieved file: ${retrievedFile.fileName}');
    
    // Query by subject
    final testingFiles = await repository.getFilesBySubject('Testing');
    assert(testingFiles.isNotEmpty, 'No files found for Testing subject');
    print('   • Found ${testingFiles.length} file(s) for Testing subject');
    
    // Update file
    final updatedFile = await repository.updateFile(
      retrievedFile.copyWith(
        organizationStatus: OrganizationStatus.manual,
        customFolder: '/custom/path',
      ),
    );
    print('   • Updated organization status to: ${updatedFile.organizationStatus}');
    
    // Get all subjects
    final subjects = await repository.getAllSubjects();
    print('   • Available subjects: ${subjects.join(", ")}');
    
    // Clean up test file
    await repository.deleteFile(addedFile.id!);
    print('   • Cleaned up test file');
    print('   ✅ Database operations working\n');

    // 5. Test storage statistics
    print('5️⃣ Testing storage statistics...');
    final stats = await statsUseCase.execute();
    print('   • Total files: ${stats.totalFiles}');
    print('   • Total size: ${stats.formattedTotalSize}');
    print('   • Available space: ${stats.formattedAvailableSpace}');
    print('   • Files by type: ${stats.filesByType}');
    print('   ✅ Statistics working\n');

    // 6. Test organization rules
    print('6️⃣ Testing organization rules...');
    final testRule = OrganizationRule(
      id: 'test_rule_1',
      name: 'Math PDFs to Special Folder',
      subjectPattern: 'Math.*',
      fileType: FileType.pdf,
      targetFolder: '/special/math',
      priority: 10,
      isEnabled: true,
    );
    
    final addedRule = await repository.addRule(testRule);
    print('   • Added rule: ${addedRule.name}');
    
    final allRules = await repository.getAllRules();
    assert(allRules.isNotEmpty, 'No rules found');
    print('   • Total rules: ${allRules.length}');
    
    // Clean up test rule
    await repository.deleteRule(addedRule.id);
    print('   • Cleaned up test rule');
    print('   ✅ Organization rules working\n');

    print('✅ All tests passed! File organization system is working correctly.\n');
    
  } catch (e, stackTrace) {
    print('❌ Test failed with error:');
    print(e);
    print(stackTrace);
    rethrow;
  }
}

// Example usage:
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await testFileOrganizationSystem();
// }
