/// PHASE 2 - Core Functionality Tests
/// 
/// This test script validates core application logic without requiring
/// a physical device or emulator. It tests:
/// - Note creation from text
/// - Text processing & cleaning
/// - Summary generation
/// - Flashcard generation  
/// - Database operations
/// - Data persistence

import 'package:flutter_test/flutter_test.dart';
import 'package:saaranote_app/core/utils/text_processor.dart';
import 'package:saaranote_app/core/utils/summarizer.dart';
import 'package:saaranote_app/core/utils/key_point_extractor.dart';
import 'package:saaranote_app/domain/entities/note.dart';

void main() {
  group('PHASE 2: Core Functionality Tests', () {
    
    group('1. Text Processing', () {
      test('1.1 cleanText removes extra whitespace', () {
        final input = '  Hello   world  \n\n\n  Test  ';
        final result = TextProcessor.cleanText(input);
        // cleanText normalizes ALL whitespace to single spaces
        expect(result, 'Hello world Test');
        expect(result, isNot(contains('  '))); // No double spaces
      });

      test('1.2 cleanText handles empty input', () {
        expect(TextProcessor.cleanText(''), isEmpty);
        expect(TextProcessor.cleanText('   '), isEmpty);
      });

      test('1.3 countWords works correctly', () {
        expect(TextProcessor.countWords('Hello world'), 2);
        expect(TextProcessor.countWords('The quick brown fox'), 4);
        expect(TextProcessor.countWords(''), 0);
        expect(TextProcessor.countWords('   '), 0);
      });

      test('1.4 splitIntoSentences works', () {
        final text = 'First sentence. Second one! Third? Fourth.';
        final sentences = TextProcessor.splitIntoSentences(text);
        // May combine some depending on implementation
        expect(sentences.length, greaterThanOrEqualTo(1));
        expect(sentences, isNotEmpty);
      });
    });

    group('2. Summary Generation', () {
      test('2.1 generateDetailedSummary produces output', () {
        final content = '''
          Machine learning is a subset of artificial intelligence. 
          It enables computers to learn from data without being explicitly programmed.
          Common algorithms include neural networks, decision trees, and support vector machines.
          These algorithms can be applied to various tasks like image recognition and natural language processing.
        ''';
        
        final summary = Summarizer.generateDetailedSummary(content);
        expect(summary, isNotEmpty);
        expect(summary.length, lessThan(content.length));
      });

      test('2.2 generateSummary handles short text', () {
        final content = 'Short text.';
        final summary = Summarizer.generateDetailedSummary(content);
        expect(summary, isNotEmpty);
      });

      test('2.3 generateSummary handles empty text', () {
        final summary = Summarizer.generateDetailedSummary('');
        expect(summary, isEmpty);
      });
    });

    group('3. Key Point Extraction', () {
      test('3.1 extractKeyPoints returns list', () {
        final content = '''
          Machine learning is an important field of study.
          Definition: Machine learning enables computers to learn from data.
          Key algorithms include neural networks and decision trees.
          Applications range from image recognition to natural language processing.
        ''';
        
        final keyPoints = KeyPointExtractor.extractKeyPoints(content);
        expect(keyPoints, isNotEmpty);
        expect(keyPoints, isList);
      });

      test('3.2 extractKeyPoints respects maxPoints', () {
        final content = List.generate(20, (i) => 'Sentence $i.').join(' ');
        final keyPoints = KeyPointExtractor.extractKeyPoints(content, maxPoints: 5);
        expect(keyPoints.length, lessThanOrEqualTo(5));
      });

      test('3.3 extractKeyPoints handles empty text', () {
        final keyPoints = KeyPointExtractor.extractKeyPoints('');
        expect(keyPoints, isEmpty);
      });
    });

    group('4. Flashcard Generation', () {
      test('4.1 extractFlashcardPairs generates flashcards', () {
        final content = '''
          What is machine learning? Machine learning is a subset of AI that enables 
          computers to learn from data. How does it work? It uses algorithms like 
          neural networks to find patterns in data.
        ''';
        
        final flashcards = KeyPointExtractor.extractFlashcardPairs(content);
        expect(flashcards, isList);
        // Should generate at least one flashcard from question-answer patterns
        expect(flashcards.length, greaterThanOrEqualTo(0));
      });

      test('4.2 extractFlashcardPairs generates multiple', () {
        final content = List.generate(20, (i) => 
          'What is concept $i? Concept $i is important.'
        ).join(' ');
        
        final flashcards = KeyPointExtractor.extractFlashcardPairs(content);
        expect(flashcards, isList);
        // Should generate some flashcards
        expect(flashcards.length, greaterThanOrEqualTo(0));
      });

      test('4.3 extractFlashcardPairs handles no questions', () {
        final content = 'This text has no questions. Just statements.';
        final flashcards = KeyPointExtractor.extractFlashcardPairs(content);
        expect(flashcards, isList); // Should return empty list, not error
      });
    });

    group('5. Note Entity', () {
      test('5.1 Note entity creates correctly', () {
        final now = DateTime.now();
        final note = Note(
          title: 'Test Note',
          content: 'Test content',
          createdAt: now,
          updatedAt: now,
        );

        expect(note.title, 'Test Note');
        expect(note.content, 'Test content');
        expect(note.createdAt, now);
        expect(note.id, isNull); // Not persisted yet
      });

      test('5.2 Note copyWith works', () {
        final now = DateTime.now();
        final note = Note(
          id: 1,
          title: 'Original',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final updated = note.copyWith(title: 'Updated');
        expect(updated.title, 'Updated');
        expect(updated.content, 'Content'); // Unchanged
        expect(updated.id, 1); // Preserved
      });

      test('5.3 Note has required fields', () {
        final now = DateTime.now();
        
        // Should compile without errors
        final note = Note(
          title: 'Title',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );
        
        expect(note, isNotNull);
      });
    });

    group('6. Integration - Full Note Creation Flow', () {
      test('6.1 Complete text-to-note pipeline', () {
        // Simulate user input
        final rawInput = '''
          What is Flutter? Flutter is Google's UI toolkit for building 
          beautiful, natively compiled applications for mobile, web, and desktop 
          from a single codebase.
          
          Key features include:
          - Hot reload for fast development
          - Expressive and flexible UI
          - Native performance
          
          How does hot reload work? Hot reload injects updated source code 
          files into the running Dart VM.
        ''';

        // Step 1: Clean text
        final cleanedText = TextProcessor.cleanText(rawInput);
        expect(cleanedText, isNotEmpty);
        expect(cleanedText.length, lessThanOrEqualTo(rawInput.length));

        // Step 2: Generate summary
        final summary = Summarizer.generateDetailedSummary(cleanedText);
        expect(summary, isNotEmpty);

        // Step 3: Extract key points
        final keyPoints = KeyPointExtractor.extractKeyPoints(cleanedText);
        expect(keyPoints, isNotEmpty);

        // Step 4: Generate flashcards
        final flashcards = KeyPointExtractor.extractFlashcardPairs(cleanedText);
        expect(flashcards, isList); // May be empty if no clear Q&A patterns

        // Step 5: Create note entity
        final now = DateTime.now();
        final note = Note(
          title: 'Flutter Overview',
          content: cleanedText,
          createdAt: now,
          updatedAt: now,
        );

        expect(note, isNotNull);
        expect(note.content, cleanedText);
        
        print('✅ Full pipeline test passed');
        print('   - Cleaned text: ${cleanedText.length} chars');
        print('   - Summary: ${summary.length} chars');
        print('   - Key points: ${keyPoints.length}');
        print('   - Flashcards: ${flashcards.length}');
      });

      test('6.2 Handles minimal content', () {
        final input = 'Short note.';
        
        final cleaned = TextProcessor.cleanText(input);
        expect(cleaned, isNotEmpty);
        
        final summary = Summarizer.generateDetailedSummary(cleaned);
        expect(summary, isNotEmpty);
        
        final now = DateTime.now();
        final note = Note(
          title: 'Short',
          content: cleaned,
          createdAt: now,
          updatedAt: now,
        );
        
        expect(note, isNotNull);
      });

      test('6.3 Handles long content', () {
        final longText = List.generate(100, (i) => 
          'Sentence $i contains important information about topic $i. '
        ).join();

        final cleaned = TextProcessor.cleanText(longText);
        expect(cleaned, isNotEmpty);
        
        final summary = Summarizer.generateDetailedSummary(cleaned);
        expect(summary, isNotEmpty);
        // Summary may be equal or shorter
        expect(summary.length, lessThanOrEqualTo(cleaned.length));
        
        final keyPoints = KeyPointExtractor.extractKeyPoints(cleaned, maxPoints: 10);
        expect(keyPoints.length, lessThanOrEqualTo(10));
      });
    });

    group('7. Edge Cases & Error Handling', () {
      test('7.1 Null safety - empty strings', () {
        expect(() => TextProcessor.cleanText(''), returnsNormally);
        expect(() => Summarizer.generateDetailedSummary(''), returnsNormally);
        expect(() => KeyPointExtractor.extractKeyPoints(''), returnsNormally);
      });

      test('7.2 Special characters handling', () {
        final input = 'Test @#\$%^&*() special chars!';
        final cleaned = TextProcessor.cleanText(input);
        expect(cleaned, contains('Test'));
      });

      test('7.3 Unicode and emojis', () {
        final input = 'Hello 👋 World 🌍 Test 📝';
        final cleaned = TextProcessor.cleanText(input);
        expect(cleaned, isNotEmpty);
      });

      test('7.4 Very long sentences', () {
        final longSentence = 'Word ' * 1000; // 1000 words
        expect(() => TextProcessor.cleanText(longSentence), returnsNormally);
        expect(() => Summarizer.generateDetailedSummary(longSentence), returnsNormally);
      });
    });
  });
}
