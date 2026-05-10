/// Describes how a note summary was produced.
///
/// This is used to communicate precise fallback reasons (e.g. AI disabled,
/// timeout, invalid format) to the UI without changing layout.
enum SummaryGenerationState {
  /// LLM successfully rewrote the summary into structured output.
  aiEnhanced,

  /// AI enhancement was explicitly disabled by the user/config.
  aiDisabled,

  /// LLM service could not be reached or failed (connection/refused/etc.).
  llmUnavailable,

  /// LLM request exceeded the configured timeout.
  timeout,

  /// LLM returned output that did not match the expected structured format.
  invalidFormat,

  /// Fallback to basic (rule-based / non-structured) summary.
  fallback,
}
