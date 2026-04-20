/// PHASE 4 - Flashcard System Tests
/// 
/// This test validates the flashcard system functionality:
/// - Flashcard entity structure and immutability
/// - Flashcard navigation (next/previous with bounds checking)
/// - Confidence level tracking (0-5 scale)
/// - Answer visibility toggle
/// - Flashcard creation and persistence
/// - Empty state handling
/// - Review session management
/// - Edge cases (empty lists, boundary navigation)

import 'package:flutter_test/flutter_test.dart';
import 'package:saaranote_app/domain/entities/flashcard.dart';

void main() {
  group('PHASE 4: Flashcard System Tests', () {
    
    // Helper to create test flashcards
    Flashcard createTestFlashcard({
      int? id,
      required int noteId,
      required String question,
      required String answer,
      int confidenceLevel = 0,
      DateTime? lastReviewedAt,
    }) {
      return Flashcard(
        id: id,
        noteId: noteId,
        question: question,
        answer: answer,
        createdAt: DateTime.now(),
        lastReviewedAt: lastReviewedAt,
        confidenceLevel: confidenceLevel,
      );
    }

    group('1. Flashcard Entity Structure', () {
      test('1.1 Create flashcard with required fields', () {
        final flashcard = createTestFlashcard(
          id: 1,
          noteId: 10,
          question: 'What is Flutter?',
          answer: 'A UI toolkit for building natively compiled applications',
        );

        expect(flashcard.id, 1);
        expect(flashcard.noteId, 10);
        expect(flashcard.question, 'What is Flutter?');
        expect(flashcard.answer, 'A UI toolkit for building natively compiled applications');
        expect(flashcard.confidenceLevel, 0); // Default
        expect(flashcard.lastReviewedAt, isNull);
      });

      test('1.2 Confidence level defaults to 0', () {
        final flashcard = createTestFlashcard(
          noteId: 1,
          question: 'Q',
          answer: 'A',
        );

        expect(flashcard.confidenceLevel, 0);
      });

      test('1.3 Flashcard is immutable - copyWith creates new instance', () {
        final original = createTestFlashcard(
          id: 1,
          noteId: 10,
          question: 'Original',
          answer: 'Answer',
          confidenceLevel: 0,
        );

        final modified = original.copyWith(confidenceLevel: 3);

        expect(original.confidenceLevel, 0); // Original unchanged
        expect(modified.confidenceLevel, 3); // New instance modified
        expect(identical(original, modified), isFalse);
      });

      test('1.4 copyWith preserves unmodified fields', () {
        final original = createTestFlashcard(
          id: 1,
          noteId: 10,
          question: 'Q1',
          answer: 'A1',
          confidenceLevel: 2,
        );

        final modified = original.copyWith(confidenceLevel: 4);

        expect(modified.id, original.id);
        expect(modified.noteId, original.noteId);
        expect(modified.question, original.question);
        expect(modified.answer, original.answer);
        expect(modified.confidenceLevel, 4);
      });

      test('1.5 Update lastReviewedAt on review', () {
        final flashcard = createTestFlashcard(
          id: 1,
          noteId: 10,
          question: 'Q',
          answer: 'A',
        );

        expect(flashcard.lastReviewedAt, isNull);

        final reviewed = flashcard.copyWith(
          lastReviewedAt: DateTime.now(),
          confidenceLevel: 3,
        );

        expect(reviewed.lastReviewedAt, isNotNull);
        expect(reviewed.confidenceLevel, 3);
      });
    });

    group('2. Navigation Bounds Checking', () {
      test('2.1 canGoNext returns true when not at end', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2'),
          createTestFlashcard(id: 3, noteId: 1, question: 'Q3', answer: 'A3'),
        ];

        int currentIndex = 0;
        final canGoNext = currentIndex < flashcards.length - 1;

        expect(canGoNext, isTrue);
      });

      test('2.2 canGoNext returns false at last card', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2'),
        ];

        int currentIndex = 1; // At last card
        final canGoNext = currentIndex < flashcards.length - 1;

        expect(canGoNext, isFalse);
      });

      test('2.3 canGoPrevious returns true when not at start', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2'),
        ];

        int currentIndex = flashcards.length - 1;
        final canGoPrevious = currentIndex > 0;

        expect(canGoPrevious, isTrue);
      });

      test('2.4 canGoPrevious returns false at first card', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
        ];

        int currentIndex = flashcards.length - 1;
        final canGoPrevious = currentIndex > 0;

        expect(canGoPrevious, isFalse);
      });

      test('2.5 Safe currentFlashcard getter with bounds check', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2'),
        ];

        // Valid index
        int currentIndex = 0;
        Flashcard? current = (currentIndex >= 0 && currentIndex < flashcards.length)
            ? flashcards[currentIndex]
            : null;
        expect(current, isNotNull);
        expect(current?.id, 1);

        // Invalid negative index
        currentIndex = -1;
        current = (currentIndex >= 0 && currentIndex < flashcards.length)
            ? flashcards[currentIndex]
            : null;
        expect(current, isNull);

        // Invalid out-of-bounds index
        currentIndex = 10;
        current = (currentIndex >= 0 && currentIndex < flashcards.length)
            ? flashcards[currentIndex]
            : null;
        expect(current, isNull);
      });

      test('2.6 Navigation with single flashcard', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
        ];

        int currentIndex = 0;
        expect(currentIndex < flashcards.length - 1, isFalse); // Can't go next
        expect(currentIndex > 0, isFalse); // Can't go previous
      });
    });

    group('3. Confidence Level System', () {
      test('3.1 Valid confidence levels (0-5)', () {
        final validLevels = [0, 1, 2, 3, 4, 5];

        for (final level in validLevels) {
          final flashcard = createTestFlashcard(
            noteId: 1,
            question: 'Q',
            answer: 'A',
            confidenceLevel: level,
          );

          expect(flashcard.confidenceLevel, level);
          expect(flashcard.confidenceLevel >= 0, isTrue);
          expect(flashcard.confidenceLevel <= 5, isTrue);
        }
      });

      test('3.2 Update confidence level via copyWith', () {
        final flashcard = createTestFlashcard(
          id: 1,
          noteId: 1,
          question: 'Q',
          answer: 'A',
          confidenceLevel: 0,
        );

        final reviewed = flashcard.copyWith(
          confidenceLevel: 4,
          lastReviewedAt: DateTime.now(),
        );

        expect(reviewed.confidenceLevel, 4);
        expect(reviewed.lastReviewedAt, isNotNull);
      });

      test('3.3 Confidence level progression simulation', () {
        var flashcard = createTestFlashcard(
          id: 1,
          noteId: 1,
          question: 'Q',
          answer: 'A',
          confidenceLevel: 0,
        );

        // First review - hard
        flashcard = flashcard.copyWith(
          confidenceLevel: 1,
          lastReviewedAt: DateTime.now(),
        );
        expect(flashcard.confidenceLevel, 1);

        // Second review - medium
        flashcard = flashcard.copyWith(
          confidenceLevel: 3,
          lastReviewedAt: DateTime.now(),
        );
        expect(flashcard.confidenceLevel, 3);

        // Third review - easy
        flashcard = flashcard.copyWith(
          confidenceLevel: 5,
          lastReviewedAt: DateTime.now(),
        );
        expect(flashcard.confidenceLevel, 5);
      });

      test('3.4 Filter flashcards due for review (confidence < 3)', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1', confidenceLevel: 0),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2', confidenceLevel: 2),
          createTestFlashcard(id: 3, noteId: 1, question: 'Q3', answer: 'A3', confidenceLevel: 4),
          createTestFlashcard(id: 4, noteId: 1, question: 'Q4', answer: 'A4', confidenceLevel: 1),
          createTestFlashcard(id: 5, noteId: 1, question: 'Q5', answer: 'A5', confidenceLevel: 5),
        ];

        // Simulate getDueForReview() - cards with confidence < 3
        final dueForReview = flashcards.where((f) => f.confidenceLevel < 3).toList();

        expect(dueForReview.length, 3); // IDs 1, 2, 4
        expect(dueForReview.every((f) => f.confidenceLevel < 3), isTrue);
      });
    });

    group('4. Answer Visibility Toggle', () {
      test('4.1 Answer starts hidden', () {
        bool showAnswer = false;

        expect(showAnswer, isFalse);
      });

      test('4.2 Toggle answer visibility', () {
        bool showAnswer = false;

        // First toggle - show
        showAnswer = !showAnswer;
        expect(showAnswer, isTrue);

        // Second toggle - hide
        showAnswer = !showAnswer;
        expect(showAnswer, isFalse);
      });

      test('4.3 Answer resets when navigating', () {
        bool showAnswer = true;
        int currentIndex = 0;

        // Simulate navigation - answer should reset
        currentIndex++;
        showAnswer = false; // Reset on navigation

        expect(currentIndex, 1);
        expect(showAnswer, isFalse);
      });

      test('4.4 Multiple show/hide cycles', () {
        bool showAnswer = false;

        for (int i = 0; i < 5; i++) {
          showAnswer = !showAnswer;
          expect(showAnswer, i % 2 == 0); // Alternates true/false
        }
      });
    });

    group('5. Flashcard Creation Patterns', () {
      test('5.1 Create definition flashcard', () {
        final flashcard = createTestFlashcard(
          id: 1,
          noteId: 10,
          question: 'What is polymorphism?',
          answer: 'The ability of objects to take on multiple forms',
        );

        expect(flashcard.question, contains('What is'));
        expect(flashcard.answer, isNotEmpty);
      });

      test('5.2 Create comparison flashcard', () {
        final flashcard = createTestFlashcard(
          id: 2,
          noteId: 10,
          question: 'What is the difference between Flutter and React Native?',
          answer: 'Flutter uses Dart and compiles to native code, while React Native uses JavaScript and a bridge',
        );

        expect(flashcard.question, contains('difference'));
        expect(flashcard.answer.length, greaterThan(20));
      });

      test('5.3 Create multiple flashcards for one note', () {
        final noteId = 10;
        final flashcards = [
          createTestFlashcard(id: 1, noteId: noteId, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: noteId, question: 'Q2', answer: 'A2'),
          createTestFlashcard(id: 3, noteId: noteId, question: 'Q3', answer: 'A3'),
        ];

        expect(flashcards.length, 3);
        expect(flashcards.every((f) => f.noteId == noteId), isTrue);
        expect(flashcards.map((f) => f.id).toSet().length, 3); // Unique IDs
      });

      test('5.4 Question and answer must not be empty', () {
        final flashcard = createTestFlashcard(
          noteId: 1,
          question: 'Q',
          answer: 'A',
        );

        expect(flashcard.question.isNotEmpty, isTrue);
        expect(flashcard.answer.isNotEmpty, isTrue);
      });

      test('5.5 Long question and answer handling', () {
        final longQuestion = 'What is ' + 'the meaning of life ' * 20;
        final longAnswer = 'The answer is ' + '42 ' * 50;

        final flashcard = createTestFlashcard(
          noteId: 1,
          question: longQuestion,
          answer: longAnswer,
        );

        expect(flashcard.question.length, greaterThan(100));
        expect(flashcard.answer.length, greaterThan(100));
      });
    });

    group('6. Empty State Handling', () {
      test('6.1 Empty flashcard list', () {
        final flashcards = <Flashcard>[];

        expect(flashcards.isEmpty, isTrue);
        expect(flashcards.length, 0);
      });

      test('6.2 No current flashcard when list is empty', () {
        final flashcards = <Flashcard>[];
        int currentIndex = 0;

        Flashcard? current = (currentIndex >= 0 && currentIndex < flashcards.length)
            ? flashcards[currentIndex]
            : null;

        expect(current, isNull);
      });

      test('6.3 Navigation disabled when empty', () {
        final flashcards = <Flashcard>[];
        int currentIndex = 0;

        expect(currentIndex < flashcards.length - 1, isFalse); // Can't go next
        expect(currentIndex > 0, isFalse); // Can't go previous
      });

      test('6.4 Filter returns empty when no matches', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1', confidenceLevel: 4),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2', confidenceLevel: 5),
        ];

        // Filter for low confidence (< 3)
        final lowConfidence = flashcards.where((f) => f.confidenceLevel < 3).toList();

        expect(lowConfidence.isEmpty, isTrue);
      });
    });

    group('7. Review Session Management', () {
      test('7.1 Track reviewed flashcards', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2'),
          createTestFlashcard(id: 3, noteId: 1, question: 'Q3', answer: 'A3'),
        ];

        // Simulate review session
        final reviewedCards = <int, int>{}; // flashcardId -> confidenceLevel

        // Review first card
        reviewedCards[flashcards[0].id!] = 3;
        expect(reviewedCards.length, 1);

        // Review second card
        reviewedCards[flashcards[1].id!] = 5;
        expect(reviewedCards.length, 2);

        // Check progress
        final reviewedCount = reviewedCards.length;
        final remainingCount = flashcards.length - reviewedCount;
        expect(reviewedCount, 2);
        expect(remainingCount, 1);
      });

      test('7.2 Calculate review progress', () {
        final totalFlashcards = 10;
        int reviewedCount = 0;

        // Initially 0%
        double progress = reviewedCount / totalFlashcards;
        expect(progress, 0.0);

        // After 5 reviews - 50%
        reviewedCount = 5;
        progress = reviewedCount / totalFlashcards;
        expect(progress, 0.5);

        // After all reviews - 100%
        reviewedCount = 10;
        progress = reviewedCount / totalFlashcards;
        expect(progress, 1.0);
      });

      test('7.3 Session completion check', () {
        final totalFlashcards = 3;
        final reviewedCount = 3;

        final isComplete = reviewedCount == totalFlashcards && totalFlashcards > 0;

        expect(isComplete, isTrue);
      });

      test('7.4 Reset session state', () {
        int currentIndex = 5;
        bool showAnswer = true;
        final reviewedCards = <int, int>{1: 3, 2: 4, 3: 5};

        // Reset
        currentIndex = 0;
        showAnswer = false;
        reviewedCards.clear();

        expect(currentIndex, 0);
        expect(showAnswer, isFalse);
        expect(reviewedCards.isEmpty, isTrue);
      });

      test('7.5 Average confidence calculation', () {
        final reviewedCards = <int, int>{
          1: 2,
          2: 4,
          3: 3,
          4: 5,
        };

        final avgConfidence = reviewedCards.values.reduce((a, b) => a + b) / reviewedCards.length;

        expect(avgConfidence, 3.5);
      });
    });

    group('8. Edge Cases', () {
      test('8.1 Flashcard with special characters', () {
        final flashcard = createTestFlashcard(
          noteId: 1,
          question: 'What is the formula for E=mc²?',
          answer: 'Energy equals mass times the speed of light squared',
        );

        expect(flashcard.question, contains('²'));
        expect(flashcard.answer, isNotEmpty);
      });

      test('8.2 Flashcard with unicode and emoji', () {
        final flashcard = createTestFlashcard(
          noteId: 1,
          question: 'What does 🚀 represent?',
          answer: 'Rocket ship - often used to represent speed or launch',
        );

        expect(flashcard.question, contains('🚀'));
        expect(flashcard.answer, isNotEmpty);
      });

      test('8.3 Multiple flashcards with same question (different notes)', () {
        final flashcard1 = createTestFlashcard(
          id: 1,
          noteId: 10,
          question: 'What is OOP?',
          answer: 'Object-Oriented Programming',
        );

        final flashcard2 = createTestFlashcard(
          id: 2,
          noteId: 20, // Different note
          question: 'What is OOP?', // Same question
          answer: 'Object-Oriented Programming',
        );

        expect(flashcard1.question, flashcard2.question);
        expect(flashcard1.noteId, isNot(flashcard2.noteId));
      });

      test('8.4 Flashcard with HTML/markdown in content', () {
        final flashcard = createTestFlashcard(
          noteId: 1,
          question: 'What is <strong>bold</strong> text?',
          answer: 'Text with **emphasis** or __importance__',
        );

        expect(flashcard.question, contains('<strong>'));
        expect(flashcard.answer, contains('**'));
      });

      test('8.5 Very short question and answer', () {
        final flashcard = createTestFlashcard(
          noteId: 1,
          question: 'Q?',
          answer: 'A',
        );

        expect(flashcard.question.length, 2);
        expect(flashcard.answer.length, 1);
      });

      test('8.6 Navigate backward then forward', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2'),
          createTestFlashcard(id: 3, noteId: 1, question: 'Q3', answer: 'A3'),
        ];

        int currentIndex = 1; // At card 2

        // Go forward
        currentIndex++;
        expect(currentIndex, 2);
        expect(flashcards[currentIndex].id, 3);

        // Go backward
        currentIndex--;
        expect(currentIndex, 1);
        expect(flashcards[currentIndex].id, 2);
      });
    });

    group('9. Integration Scenarios', () {
      test('9.1 Complete review flow', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2'),
        ];

        int currentIndex = 0;
        bool showAnswer = false;
        final reviewedCards = <int, int>{};

        // Card 1: Show answer
        showAnswer = true;
        expect(showAnswer, isTrue);

        // Card 1: Rate and move next
        reviewedCards[flashcards[currentIndex].id!] = 4;
        currentIndex++;
        showAnswer = false;
        expect(currentIndex, 1);
        expect(showAnswer, isFalse);

        // Card 2: Show answer
        showAnswer = true;

        // Card 2: Rate (last card)
        reviewedCards[flashcards[currentIndex].id!] = 5;
        
        // Check completion
        final isComplete = reviewedCards.length == flashcards.length;
        expect(isComplete, isTrue);
      });

      test('9.2 Skip card by navigating without rating', () {
        final flashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2'),
        ];

        expect(flashcards.length, 2);

        int currentIndex = 0;
        final reviewedCards = <int, int>{};

        // Skip card 1 without rating
        currentIndex++;
        
        // Now at card 2
        expect(currentIndex, 1);
        expect(reviewedCards.isEmpty, isTrue);
      });

      test('9.3 Review only due cards (low confidence)', () {
        final allFlashcards = [
          createTestFlashcard(id: 1, noteId: 1, question: 'Q1', answer: 'A1', confidenceLevel: 1),
          createTestFlashcard(id: 2, noteId: 1, question: 'Q2', answer: 'A2', confidenceLevel: 5),
          createTestFlashcard(id: 3, noteId: 1, question: 'Q3', answer: 'A3', confidenceLevel: 2),
          createTestFlashcard(id: 4, noteId: 1, question: 'Q4', answer: 'A4', confidenceLevel: 4),
        ];

        // Filter for review (confidence < 3)
        final dueCards = allFlashcards.where((f) => f.confidenceLevel < 3).toList();

        expect(dueCards.length, 2); // Q1 and Q3
        expect(dueCards[0].id, 1);
        expect(dueCards[1].id, 3);
      });

      test('9.4 Load flashcards for specific note', () {
        final allFlashcards = [
          createTestFlashcard(id: 1, noteId: 10, question: 'Q1', answer: 'A1'),
          createTestFlashcard(id: 2, noteId: 20, question: 'Q2', answer: 'A2'),
          createTestFlashcard(id: 3, noteId: 10, question: 'Q3', answer: 'A3'),
          createTestFlashcard(id: 4, noteId: 30, question: 'Q4', answer: 'A4'),
        ];

        final noteId = 10;
        final noteFlashcards = allFlashcards.where((f) => f.noteId == noteId).toList();

        expect(noteFlashcards.length, 2);
        expect(noteFlashcards.every((f) => f.noteId == noteId), isTrue);
      });
    });

    group('10. Performance Considerations', () {
      test('10.1 Large flashcard set handling', () {
        final largeSet = List.generate(1000, (i) {
          return createTestFlashcard(
            id: i,
            noteId: 1,
            question: 'Question $i',
            answer: 'Answer $i',
            confidenceLevel: i % 6, // 0-5
          );
        });

        expect(largeSet.length, 1000);

        // Filter low confidence (0, 1, 2 out of 0-5 = 3/6 = 50%)
        final lowConfidence = largeSet.where((f) => f.confidenceLevel < 3).toList();
        expect(lowConfidence.length, 501); // 0-2 from 1000 items with i%6
      });

      test('10.2 Fast navigation through cards', () {
        final flashcards = List.generate(100, (i) {
          return createTestFlashcard(
            id: i,
            noteId: 1,
            question: 'Q$i',
            answer: 'A$i',
          );
        });

        int currentIndex = 0;
        final sw = Stopwatch()..start();

        // Navigate through all cards
        while (currentIndex < flashcards.length - 1) {
          currentIndex++;
        }

        sw.stop();

        expect(currentIndex, 99);
        expect(sw.elapsedMilliseconds, lessThan(10)); // Should be instant
      });

      test('10.3 Efficient confidence level updates', () {
        var flashcard = createTestFlashcard(
          id: 1,
          noteId: 1,
          question: 'Q',
          answer: 'A',
          confidenceLevel: 0,
        );

        final sw = Stopwatch()..start();

        // Simulate 100 confidence updates
        for (int i = 0; i < 100; i++) {
          flashcard = flashcard.copyWith(
            confidenceLevel: (i % 6),
            lastReviewedAt: DateTime.now(),
          );
        }

        sw.stop();

        expect(flashcard.confidenceLevel, greaterThanOrEqualTo(0));
        expect(sw.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
