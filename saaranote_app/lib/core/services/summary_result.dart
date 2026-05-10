import 'summary_generation_state.dart';

/// Lightweight structured result for summary generation used by hybrid
/// summary flow. Keeps a simple string summary and a state for UI mapping.
class SummaryResult {
  final String summary;
  final SummaryGenerationState state;

  const SummaryResult({
    required this.summary,
    required this.state,
  });
}
 
