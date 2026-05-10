import 'dart:developer' as developer;

import 'llm_service.dart';
import 'summary_generation_state.dart';
import 'summary_result.dart';
import '../utils/llm_prompt_builder.dart';

/// Hybrid summary enhancer that rewrites rule-based summaries via a local LLM.
class HybridSummaryService {
  static const int _maxInputChars = 1500;
  static const int _maxCacheEntries = 50;

  HybridSummaryService({LlmService? llmService})
      : _llmService = llmService ?? LlmService();
  final LlmService _llmService;
  final Map<String, SummaryResult> _summaryCache = <String, SummaryResult>{};

  /// Generate the final summary using a hybrid flow.
  /// Falls back to the structured summary when the LLM output is unusable.
  Future<String> generateFinalSummary(String structuredSummary) async {
    final res = await generateFinalSummaryResult(structuredSummary);
    return res.summary;
  }

  /// New API: returns a structured result with state for accurate UI mapping.
  Future<SummaryResult> generateFinalSummaryResult(String structuredSummary) async {
    final trimmed = structuredSummary.trim();
    if (trimmed.isEmpty) return const SummaryResult(summary: '', state: SummaryGenerationState.fallback);

    final safeInput = _truncateInput(trimmed);
    final cached = _summaryCache[safeInput];
    if (cached != null) {
      return cached;
    }

    developer.log('🧠 Hybrid AI started', name: 'HybridSummaryService');
    developer.log('Input length: ${safeInput.length}', name: 'HybridSummaryService');

    final rewritten = await rewriteSummary(safeInput);

    // If LLM returned empty string, consider service unavailable for now
    if (rewritten.trim().isEmpty) {
      developer.log('⚠️ LLM returned empty response; using fallback.', name: 'HybridSummaryService');
      final fallback = SummaryResult(summary: trimmed, state: SummaryGenerationState.llmUnavailable);
      _storeCache(safeInput, fallback);
      return fallback;
    }

    if (!_isValidLlmSummary(rewritten)) {
      developer.log('⚠️ LLM returned invalid format; using fallback.', name: 'HybridSummaryService');
      final fallback = SummaryResult(summary: trimmed, state: SummaryGenerationState.invalidFormat);
      _storeCache(safeInput, fallback);
      return fallback;
    }

    developer.log('LLM summary accepted.', name: 'HybridSummaryService');
    final accepted = SummaryResult(summary: rewritten, state: SummaryGenerationState.aiEnhanced);
    _storeCache(safeInput, accepted);
    return accepted;
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

  void _storeCache(String key, SummaryResult value) {
    if (value.summary.isEmpty) return;
    if (_summaryCache.length >= _maxCacheEntries) {
      _summaryCache.remove(_summaryCache.keys.first);
    }
    _summaryCache[key] = value;
  }
}
