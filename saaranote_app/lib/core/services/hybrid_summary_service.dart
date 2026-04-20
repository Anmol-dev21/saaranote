import 'dart:developer' as developer;

import 'llm_service.dart';
import '../utils/llm_prompt_builder.dart';

/// Hybrid summary enhancer that rewrites rule-based summaries via a local LLM.
class HybridSummaryService {
  static const int _maxInputChars = 1500;
  static const int _maxCacheEntries = 50;

  HybridSummaryService({LlmService? llmService})
      : _llmService = llmService ?? LlmService();

  final LlmService _llmService;
  final Map<String, String> _summaryCache = <String, String>{};

  /// Generate the final summary using a hybrid flow.
  /// Falls back to the structured summary when the LLM output is unusable.
  Future<String> generateFinalSummary(String structuredSummary) async {
    final trimmed = structuredSummary.trim();
    if (trimmed.isEmpty) return '';

    final safeInput = _truncateInput(trimmed);
    final cached = _summaryCache[safeInput];
    if (cached != null) {
      return cached;
    }
    developer.log('🧠 Hybrid AI started', name: 'HybridSummaryService');
    developer.log('Input length: ${safeInput.length}', name: 'HybridSummaryService');
    final rewritten = await rewriteSummary(safeInput);
    if (!_isValidLlmSummary(rewritten)) {
      developer.log('⚠️ LLM fallback used (invalid or empty response).',
          name: 'HybridSummaryService');
      final fallback = trimmed;
      _storeCache(safeInput, fallback);
      return fallback;
    }

    developer.log('LLM summary accepted.', name: 'HybridSummaryService');
    _storeCache(safeInput, rewritten);
    return rewritten;
  }

  /// Rewrite a structured summary using the local model.
  /// Returns an empty string if no rewrite is available.
  Future<String> rewriteSummary(String structuredSummary) async {
    final trimmed = structuredSummary.trim();
    if (trimmed.isEmpty) return '';

    final prompt = LlmPromptBuilder.buildSummaryPrompt(trimmed);
    developer.log('LLM summary rewrite started.', name: 'HybridSummaryService');
    try {
      final response = await _llmService.generateSummary(prompt);
      developer.log('LLM summary rewrite completed.', name: 'HybridSummaryService');
      return response.trim();
    } catch (e) {
      developer.log('LLM summary rewrite failed: $e', name: 'HybridSummaryService');
      return '';
    }
  }

  bool _isValidLlmSummary(String summary) {
    final trimmed = summary.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length < 60) return false;

    return trimmed.contains('Title:') &&
        trimmed.contains('Summary:') &&
        trimmed.contains('Key Points:');
  }

  String _truncateInput(String input) {
    if (input.length <= _maxInputChars) return input;
    return input.substring(0, _maxInputChars).trimRight();
  }

  void _storeCache(String key, String value) {
    if (value.isEmpty) return;
    if (_summaryCache.length >= _maxCacheEntries) {
      _summaryCache.remove(_summaryCache.keys.first);
    }
    _summaryCache[key] = value;
  }
}
