# File Organization System Documentation

## Overview
The File Organization System is an automatic study material organizer for SAARANOTE that manages PDFs, images, notes, and other files. It provides automatic folder creation, subject detection, and SQLite-based file indexing while maintaining offline-first architecture.

## Architecture

### Domain Layer

#### Entities
- **FileMetadata** (`lib/domain/entities/file_metadata.dart`)
  - Core entity representing a tracked file
  - Properties: id, filePath, fileName, fileType, subject, createdAt, lastModified, fileSize, relatedNoteId, organizationStatus, customFolder, tags
  - Methods: `getTargetFolder()`, `isOrganized`, `hasManualOverride`, `copyWith()`
  - Folder structure: `{subject}/{YYYY-MM}/{type}`

- **FileType** (enum)
  - Values: pdf, image, note, other
  - Factory: `FileType.fromExtension(String extension)`

- **OrganizationStatus** (enum)
  - Values: pending, organized, failed, manual
  - Tracks file processing state

- **OrganizationRule**
  - Pattern-based organization rules
  - Properties: id, name, subjectPattern, fileType, targetFolder, priority, isEnabled
  - Allows customization of automatic organization

#### Repository Interface
- **FileOrganizationRepository** (`lib/domain/repositories/file_organization_repository.dart`)
  - Abstract interface for file indexing operations
  - CRUD operations: addFile, getFileById, getFileByPath, updateFile, deleteFile
  - Query operations: getFilesBySubject, getFilesByType, getFilesByStatus, getFilesByDateRange, searchFiles
  - Statistics: getStorageStats, getAllSubjects
  - Rules management: addRule, getAllRules, updateRule, deleteRule

#### Use Cases
1. **OrganizeFileUseCase** (`lib/domain/usecases/organize_file_usecase.dart`)
   - Organizes a single file automatically
   - Auto-detects subject if not provided
   - Creates FileMetadata and moves file to organized location
   - Handles existing file conflicts
   - Updates repository with organization status

2. **BatchOrganizeFilesUseCase** (`lib/domain/usecases/batch_organize_files_usecase.dart`)
   - Organizes multiple files in batch
   - Collects results and errors
   - Returns BatchOrganizeResult with success/error counts
   - Continues processing even if individual files fail

3. **MoveFileManuallyUseCase** (`lib/domain/usecases/move_file_manually_usecase.dart`)
   - Allows manual override of automatic organization
   - Moves file to custom location
   - Updates metadata with OrganizationStatus.manual
   - Supports renaming during move

4. **GetOrganizedFilesUseCase** (`lib/domain/usecases/get_organized_files_usecase.dart`)
   - Query organized files by various criteria
   - Methods: execute() (all files), bySubject(), byType(), byDateRange(), search(), getAllSubjects()

5. **GetStorageStatsUseCase** (`lib/domain/usecases/get_storage_stats_usecase.dart`)
   - Get storage statistics
   - Returns StorageStats with: totalFiles, totalSize, availableSpace, filesByType, filesBySubject
   - Provides formatting methods for display

### Core Services

#### FileOrganizationService
- **Location**: `lib/core/services/file_organization_service.dart`
- **Purpose**: Core file operations (separate from storage/note logic)
- **Key Methods**:
  - `organizeFile()`: Move file to organized location based on rules
  - `createFolderStructure()`: Create subject/date/type folder hierarchy
  - `detectSubject()`: Auto-detect subject from filename and content
  - `moveFileManually()`: Manual file movement with custom location
  - `renameFile()`: Rename file within organization system
  - `deleteFile()`: Delete file and cleanup empty folders
  - `getFolderSize()`: Calculate folder size recursively
  - `getAvailableSpace()`: Get available storage space
  - `cleanupEmptyFolders()`: Remove empty folder structures

- **Subject Detection**:
  - Regex patterns for common subjects (math, science, history, etc.)
  - Content keyword analysis for PDFs
  - Fallback to "General" if no subject detected

- **File Conflict Resolution**:
  - Automatically appends counter suffix: `file (1).pdf`, `file (2).pdf`, etc.

### Data Layer

#### Models
- **FileMetadataModel** (`lib/data/models/file_metadata_model.dart`)
  - Extends FileMetadata entity
  - Provides database serialization
  - Methods: fromEntity(), fromMap(), toMap(), toEntity()
  - Tags stored as JSON string in database

- **OrganizationRuleModel**
  - Extends OrganizationRule entity
  - Database serialization for rules
  - Methods: fromEntity(), fromMap(), toMap(), toEntity()

#### Repository Implementation
- **FileOrganizationRepositoryImpl** (`lib/data/repositories/file_organization_repository_impl.dart`)
  - Implements FileOrganizationRepository interface
  - Uses SQLite via DatabaseHelper
  - All CRUD and query operations
  - Statistics aggregation with SQL GROUP BY

