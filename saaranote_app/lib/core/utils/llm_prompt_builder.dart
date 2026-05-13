class LlmPromptBuilder {
  /// Builds a STRICT prompt for Phi-3.
  /// Goal:
  /// - simplify language
  /// - preserve meaning
  /// - NEVER add information
  /// - keep output short and structured
  static String buildSummaryPrompt(String structuredSummary) {
    return '''
You are a STRICT note rewriting assistant.

TASK:
Rewrite the provided content into VERY SHORT student notes.

CRITICAL RULES:
- Use ONLY the information provided
- NEVER add examples
- NEVER explain extra details
- NEVER expand the topic
- NEVER infer anything
- NEVER mention industries or applications unless explicitly written
- NEVER generate extra sentences
- Keep everything concise
- Use simple beginner-friendly English
- Keep bullet points very short
- Output plain text only
- NO markdown
- NO bold text
- NO introductions
- NO conclusions

OUTPUT FORMAT (follow EXACTLY):

Title:
<2 to 5 words only>

Summary:
<1 or 2 short sentences only, max 30 words>

Key Points:
- <short bullet, max 8 words>
- <short bullet, max 8 words>
- <short bullet, max 8 words>

IMPORTANT:
If information is not present in the content,
DO NOT add it.
Output ONLY the three sections above.

CONTENT:
$structuredSummary
''';
  }
}