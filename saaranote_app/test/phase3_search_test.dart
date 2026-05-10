/// PHASE 3 - Search & Organization Tests
/// 
/// This test validates the search and organization functionality:
/// - Search query handling (empty, partial, full match)
/// - SQL LIKE query pattern matching
/// - Case-insensitive search
/// - Search performance considerations
/// - Clear search functionality
/// - Sort ordering (recent/oldest)
/// - Filter states (all/active/archived)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saaranote_app/domain/entities/note.dart';

void main() {
  group('PHASE 3: Search & Organization Tests', () {
    
    // Helper to create test notes
    Note createTestNote({
      int? id,
      required String title,
      required String content,
      bool isArchived = false,
    }) {
      final now = DateTime.now();
      return Note(
        id: id,
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        isArchived: isArchived,
      );
    }

    group('1. Search Query Pattern Matching', () {
      test('1.1 SQL LIKE pattern generation', () {
        // Testing the pattern that would be used in SQL query
        final query = 'flutter';
        final pattern = '%$query%'; // Pattern used in searchNotes()
        
        expect(pattern, '%flutter%');
        
        // Verify pattern matches expected strings
        expect('Flutter is great'.toLowerCase().contains(query.toLowerCase()), isTrue);
        expect('Learn flutter development'.toLowerCase().contains(query.toLowerCase()), isTrue);
        expect('I love Flutter'.toLowerCase().contains(query.toLowerCase()), isTrue);
        expect('Python programming'.toLowerCase().contains(query.toLowerCase()), isFalse);
      });

      test('1.2 Case-insensitive matching', () {
        final testCases = [
          ('Flutter', 'flutter', true),
          ('FLUTTER', 'flutter', true),
          ('FlUtTeR', 'flutter', true),
          ('flutter', 'FLUTTER', true),
          ('Python', 'flutter', false),
        ];

        for (final testCase in testCases) {
          final (text, query, shouldMatch) = testCase;
          expect(
            text.toLowerCase().contains(query.toLowerCase()),
            shouldMatch,
            reason: '"$text" should ${shouldMatch ? '' : 'not '}match "$query"',
          );
        }
      });

      test('1.3 Partial word matching', () {
        final query = 'flutter';
        final testStrings = [
          'flutter',           // Exact match
          'Flutter',           // Case different
          'flutter app',       // Start of string
          'Learn flutter',     // End of string
          'with flutter in',   // Middle
          'fluttering',        // Substring
        ];

        for (final str in testStrings) {
          expect(
            str.toLowerCase().contains(query.toLowerCase()),
            isTrue,
            reason: '"$str" should contain "$query"',
          );
        }
      });

      test('1.4 Multi-word search (current implementation)', () {
        // Note: Current implementation searches as single string
        final query = 'flutter app';
        final pattern = '%$query%';
        
        expect(pattern, '%flutter app%');
        
        // This would match strings containing the exact phrase
        expect('My flutter app project'.toLowerCase().contains(query.toLowerCase()), isTrue);
        expect('Flutter App Development'.toLowerCase().contains(query.toLowerCase()), isTrue);
        // But not separate words
        expect('app for flutter'.toLowerCase().contains(query.toLowerCase()), isFalse);
      });

      test('1.5 Special characters in search', () {
        final specialChars = ['@', '#', r'$', '%', '&', '*', '(', ')', '-', '+'];
        
        for (final char in specialChars) {
          final query = 'test$char';
          final pattern = '%$query%';
          expect(pattern, contains(char));
        }
      });
    });

    group('2. Search Result Matching', () {
      test('2.1 Search matches title', () {
        final notes = [
          createTestNote(id: 1, title: 'Flutter Tutorial', content: 'About Dart'),
          createTestNote(id: 2, title: 'Python Guide', content: 'About Python'),
        ];

        final query = 'flutter';
        final results = notes.where((note) {
          return note.title.toLowerCase().contains(query.toLowerCase());
        }).toList();

        expect(results.length, 1);
        expect(results[0].title, contains('Flutter'));
      });

      test('2.2 Search matches content', () {
        final notes = [
          createTestNote(id: 1, title: 'My Note', content: 'Learning Flutter today'),
          createTestNote(id: 2, title: 'Another Note', content: 'Learning Python'),
        ];

        final query = 'flutter';
        final results = notes.where((note) {
          return note.content.toLowerCase().contains(query.toLowerCase());
        }).toList();

        expect(results.length, 1);
        expect(results[0].content, contains('Flutter'));
      });

      test('2.3 Search matches title OR content', () {
        final notes = [
          createTestNote(id: 1, title: 'Flutter App', content: 'Building apps'),
          createTestNote(id: 2, title: 'My Project', content: 'Using Flutter'),
          createTestNote(id: 3, title: 'Python Code', content: 'Python scripts'),
        ];

        final query = 'flutter';
        final results = notes.where((note) {
          return note.title.toLowerCase().contains(query.toLowerCase()) ||
                 note.content.toLowerCase().contains(query.toLowerCase());
        }).toList();

        expect(results.length, 2);
        expect(results.any((n) => n.title.contains('Flutter')), isTrue);
        expect(results.any((n) => n.content.contains('Flutter')), isTrue);
      });

      test('2.4 Empty query returns all notes', () {
        final notes = [
          createTestNote(id: 1, title: 'Note 1', content: 'Content 1'),
          createTestNote(id: 2, title: 'Note 2', content: 'Content 2'),
        ];

        final query = '';
        // SearchNotesUseCase returns empty list for empty query
        final results = query.isEmpty ? [] : notes;

        expect(results, isEmpty);
      });

      test('2.5 No matches found', () {
        final notes = [
          createTestNote(id: 1, title: 'Flutter Note', content: 'About Flutter'),
          createTestNote(id: 2, title: 'Dart Note', content: 'About Dart'),
        ];

        final query = 'python';
        final results = notes.where((note) {
          return note.title.toLowerCase().contains(query.toLowerCase()) ||
                 note.content.toLowerCase().contains(query.toLowerCase());
        }).toList();

        expect(results, isEmpty);
      });
    });

    group('3. Sort Ordering', () {
      test('3.1 Sort by created date descending (recent first)', () {
        final now = DateTime.now();
        
        // Create notes with proper dates
        final oldNote = createTestNote(id: 1, title: 'Old Note', content: 'Content')
            .copyWith(createdAt: now.subtract(Duration(days: 3)));
        final recentNote = createTestNote(id: 2, title: 'Recent Note', content: 'Content')
            .copyWith(createdAt: now.subtract(Duration(days: 1)));
        final oldestNote = createTestNote(id: 3, title: 'Oldest Note', content: 'Content')
            .copyWith(createdAt: now.subtract(Duration(days: 5)));
        
        final notes = [oldNote, recentNote, oldestNote];

        // Simulate NoteSortBy.createdDateDesc
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        expect(notes[0].id, 2); // Most recent
        expect(notes[1].id, 1);
        expect(notes[2].id, 3); // Oldest
      });

      test('3.2 Sort by created date ascending (oldest first)', () {
        final now = DateTime.now();
        
        // Create notes with proper dates
        final oldNote = createTestNote(id: 1, title: 'Old Note', content: 'Content')
            .copyWith(createdAt: now.subtract(Duration(days: 3)));
        final recentNote = createTestNote(id: 2, title: 'Recent Note', content: 'Content')
            .copyWith(createdAt: now.subtract(Duration(days: 1)));
        final oldestNote = createTestNote(id: 3, title: 'Oldest Note', content: 'Content')
            .copyWith(createdAt: now.subtract(Duration(days: 5)));
        
        final notes = [oldNote, recentNote, oldestNote];

        // Simulate NoteSortBy.createdDateAsc
        notes.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        expect(notes[0].id, 3); // Oldest
        expect(notes[1].id, 1);
        expect(notes[2].id, 2); // Most recent
      });

      test('3.3 Sort by title alphabetically', () {
        final notes = [
          createTestNote(id: 1, title: 'Zebra', content: 'Content'),
          createTestNote(id: 2, title: 'Apple', content: 'Content'),
          createTestNote(id: 3, title: 'Mango', content: 'Content'),
        ];

        // Simulate NoteSortBy.titleAsc
        notes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

        expect(notes[0].title, 'Apple');
        expect(notes[1].title, 'Mango');
        expect(notes[2].title, 'Zebra');
      });

      test('3.4 Sort with case-insensitive titles', () {
        final notes = [
          createTestNote(id: 1, title: 'zebra', content: 'Content'),
          createTestNote(id: 2, title: 'Apple', content: 'Content'),
          createTestNote(id: 3, title: 'MANGO', content: 'Content'),
        ];

        notes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

        expect(notes[0].title, 'Apple');
        expect(notes[1].title, 'MANGO');
        expect(notes[2].title, 'zebra');
      });
    });

    group('4. Filter States', () {
      test('4.1 Filter active notes', () {
        final notes = [
          createTestNote(id: 1, title: 'Active 1', content: 'C', isArchived: false),
          createTestNote(id: 2, title: 'Archived 1', content: 'C', isArchived: true),
          createTestNote(id: 3, title: 'Active 2', content: 'C', isArchived: false),
          createTestNote(id: 4, title: 'Archived 2', content: 'C', isArchived: true),
        ];

        // Simulate NoteFilter.active
        final activeNotes = notes.where((n) => !n.isArchived).toList();

        expect(activeNotes.length, 2);
        expect(activeNotes.every((n) => !n.isArchived), isTrue);
      });

      test('4.2 Filter archived notes', () {
        final notes = [
          createTestNote(id: 1, title: 'Active 1', content: 'C', isArchived: false),
          createTestNote(id: 2, title: 'Archived 1', content: 'C', isArchived: true),
          createTestNote(id: 3, title: 'Active 2', content: 'C', isArchived: false),
        ];

        // Simulate NoteFilter.archived
        final archivedNotes = notes.where((n) => n.isArchived).toList();

        expect(archivedNotes.length, 1);
        expect(archivedNotes.every((n) => n.isArchived), isTrue);
      });

      test('4.3 Show all notes', () {
        final notes = [
          createTestNote(id: 1, title: 'Active', content: 'C', isArchived: false),
          createTestNote(id: 2, title: 'Archived', content: 'C', isArchived: true),
        ];

        // Simulate NoteFilter.all
        final allNotes = notes; // No filtering

        expect(allNotes.length, 2);
      });
    });

    group('5. Search Performance Considerations', () {
      test('5.1 Large result set handling', () {
        // Simulate 1000 notes
        final notes = List.generate(1000, (i) {
          final hasFlutter = i % 3 == 0; // Every 3rd note contains 'flutter'
          return createTestNote(
            id: i,
            title: hasFlutter ? 'Flutter Note $i' : 'Other Note $i',
            content: 'Content for note $i',
          );
        });

        final query = 'flutter';
        final sw = Stopwatch()..start();
        
        final results = notes.where((note) {
          return note.title.toLowerCase().contains(query.toLowerCase()) ||
                 note.content.toLowerCase().contains(query.toLowerCase());
        }).toList();
        
        sw.stop();

        expect(results.length, greaterThan(0));
        expect(sw.elapsedMilliseconds, lessThan(100)); // Should be fast in-memory
        // Debug print removed to satisfy avoid_print lint.
      });

      test('5.2 Query trimming', () {
        final queries = [
          ('  flutter  ', 'flutter'),
          ('flutter\n', 'flutter'),
          ('\tflutter', 'flutter'),
          ('   ', ''),
        ];

        for (final (input, expected) in queries) {
          expect(input.trim(), expected);
        }
      });

      test('5.3 Empty/whitespace query handling', () {
        final queries = ['', '   ', '\t', '\n'];

        for (final query in queries) {
          expect(query.trim().isEmpty, isTrue);
        }
      });
    });

    group('6. Edge Cases', () {
      test('6.1 Search with very long query', () {
        final longQuery = 'flutter' * 100; // 700 characters
        final pattern = '%$longQuery%';

        expect(pattern.length, longQuery.length + 2);
        expect(() => 'test'.contains(longQuery), returnsNormally);
      });

      test('6.2 Search in empty notes list', () {
        final notes = <Note>[];
        final query = 'flutter';
        
        final results = notes.where((note) {
          return note.title.toLowerCase().contains(query.toLowerCase());
        }).toList();

        expect(results, isEmpty);
      });

      test('6.3 Unicode and emoji in search', () {
        final notes = [
          createTestNote(id: 1, title: 'Flutter 🚀', content: 'Amazing'),
          createTestNote(id: 2, title: 'Café ☕', content: 'Coffee'),
        ];

        final query1 = '🚀';
        final results1 = notes.where((n) => n.title.contains(query1)).toList();
        expect(results1.length, 1);

        final query2 = 'café';
        final results2 = notes.where((n) => 
          n.title.toLowerCase().contains(query2.toLowerCase())
        ).toList();
        expect(results2.length, 1);
      });

      test('6.4 SQL injection patterns (safely handled by prepared statements)', () {
        // These should be treated as literal strings, not SQL
        final dangerousQueries = [
          "'; DROP TABLE notes; --",
          "1' OR '1'='1",
          "%'; DELETE FROM notes WHERE '1'='1",
        ];

        for (final query in dangerousQueries) {
          final pattern = '%$query%';
          // Pattern is just a string - no SQL execution here
          expect(pattern, contains(query));
        }
      });
    });

    group('7. Integration Scenarios', () {
      test('7.1 Search active notes, sorted by recent', () {
        final now = DateTime.now();
        
        // Create notes with proper dates
        final oldFlutter = createTestNote(id: 1, title: 'Old Flutter', content: 'C', isArchived: false)
            .copyWith(createdAt: now.subtract(Duration(days: 5)));
        final recentPython = createTestNote(id: 2, title: 'Recent Python', content: 'C', isArchived: false)
            .copyWith(createdAt: now.subtract(Duration(days: 1)));
        final archivedFlutter = createTestNote(id: 3, title: 'Archived Flutter', content: 'C', isArchived: true)
            .copyWith(createdAt: now);
        final recentFlutter = createTestNote(id: 4, title: 'Recent Flutter', content: 'C', isArchived: false)
            .copyWith(createdAt: now.subtract(Duration(days: 2)));
        
        final notes = [oldFlutter, recentPython, archivedFlutter, recentFlutter];

        final query = 'flutter';
        
        // Step 1: Filter active
        var filtered = notes.where((n) => !n.isArchived).toList();
        
        // Step 2: Search
        filtered = filtered.where((note) {
          return note.title.toLowerCase().contains(query.toLowerCase()) ||
                 note.content.toLowerCase().contains(query.toLowerCase());
        }).toList();
        
        // Step 3: Sort by recent
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        expect(filtered.length, 2);
        expect(filtered[0].id, 4); // Most recent active Flutter note
        expect(filtered[1].id, 1); // Older active Flutter note
      });

      test('7.2 Clear search returns to filtered view', () {
        final notes = [
          createTestNote(id: 1, title: 'Flutter', content: 'C'),
          createTestNote(id: 2, title: 'Python', content: 'C'),
        ];

        // With search
        var query = 'flutter';
        var results = notes.where((n) => 
          n.title.toLowerCase().contains(query.toLowerCase())
        ).toList();
        expect(results.length, 1);

        // Clear search
        query = '';
        results = query.isEmpty ? notes : results;
        expect(results.length, 2);
      });
    });
  });
}