#### Database Schema
- **Database Version**: 3 (upgraded from 2)
- **Tables**:

  **file_metadata**:
  ```sql
  CREATE TABLE file_metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_path TEXT NOT NULL UNIQUE,
    file_name TEXT NOT NULL,
    file_type INTEGER NOT NULL,
    subject TEXT,
    created_at INTEGER NOT NULL,
    last_modified INTEGER,
    file_size INTEGER NOT NULL,
    related_note_id TEXT,
    organization_status INTEGER DEFAULT 0,
    custom_folder TEXT,
    tags TEXT
  )
  ```

  **organization_rules**:
  ```sql
  CREATE TABLE organization_rules (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    subject_pattern TEXT,
    file_type INTEGER,
    target_folder TEXT NOT NULL,
    priority INTEGER DEFAULT 0,
    is_enabled INTEGER DEFAULT 1
  )
  ```

- **Indexes**:
  - `idx_file_metadata_subject ON file_metadata(subject)`
  - `idx_file_metadata_type ON file_metadata(file_type)`
  - `idx_file_metadata_status ON file_metadata(organization_status)`
  - `idx_file_metadata_created ON file_metadata(created_at DESC)`
  - `idx_organization_rules_priority ON organization_rules(priority DESC)`

## Folder Structure

### Automatic Organization
Files are organized into a predictable hierarchy:
```
{baseStoragePath}/
  ├── Mathematics/
  │   ├── 2025-01/
  │   │   ├── pdf/
  │   │   │   ├── calculus_notes.pdf
  │   │   │   └── algebra_homework.pdf
  │   │   ├── image/
  │   │   │   └── graph_sketch.png
  │   │   └── note/
  │   │       └── study_note_123.txt
  │   └── 2025-02/
  │       └── ...
  ├── Physics/
  │   └── 2025-01/
  │       └── ...
  └── General/
      └── ...
```

### Folder Naming Rules
- **Subject**: Auto-detected or user-specified (e.g., "Mathematics", "Physics")
- **Date**: YYYY-MM format based on file creation date
- **Type**: pdf, image, note, other (based on FileType)

## Usage Examples

### Example 1: Organize Single File
```dart
final organizeUseCase = OrganizeFileUseCase(
  repository: fileOrganizationRepository,
  fileService: fileOrganizationService,
);

final result = await organizeUseCase.execute(
  OrganizeFileParams(
    filePath: '/storage/downloads/math_homework.pdf',
    subject: 'Mathematics', // Optional, will auto-detect if omitted
    autoDetectSubject: true,
    tags: {'semester': '1', 'year': '2025'},
  ),
);

print('File organized to: ${result.filePath}');
```

### Example 2: Batch Organize Files
```dart
final batchUseCase = BatchOrganizeFilesUseCase(
  repository: fileOrganizationRepository,
  organizeFileUseCase: organizeUseCase,
);

final result = await batchUseCase.execute([
  '/storage/downloads/file1.pdf',
  '/storage/downloads/file2.png',
  '/storage/downloads/file3.pdf',
]);

print('Organized: ${result.successCount}, Failed: ${result.errorCount}');
for (final file in result.organizedFiles) {
  print('  ✓ ${file.fileName}');
}
for (final entry in result.errors.entries) {
  print('  ✗ ${entry.key}: ${entry.value}');
}
```

### Example 3: Manual Override
```dart
final moveUseCase = MoveFileManuallyUseCase(
  repository: fileOrganizationRepository,
  fileService: fileOrganizationService,
);

await moveUseCase.execute(
  MoveFileParams(
    fileId: 123,
    targetFolder: '/storage/my_custom_folder',
    newFileName: 'important_notes.pdf', // Optional
  ),
);
```

### Example 4: Query Files
```dart
final queryUseCase = GetOrganizedFilesUseCase(repository);

// Get all Mathematics files
final mathFiles = await queryUseCase.bySubject('Mathematics');

// Search by filename
final searchResults = await queryUseCase.search('calculus');

// Get files by date range
final januaryFiles = await queryUseCase.byDateRange(
  DateTime(2025, 1, 1),
  DateTime(2025, 1, 31),
);
```

### Example 5: Storage Statistics
```dart
final statsUseCase = GetStorageStatsUseCase(
  repository: fileOrganizationRepository,
  fileService: fileOrganizationService,
);

final stats = await statsUseCase.execute();
print('Total Files: ${stats.totalFiles}');
print('Total Size: ${stats.formattedTotalSize}');
print('Available: ${stats.formattedAvailableSpace}');
print('PDF Files: ${stats.filesByType[FileType.pdf]}');
```

## Key Features

### 1. Automatic Subject Detection
- Filename pattern matching (e.g., "math_homework.pdf" → "Mathematics")
- Content analysis for PDFs (keyword extraction)
- Fallback to "General" for unknown subjects
- Manual override always available

### 2. Offline-First Architecture
- All operations work without network connection
- SQLite-based file index for fast queries
- Local file system management
- No cloud dependencies

### 3. Manual Override Support
- Users can move files to custom locations
- OrganizationStatus.manual tracks user-organized files
- Custom folder paths preserved in database
- Original automatic organization rules still apply to new files

