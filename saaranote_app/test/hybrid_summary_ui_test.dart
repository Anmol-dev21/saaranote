import 'package:flutter_test/flutter_test.dart';
import 'package:saaranote_app/core/services/hybrid_summary_service.dart';
import 'package:saaranote_app/core/services/llm_service.dart';
import 'package:saaranote_app/presentation/utils/summary_parser.dart';

class FakeLlmService extends LlmService {
  FakeLlmService({required this.response, this.throwOnCall = false});

  final String response;
  final bool throwOnCall;

  @override
  Future<String> generateSummary(String prompt) async {
    if (throwOnCall) {
      throw Exception('LLM unavailable');
    }
    return response;
  }
}

void main() {
  group('Hybrid summary UI basics', () {
    test('SummaryParser recognizes structured output', () {
      const text = '''Title: Test Title
Summary: This is a short summary.
Key Points:
- Point one
- Point two
''';

      final parsed = SummaryParser.parse(text);

      expect(parsed.isValid, isTrue);
      expect(parsed.title, 'Test Title');
      expect(parsed.summary, 'This is a short summary.');
      expect(parsed.keyPoints.length, 2);
    });

    test('SummaryParser rejects unstructured output', () {
      const text = 'This is a basic summary without labels.';

      final parsed = SummaryParser.parse(text);

      expect(parsed.isValid, isFalse);
    });

    test('HybridSummaryService falls back when LLM unavailable', () async {
      const baseSummary = 'Basic summary from rule-based engine.';
      final service = HybridSummaryService(
        llmService: FakeLlmService(response: '', throwOnCall: true),
      );

      final result = await service.generateFinalSummary(baseSummary);

      expect(result, baseSummary);
    });
  });
}
