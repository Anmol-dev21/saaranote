/// Prompt builder for LLM summary rewriting.
class LlmPromptBuilder {
  /// Build a structured prompt for rewriting summaries.
  static String buildSummaryPrompt(String structuredSummary) {
    final cleaned = structuredSummary.trim();
    final content = cleaned.isEmpty
        ? 'Not enough information to summarize.'
        : cleaned;

    return '''You are a rewriting assistant. Use ONLY the content below.
Do NOT add new facts. Do NOT guess or speculate.
Use simple language and short sentences.
If the content is insufficient, say: Not enough information to summarize.

Return the result in this exact format:
Title: <short title>
Summary: <2-4 sentences>
Key Points:
- <bullet 1>
- <bullet 2>
- <bullet 3>

Content:
$content
''';
  }
}
