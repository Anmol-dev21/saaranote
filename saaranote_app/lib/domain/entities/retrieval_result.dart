import 'document_chunk.dart';

/// Result from the retrieval pipeline
class RetrievalResult {
  final DocumentChunk chunk;
  final double score;
  final RetrievalMethod method;

  const RetrievalResult({
    required this.chunk,
    required this.score,
    required this.method,
  });

  RetrievalResult copyWith({
    DocumentChunk? chunk,
    double? score,
    RetrievalMethod? method,
  }) {
    return RetrievalResult(
      chunk: chunk ?? this.chunk,
      score: score ?? this.score,
      method: method ?? this.method,
    );
  }
}

/// Method used for retrieval
enum RetrievalMethod {
  keyword,
  semantic,
  hybrid,
}
