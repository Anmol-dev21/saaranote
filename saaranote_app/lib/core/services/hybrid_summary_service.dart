import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../utils/llm_prompt_builder.dart';
import 'llm_service.dart';

class HybridSummaryService {
  final LlmService _llmService;
  final int _maxInputChars;
  final int _maxCacheEntries;
  final int _minResponseChars;

  final LinkedHashMap<String, String> _cache = LinkedHashMap();
  final Map<String, Future<String?>> _inFlight = {};

  HybridSummaryService(
    this._llmService, {
    int maxInputChars = 2400,
    int maxCacheEntries = 48,
    int minResponseChars = 80,
  })  : _maxInputChars = maxInputChars,
        _maxCacheEntries = maxCacheEntries,
        _minResponseChars = minResponseChars;

  Future<String?> enhanceSummary(String structuredSummary) async {
    final trimmed = structuredSummary.trim();
    if (trimmed.isEmpty) return null;

    final safeInput = _truncate(trimmed, _maxInputChars);
    final prompt = LlmPromptBuilder.buildSummaryPrompt(safeInput);

    final cached = _getCached(prompt);
    if (cached != null) return cached;

    final existing = _inFlight[prompt];
    if (existing != null) return existing;

    final future = _fetchAndValidate(prompt);
    _inFlight[prompt] = future;

    final result = await future;
    _inFlight.remove(prompt);

    if (result != null) {
      _cacheResult(prompt, result);
    }

    return result;
  }

  Future<String?> _fetchAndValidate(String prompt) async {
    final response = await _llmService.generateSummary(prompt);
    if (response == null) return null;

    if (!_isValidResponse(response)) {
      debugPrint('HybridSummaryService: Rejected invalid LLM response.');
      return null;
    }

    return response.trim();
  }

  String? _getCached(String prompt) {
    final cached = _cache[prompt];
    if (cached == null) return null;

    _cache.remove(prompt);
    _cache[prompt] = cached;
    return cached;
  }

  void _cacheResult(String prompt, String result) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[prompt] = result;
  }

  bool _isValidResponse(String response) {
    final trimmed = response.trim();
    if (trimmed.length < _minResponseChars) return false;

    if (!trimmed.contains('Title:') ||
        !trimmed.contains('Summary:') ||
        !trimmed.contains('Key Points:')) {
      return false;
    }

    if (!RegExp(r'^[\-\*\u2022]\s+.+', multiLine: true).hasMatch(trimmed)) {
      return false;
    }

    if (RegExp(r'```|^#|\*\*|__|`', multiLine: true).hasMatch(trimmed)) {
      return false;
    }

    if (RegExp(r'^\s*(Sections|Detailed):', multiLine: true)
        .hasMatch(trimmed)) {
      return false;
    }

    if (RegExp(r"as an ai|i cannot|i can't|sorry", caseSensitive: false)
        .hasMatch(trimmed)) {
      return false;
    }

    final titleLine = RegExp(r'^Title:\s*(.+)$', multiLine: true)
        .firstMatch(trimmed)
        ?.group(1)
        ?.trim();
    if (titleLine == null || titleLine.isEmpty) {
      return false;
    }

    return true;
  }

  String _truncate(String text, int maxChars) {
    if (maxChars <= 0 || text.length <= maxChars) return text;
    return text.substring(0, maxChars);
  }
}
