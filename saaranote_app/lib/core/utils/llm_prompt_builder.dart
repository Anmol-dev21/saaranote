class LlmPromptBuilder {
  /// Build a lightweight prompt instructing the local LLM to rewrite a
  /// structured summary into a human-friendly, well-formatted summary.
  static String buildSummaryPrompt(String structuredSummary) {
    return '''Rewrite the following structured summary into a concise, readable, and professional summary.
Keep the important points and preserve any titles or key bullets. Format the result with a clear Title, a short Summary, and a few Key Points.

Input:
$structuredSummary

Output format:
Title: <short title>
Summary: <one to three sentences>
Key Points: <bullet points separated by commas or newlines>
''';
  }
}
