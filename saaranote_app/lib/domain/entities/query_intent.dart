/// Intent classification for user queries
enum QueryIntent {
  /// Direct question answering: "What is X?", "How does Y work?"
  questionAnswering,

  /// Request for summary: "Summarize...", "Give overview..."
  summarization,

  /// Request for list/extraction: "List...", "Find all..."
  listExtraction,

  /// Request for definition: "Define...", "What does X mean?"
  definition,

  /// Comparison request: "Compare...", "Difference between..."
  comparison,
}