### 4. File Conflict Resolution
- Automatic counter suffix for duplicate filenames
- Preserves both files (no overwriting)
- Format: `filename (1).ext`, `filename (2).ext`, etc.

### 5. Storage Management
- Track total storage usage
- Monitor available space
- Cleanup empty folders automatically
- Calculate folder sizes recursively

### 6. Search and Query
- Search by filename and subject
- Filter by file type, subject, date range, status
- Get all unique subjects
- Full-text search support

### 7. Organization Rules
- Pattern-based automatic organization
- Priority system for rule conflicts
- Enable/disable rules dynamically
- Custom target folders per rule

## Migration Notes

### Database Migration v2 → v3
- Adds two new tables: `file_metadata`, `organization_rules`
- Creates indexes for query performance
- Backward compatible (no changes to existing tables)
- Automatic migration on app upgrade

### Integration with Existing Code
- **Does NOT modify**: Existing note storage, DatabaseHelper core logic
- **Adds**: New tables and indexes only
- **Separates**: File organization from note management
- **Independent**: Can be disabled without affecting notes

## Future Enhancements

### Phase 1 (Current)
- ✅ Domain entities and use cases
- ✅ Core file operations service
- ✅ SQLite file index
- ✅ Automatic subject detection
- ✅ Manual override support

### Phase 2 (Next)
- [ ] UI for file browser
- [ ] Batch import from device storage
- [ ] File preview integration
- [ ] Subject management screen
- [ ] Organization rules UI

### Phase 3 (Future)
- [ ] OCR text extraction for better subject detection
- [ ] Duplicate file detection
- [ ] File compression for large PDFs
- [ ] Export/backup organized files
- [ ] Cloud sync support (optional)

## Testing Checklist

### Unit Tests
- [ ] FileMetadata.getTargetFolder() returns correct path
- [ ] FileType.fromExtension() handles all extensions
- [ ] FileOrganizationService.detectSubject() accuracy
- [ ] FileOrganizationService.organizeFile() creates folders
- [ ] FileOrganizationService handles file conflicts
- [ ] Repository queries return correct results
- [ ] Use cases handle errors gracefully

### Integration Tests
- [ ] Organize single file end-to-end
- [ ] Batch organize multiple files
- [ ] Manual override works correctly
- [ ] Database migration v2 → v3 succeeds
- [ ] File deletion cleans up empty folders
- [ ] Storage statistics accurate
- [ ] Search returns relevant results

### Manual Testing
- [ ] Import PDF from downloads
- [ ] Verify automatic subject detection
- [ ] Check folder structure creation
- [ ] Move file manually to custom folder
- [ ] Search for files by name/subject
- [ ] View storage statistics
- [ ] Delete organized file
- [ ] Verify empty folder cleanup

## Performance Considerations

### Database Optimization
- Indexed queries for fast lookups
- Batch inserts for multiple files
- Lazy loading for large result sets
- Query result caching where appropriate

### File System Optimization
- Asynchronous file operations (non-blocking)
- Parallel batch processing where safe
- Minimize disk I/O during queries
- Efficient folder size calculations

### Memory Management
- Stream large file lists instead of loading all
- Dispose database connections properly
- Clear caches when memory pressure detected
- Use FileMetadata references instead of full file data

## Error Handling

### Common Errors
1. **FileSystemException**: File not found, permission denied
   - Handled in FileOrganizationService
   - Returns error to use case
   - Marked as OrganizationStatus.failed in database

2. **DatabaseException**: SQLite errors during queries
   - Logged for debugging
   - Returns empty results or null
   - Does not crash app

3. **StorageFullException**: No available disk space
   - Checked before file operations
   - User notified to free space
   - Operation cancelled gracefully

### Error Recovery
- Failed organizations can be retried
- Database transactions ensure data consistency
- File moves are atomic (copy + delete original)
- Rollback on failure prevents data loss

## Security Considerations

### File Access
- Only access app's storage directory
- No system file access
- User permissions required for external storage
- Validate file paths to prevent directory traversal

### Data Privacy
- File index stored locally only
- No file content uploaded to cloud
- Tags and metadata remain on device
- User controls all data

### Input Validation
- Sanitize filenames to prevent injection
- Validate file extensions
- Check file size limits
- Prevent path traversal attacks

## Summary

The File Organization System provides automatic, intelligent organization of study materials with:
- Clean Architecture following domain-driven design
- Offline-first SQLite-based file indexing
- Automatic subject detection with manual override
- Predictable folder structure (subject/date/type)
- Comprehensive query and statistics APIs
- No modifications to existing note storage logic
- Extensible rule-based organization system

Total Implementation: ~1,300 lines of code
- Domain layer: 5 entities + 1 repository interface + 5 use cases (~600 lines)
- Service layer: FileOrganizationService (~300 lines)
- Data layer: 2 models + repository implementation + database schema (~400 lines)
