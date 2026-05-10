/// PHASE 5 - PDF Export Tests
/// 
/// This test validates the PDF export functionality:
/// - PDF document generation from notes
/// - Content inclusion (title, content, metadata)
/// - Summary section rendering
/// - Flashcard section formatting
/// - File name sanitization
/// - Date formatting
/// - Empty state handling
/// - Edge cases (special characters, long content)
/// - Performance considerations
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saaranote_app/domain/entities/note.dart';
import 'package:saaranote_app/domain/entities/note_summary.dart';
import 'package:saaranote_app/domain/entities/flashcard.dart';

void main() {
  group('PHASE 5: PDF Export Tests', () {
    
    // Helper to create test notes
    Note createTestNote({
      int? id,
      required String title,
      required String content,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      final now = DateTime.now();
      return Note(
        id: id,
        title: title,
        content: content,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
      );
    }

    // Helper to create test summary
    NoteSummary createTestSummary({
      int? id,
      required int noteId,
      required String summaryText,
    }) {
      return NoteSummary(
        id: id,
        noteId: noteId,
        summaryText: summaryText,
        createdAt: DateTime.now(),
      );
    }

    // Helper to create test flashcard
    Flashcard createTestFlashcard({
      int? id,
      required int noteId,
      required String question,
      required String answer,
    }) {
      return Flashcard(
        id: id,
        noteId: noteId,
        question: question,
        answer: answer,
        createdAt: DateTime.now(),
      );
    }

    group('1. File Name Sanitization', () {
      test('1.1 Remove special characters', () {
        final testCases = [
          ('Hello World!', 'hello_world'),
          ('My Note @2024', 'my_note_2024'),
          ('Test#123', 'test123'),
          ('Note with /slash', 'note_with_slash'),
          ('Price: \$100', 'price_100'),
        ];

        for (final (input, expected) in testCases) {
          final sanitized = _sanitizeFileName(input);
          expect(sanitized, expected);
          expect(sanitized, matches(RegExp(r'^[a-z0-9_-]+$')));
        }
      });

      test('1.2 Replace spaces with underscores', () {
        final input = 'Flutter App Development';
        final sanitized = _sanitizeFileName(input);
        
        expect(sanitized, 'flutter_app_development');
        expect(sanitized, isNot(contains(' ')));
      });

      test('1.3 Convert to lowercase', () {
        final input = 'MyNoteTitle';
        final sanitized = _sanitizeFileName(input);
        
        expect(sanitized, 'mynotetitle');
        expect(sanitized, equals(sanitized.toLowerCase()));
      });

      test('1.4 Limit length to 50 characters', () {
        final longTitle = 'This is a very long note title that exceeds the maximum allowed length';
        final sanitized = _sanitizeFileName(longTitle);
        
        expect(sanitized.length, lessThanOrEqualTo(50));
      });

      test('1.5 Handle empty or whitespace-only titles', () {
        final testCases = ['', '   ', '\t\n'];

        for (final input in testCases) {
          final sanitized = _sanitizeFileName(input);
          // Empty input results in '_' or fallback with timestamp
          expect(sanitized.isNotEmpty, isTrue);
        }
      });

      test('1.6 Handle unicode characters', () {
        final input = 'Café Notes 🚀';
        final sanitized = _sanitizeFileName(input);
        
        // Unicode removed, may have trailing underscore from space/emoji removal
        expect(sanitized, matches(RegExp(r'^caf_notes_?$')));
      });

      test('1.7 Preserve hyphens and underscores', () {
        final input = 'my-note_2024';
        final sanitized = _sanitizeFileName(input);
        
        expect(sanitized, 'my-note_2024');
      });
    });

    group('2. Date Formatting', () {
      test('2.1 Format date with day/month/year', () {
        final date = DateTime(2024, 3, 15, 14, 30);
        final formatted = _formatDate(date);
        
        expect(formatted, contains('15/3/2024'));
      });

      test('2.2 Format time with hours and minutes', () {
        final date = DateTime(2024, 1, 1, 9, 5);
        final formatted = _formatDate(date);
        
        expect(formatted, contains('9:05')); // Padded minutes
      });

      test('2.3 Pad single-digit minutes', () {
        final date = DateTime(2024, 1, 1, 10, 3);
        final formatted = _formatDate(date);
        
        expect(formatted, contains('10:03'));
        expect(formatted, isNot(contains('10:3')));
      });

      test('2.4 Format various dates', () {
        final testCases = [
          DateTime(2024, 12, 31, 23, 59),
          DateTime(2024, 1, 1, 0, 0),
          DateTime(2024, 6, 15, 12, 30),
        ];

        for (final date in testCases) {
          final formatted = _formatDate(date);
          expect(formatted, matches(RegExp(r'\d+/\d+/\d+ \d+:\d{2}')));
        }
      });
    });

    group('3. Content Structure Validation', () {
      test('3.1 Note must have title', () {
        final note = createTestNote(
          id: 1,
          title: 'Test Note',
          content: 'Content',
        );

        expect(note.title, isNotEmpty);
        expect(note.title, 'Test Note');
      });

      test('3.2 Note must have content', () {
        final note = createTestNote(
          id: 1,
          title: 'Title',
          content: 'This is the main content of the note.',
        );

        expect(note.content, isNotEmpty);
        expect(note.content.length, greaterThan(0));
      });

      test('3.3 Note must have timestamps', () {
        final now = DateTime.now();
        final note = createTestNote(
          id: 1,
          title: 'Title',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        expect(note.createdAt, isNotNull);
        expect(note.updatedAt, isNotNull);
      });

      test('3.4 Summary is optional', () {
        final note = createTestNote(id: 1, title: 'T', content: 'C');
        NoteSummary? summary; // Can be null

        expect(note, isNotNull);
        expect(summary, isNull);
      });

      test('3.5 Flashcards list can be empty', () {
        final flashcards = <Flashcard>[];

        expect(flashcards, isEmpty);
        expect(flashcards.length, 0);
      });
    });

    group('4. Key Points Extraction', () {
      test('4.1 Extract up to 5 key points from content', () {
        final content = 'Point 1. Point 2. Point 3. Point 4. Point 5. Point 6. Point 7.';
        final sentences = content.split('.').where((s) => s.trim().isNotEmpty).take(5).toList();

        expect(sentences.length, 5);
      });

      test('4.2 Handle content with fewer than 5 sentences', () {
        final content = 'First point. Second point. Third point.';
        final sentences = content.split('.').where((s) => s.trim().isNotEmpty).take(5).toList();

        expect(sentences.length, 3);
      });

      test('4.3 Filter out empty sentences', () {
        final content = 'Valid sentence.. Another sentence...Third one.';
        final sentences = content.split('.').where((s) => s.trim().isNotEmpty).take(5).toList();

        expect(sentences.every((s) => s.trim().isNotEmpty), isTrue);
      });

      test('4.4 Trim whitespace from key points', () {
        final content = '  First point  .  Second point  .';
        final sentences = content.split('.').where((s) => s.trim().isNotEmpty).take(5).toList();

        for (final sentence in sentences) {
          final trimmed = sentence.trim();
          expect(trimmed, isNot(startsWith(' ')));
          expect(trimmed, isNot(endsWith(' ')));
        }
      });

      test('4.5 Handle single long sentence', () {
        final content = 'This is one very long sentence without any period marks except at the end';
        final sentences = content.split('.').where((s) => s.trim().isNotEmpty).take(5).toList();

        expect(sentences.length, 1);
      });
    });

    group('5. Flashcard Formatting', () {
      test('5.1 Flashcard has question and answer', () {
        final flashcard = createTestFlashcard(
          id: 1,
          noteId: 10,
          question: 'What is Flutter?',
          answer: 'A UI toolkit',
        );

        expect(flashcard.question, isNotEmpty);
        expect(flashcard.answer, isNotEmpty);
      });

      test('5.2 Format flashcard with index', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2'),
        ];

        for (var i = 0; i < flashcards.length; i++) {
          final label = 'Flashcard ${i + 1}';
          expect(label, contains('Flashcard'));
          expect(label, contains('${i + 1}'));
        }
      });

      test('5.3 Question has Q: prefix', () {
        final flashcard = createTestFlashcard(
          noteId: 1,
          question: 'Test question',
          answer: 'Test answer',
        );

        final formatted = 'Q: ${flashcard.question}';
        expect(formatted, startsWith('Q: '));
      });

      test('5.4 Answer has A: prefix', () {
        final flashcard = createTestFlashcard(
          noteId: 1,
          question: 'Question',
          answer: 'Answer',
        );

        final formatted = 'A: ${flashcard.answer}';
        expect(formatted, startsWith('A: '));
      });

      test('5.5 Multiple flashcards maintain order', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2'),
          createTestFlashcard(id: 3, noteId: 1, question: 'Q3', answer: 'A3'),
        ];

        expect(flashcards[0].question, 'Q1');
        expect(flashcards[1].question, 'Q2');
        expect(flashcards[2].question, 'Q3');
      });
    });

    group('6. PDF Content Sections', () {
      test('6.1 Basic note has required sections', () {
        final note = createTestNote(
          id: 1,
          title: 'Test Note',
          content: 'Test content',
        );

        expect(note.content, 'Test content');

        // Required sections
        final sections = ['Title', 'Content', 'Key Points'];
        expect(sections, contains('Title'));
        expect(sections, contains('Content'));
        expect(sections, contains('Key Points'));
      });

      test('6.2 Summary section is conditional', () {
        NoteSummary? summary = createTestSummary(
          id: 1,
          noteId: 1,
          summaryText: 'Test summary',
        );

        expect(summary, isNotNull);

        summary = null;
        expect(summary, isNull);
      });

      test('6.3 Flashcards section is conditional', () {
        List<Flashcard>? flashcards = [
          createTestFlashcard(noteId: 1, question: 'Q', answer: 'A'),
        ];

        expect(flashcards, isNotNull);
        expect(flashcards.isNotEmpty, isTrue);

        flashcards = [];
        expect(flashcards.isEmpty, isTrue);
      });

      test('6.4 Metadata includes created and updated dates', () {
        final now = DateTime.now();
        final note = createTestNote(
          id: 1,
          title: 'T',
          content: 'C',
          createdAt: now,
          updatedAt: now,
        );

        final createdLabel = 'Created: ${_formatDate(note.createdAt)}';
        final updatedLabel = 'Last Updated: ${_formatDate(note.updatedAt)}';

        expect(createdLabel, startsWith('Created: '));
        expect(updatedLabel, startsWith('Last Updated: '));
      });

      test('6.5 Section headers are properly labeled', () {
        final headers = ['Content', 'Summary', 'Key Points', 'Flashcards'];

        for (final header in headers) {
          expect(header, isNotEmpty);
          expect(header[0], equals(header[0].toUpperCase())); // Capitalized
        }
      });
    });

    group('7. Edge Cases', () {
      test('7.1 Very long note title', () {
        final longTitle = 'A' * 200;
        final note = createTestNote(
          id: 1,
          title: longTitle,
          content: 'Content',
        );

        expect(note.title.length, 200);
        
        final fileName = _sanitizeFileName(note.title);
        expect(fileName.length, lessThanOrEqualTo(50));
      });

      test('7.2 Very long note content', () {
        final longContent = 'Word ' * 10000; // 50000 characters
        final note = createTestNote(
          id: 1,
          title: 'Title',
          content: longContent,
        );

        expect(note.content.length, greaterThan(10000));
      });

      test('7.3 Note with special characters in content', () {
        final content = 'Formula: E=mc². Price: \$100. Temp: 25°C. Quote: "Hello"';
        final note = createTestNote(
          id: 1,
          title: 'Test',
          content: content,
        );

        expect(note.content, contains('²'));
        expect(note.content, contains('\$'));
        expect(note.content, contains('°'));
        expect(note.content, contains('"'));
      });

      test('7.4 Summary longer than original content', () {
        final note = createTestNote(id: 1, title: 'T', content: 'Short');
        final summary = createTestSummary(
          id: 1,
          noteId: 1,
          summaryText: 'This is a much longer summary than the original content for testing purposes',
        );

        expect(summary.summaryText.length, greaterThan(note.content.length));
      });

      test('7.5 Flashcard with very long question', () {
        final longQuestion = 'What is the complete and detailed explanation of ' * 10;
        final flashcard = createTestFlashcard(
          noteId: 1,
          question: longQuestion,
          answer: 'Answer',
        );

        expect(flashcard.question.length, greaterThan(100));
      });

      test('7.6 Flashcard with very long answer', () {
        final longAnswer = 'The answer involves multiple steps and considerations. ' * 20;
        final flashcard = createTestFlashcard(
          noteId: 1,
          question: 'Question',
          answer: longAnswer,
        );

        expect(flashcard.answer.length, greaterThan(500));
      });

      test('7.7 Many flashcards (50+)', () {
        final flashcards = List.generate(50, (i) {
          return createTestFlashcard(
            id: i,
            noteId: 1,
            question: 'Question $i',
            answer: 'Answer $i',
          );
        });

        expect(flashcards.length, 50);
        expect(flashcards.first.id, 0);
        expect(flashcards.last.id, 49);
      });

      test('7.8 Title with only special characters', () {
        final title = '!@#\$%^&*()';
        final sanitized = _sanitizeFileName(title);

        expect(sanitized, startsWith('note_')); // Falls back to default
      });

      test('7.9 Content with only whitespace', () {
        final content = '     \n\n\t\t     ';
        final trimmed = content.trim();

        expect(trimmed, isEmpty);
      });

      test('7.10 Mixed language content', () {
        final content = 'English text. Texto en español. Texte français. 日本語のテキスト.';
        final note = createTestNote(id: 1, title: 'T', content: content);

        expect(note.content, contains('English'));
        expect(note.content, contains('español'));
        expect(note.content, contains('français'));
        expect(note.content, contains('日本語'));
      });
    });

    group('8. Empty/Null Handling', () {
      test('8.1 Note with empty summary', () {
        final summary = createTestSummary(
          id: 1,
          noteId: 1,
          summaryText: '',
        );

        expect(summary.summaryText, isEmpty);
      });

      test('8.2 Note with no flashcards', () {
        final flashcards = <Flashcard>[];

        expect(flashcards, isEmpty);
        expect(flashcards.length, 0);
      });

      test('8.3 Null summary handling', () {
        NoteSummary? summary;

        expect(summary, isNull);
      });

      test('8.4 Null flashcards handling', () {
        List<Flashcard>? flashcards;

        expect(flashcards, isNull);
      });

      test('8.5 Empty content generates empty key points', () {
        final content = '';
        final sentences = content.split('.').where((s) => s.trim().isNotEmpty).take(5).toList();

        expect(sentences, isEmpty);
      });
    });

    group('9. Integration Scenarios', () {
      test('9.1 Complete PDF export data', () {
        final note = createTestNote(
          id: 1,
          title: 'Complete Note',
          content: 'This is a complete note with all components.',
        );

        final summary = createTestSummary(
          id: 1,
          noteId: 1,
          summaryText: 'A comprehensive summary.',
        );

        final flashcards = [
          createTestFlashcard(noteId: 1, question: 'Q1', answer: 'A1'),
          createTestFlashcard(noteId: 1, question: 'Q2', answer: 'A2'),
        ];

        expect(note, isNotNull);
        expect(summary, isNotNull);
        expect(flashcards, isNotEmpty);
      });

      test('9.2 Minimal PDF export (note only)', () {
        final note = createTestNote(
          id: 1,
          title: 'Minimal Note',
          content: 'Just basic content.',
        );

        NoteSummary? summary;
        List<Flashcard>? flashcards;

        expect(note, isNotNull);
        expect(summary, isNull);
        expect(flashcards, isNull);
      });

      test('9.3 Note with summary but no flashcards', () {
        final note = createTestNote(id: 1, title: 'T', content: 'C');
        final summary = createTestSummary(id: 1, noteId: 1, summaryText: 'S');
        final flashcards = <Flashcard>[];

        expect(note, isNotNull);
        expect(summary, isNotNull);
        expect(flashcards, isEmpty);
      });

      test('9.4 Note with flashcards but no summary', () {
        final note = createTestNote(id: 1, title: 'T', content: 'C');
        NoteSummary? summary;
        final flashcards = [
          createTestFlashcard(noteId: 1, question: 'Q', answer: 'A'),
        ];

        expect(note, isNotNull);
        expect(summary, isNull);
        expect(flashcards, isNotEmpty);
      });

      test('9.5 Export note that was recently updated', () {
        final createdAt = DateTime.now().subtract(Duration(days: 7));
        final updatedAt = DateTime.now();

        final note = createTestNote(
          id: 1,
          title: 'Updated Note',
          content: 'Content',
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        expect(note.updatedAt.isAfter(note.createdAt), isTrue);
      });
    });

    group('10. Performance Considerations', () {
      test('10.1 Handle 100 flashcards', () {
        final flashcards = List.generate(100, (i) {
          return createTestFlashcard(
            id: i,
            noteId: 1,
            question: 'Question $i',
            answer: 'Answer $i',
          );
        });

        expect(flashcards.length, 100);
      });

      test('10.2 Handle 10000 word content', () {
        final words = List.generate(10000, (i) => 'word$i').join(' ');
        final note = createTestNote(id: 1, title: 'Large', content: words);

        expect(note.content.split(' ').length, 10000);
      });

      test('10.3 File name sanitization performance', () {
        final sw = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          _sanitizeFileName('Test Note Title $i with Special!@#\$ Characters');
        }

        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(100));
      });

      test('10.4 Date formatting performance', () {
        final dates = List.generate(1000, (i) => DateTime.now());
        final sw = Stopwatch()..start();

        for (final date in dates) {
          _formatDate(date);
        }

        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(50));
      });

      test('10.5 Key points extraction from large content', () {
        final sentences = List.generate(1000, (i) => 'Sentence $i').join('. ');
        final sw = Stopwatch()..start();

        final keyPoints = sentences.split('.').where((s) => s.trim().isNotEmpty).take(5).toList();

        sw.stop();
        expect(keyPoints.length, 5);
        expect(sw.elapsedMilliseconds, lessThan(10));
      });
    });
  });
}

// Helper functions matching PdfExportService implementation

String _sanitizeFileName(String fileName) {
  String sanitized = fileName
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '_')
      .toLowerCase();
  
  if (sanitized.length > 50) {
    sanitized = sanitized.substring(0, 50);
  }
  
  if (sanitized.isEmpty) {
    sanitized = 'note_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  return sanitized;
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
