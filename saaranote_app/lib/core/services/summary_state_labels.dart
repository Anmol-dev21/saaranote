import 'summary_generation_state.dart';

/// Utility class for summary state labels and descriptions
class SummaryStateLabels {
  /// Get the title for a summary generation state
  static String title(SummaryGenerationState state) {
    switch (state) {
      case SummaryGenerationState.aiEnhanced:
        return 'AI Enhanced Summary';
      case SummaryGenerationState.aiDisabled:
        return 'AI Disabled';
      case SummaryGenerationState.llmUnavailable:
        return 'LLM Unavailable';
      case SummaryGenerationState.timeout:
        return 'Timeout';
      case SummaryGenerationState.invalidFormat:
        return 'Invalid Format';
      case SummaryGenerationState.fallback:
        return 'Generated Summary';
    }
  }

  /// Get the subtitle/description for a summary generation state
  static String subtitle(SummaryGenerationState state) {
    switch (state) {
      case SummaryGenerationState.aiEnhanced:
        return 'Enhanced with AI to improve clarity and structure';
      case SummaryGenerationState.aiDisabled:
        return 'AI enhancement is disabled';
      case SummaryGenerationState.llmUnavailable:
        return 'LLM service is unavailable';
      case SummaryGenerationState.timeout:
        return 'Request timed out';
      case SummaryGenerationState.invalidFormat:
        return 'Invalid format returned';
      case SummaryGenerationState.fallback:
        return 'Automatically generated from your notes';
    }
  }

  /// Convert string to SummaryGenerationState
  static SummaryGenerationState fromString(String? value) {
    if (value == null || value.isEmpty) {
      return SummaryGenerationState.fallback;
    }
    try {
      return SummaryGenerationState.values.firstWhere(
        (state) => state.toString() == 'SummaryGenerationState.$value',
        orElse: () => SummaryGenerationState.fallback,
      );
    } catch (_) {
      return SummaryGenerationState.fallback;
    }
  }

  /// Get all available states
  static List<SummaryGenerationState> get availableStates {
    return SummaryGenerationState.values;
  }
}
