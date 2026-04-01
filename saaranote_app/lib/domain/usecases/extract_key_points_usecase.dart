import '../../core/ai_engine.dart';

/// Use case for extracting key points and keywords from text
class ExtractKeyPointsUseCase {
  final AIEngine _aiEngine;

  ExtractKeyPointsUseCase(this._aiEngine);

  Future<KeyPointsResult> execute(ExtractKeyPointsParams params) async {
    try {
      return await _aiEngine.extractKeyPoints(
        text: params.text,
        maxChars: params.maxChars,
        maxPoints: params.maxPoints,
        maxKeywords: params.maxKeywords,
      );
    } catch (_) {
      return KeyPointsResult.empty();
    }
  }
}

class ExtractKeyPointsParams {
  final String text;
  final int maxChars;
  final int maxPoints;
  final int maxKeywords;

  const ExtractKeyPointsParams({
    required this.text,
    this.maxChars = 8000,
    this.maxPoints = 10,
    this.maxKeywords = 12,
  });
}
