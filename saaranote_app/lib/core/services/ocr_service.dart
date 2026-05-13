import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/text_processor.dart';

class OcrService {
  static const Duration _ocrTimeout = Duration(seconds: 12);
  static const Duration _preprocessTimeout = Duration(seconds: 3);
  final bool enablePreprocessing;
  final int maxImageDimension;
  final double contrast;
  final double brightness;
  final bool enableDenoise;
  final int denoiseRadius;
  final bool enableThresholding;

  OcrService({
    this.enablePreprocessing = true,
    this.maxImageDimension = 2000,
    this.contrast = 1.15,
    this.brightness = 0.04,
    this.enableDenoise = true,
    this.denoiseRadius = 1,
    this.enableThresholding = true,
  });

  Future<String> extractTextFromImage(File imageFile) async {
    _PreparedInputImage? prepared;
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final originalResult = await _processImage(
        textRecognizer,
        InputImage.fromFile(imageFile),
        stage: 'original-first',
      );

      final shouldPreprocess = _shouldTryPreprocess(originalResult);
      if (!shouldPreprocess || !enablePreprocessing) {
        debugPrint('OCR: using original result.');
        return originalResult.text;
      }

      debugPrint('OCR: preprocessing triggered for low confidence/empty text.');
      prepared = await _prepareInputImage(imageFile);
      if (!prepared.usedPreprocessing) {
        return originalResult.text;
      }

      final preprocessedResult = await _processImage(
        textRecognizer,
        prepared.inputImage,
        stage: prepared.preprocessLabel,
      );

      if (_isBetter(preprocessedResult, originalResult)) {
        debugPrint('OCR: using preprocessed result.');
        return preprocessedResult.text;
      }

      return originalResult.text;
    } catch (e) {
      debugPrint('OCR: Failed to extract text (${e.toString()}).');
      return '';
    } finally {
      await textRecognizer.close();
      if (prepared != null) {
        await prepared.dispose();
      }
    }
  }

  Future<OcrDebugResult> debugAnalyzeImage(
    File imageFile, {
    bool runPreprocessing = true,
    bool enableThresholdingOverride = true,
    bool enableDenoiseOverride = true,
  }) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _PreparedInputImage? prepared;
    final originalStopwatch = Stopwatch()..start();
    final originalResult = await _processImage(
      textRecognizer,
      InputImage.fromFile(imageFile),
      stage: 'debug-original',
    );
    originalStopwatch.stop();

    _OcrResult? preprocessedResult;
    int preprocessedMs = 0;
    if (runPreprocessing) {
      prepared = await _prepareInputImageWithOverrides(
        imageFile,
        enableThresholdingOverride: enableThresholdingOverride,
        enableDenoiseOverride: enableDenoiseOverride,
      );
      if (prepared.usedPreprocessing) {
        final preprocessStopwatch = Stopwatch()..start();
        preprocessedResult = await _processImage(
          textRecognizer,
          prepared.inputImage,
          stage: prepared.preprocessLabel,
        );
        preprocessStopwatch.stop();
        preprocessedMs = preprocessStopwatch.elapsedMilliseconds;
      }
    }

    final selected = _selectBestCandidate(originalResult, preprocessedResult);
    final cleaned = TextProcessor.cleanText(selected.text);
    final wordCount = TextProcessor.countWords(cleaned);

    await textRecognizer.close();
    if (prepared != null) {
      await prepared.dispose();
    }

    return OcrDebugResult(
      originalText: originalResult.text,
      originalConfidence: originalResult.confidence,
      originalDurationMs: originalStopwatch.elapsedMilliseconds,
      preprocessedText: preprocessedResult?.text ?? '',
      preprocessedConfidence: preprocessedResult?.confidence,
      preprocessedDurationMs: preprocessedMs,
      selectedText: selected.text,
      selectedConfidence: selected.confidence,
      selectedSource: selected.source,
      cleanedText: cleaned,
      wordCount: wordCount,
      preprocessingUsed: prepared?.usedPreprocessing ?? false,
    );
  }

  Future<String> extractTextFromImageBytes(
    Uint8List bytes,
    int width,
    int height, {
    InputImageRotation rotation = InputImageRotation.rotation0deg,
  }) async {
    try {
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final originalResult = await _processImage(
        textRecognizer,
        InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(width.toDouble(), height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: width * 4,
          ),
        ),
        stage: 'original-bytes',
      );

      final shouldPreprocess = _shouldTryPreprocess(originalResult);
      if (!shouldPreprocess || !enablePreprocessing) {
        debugPrint('OCR: using original byte result.');
        await textRecognizer.close();
        return originalResult.text;
      }

      debugPrint('OCR: preprocessing bytes triggered for low confidence/empty text.');
      final processed = await _preprocessBytes(bytes, width, height);
      if (processed == null) {
        await textRecognizer.close();
        return originalResult.text;
      }

      final preprocessedResult = await _processImage(
        textRecognizer,
        InputImage.fromBytes(
          bytes: processed.bytes,
          metadata: InputImageMetadata(
            size: Size(processed.width.toDouble(), processed.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: processed.width * 4,
          ),
        ),
        stage: 'preprocessed-bytes',
      );

      final best = _isBetter(preprocessedResult, originalResult)
          ? preprocessedResult
          : originalResult;

      await textRecognizer.close();
      return best.text;
    } catch (e) {
      debugPrint('OCR: Failed to extract text from bytes (${e.toString()}).');
      return '';
    }
  }

  Future<_OcrResult> _processImage(
    TextRecognizer textRecognizer,
    InputImage inputImage, {
    required String stage,
  }) async {
    try {
      final recognizedText = await textRecognizer
          .processImage(inputImage)
          .timeout(_ocrTimeout);
      final text = recognizedText.text;
      final confidence = _averageBlockConfidence(recognizedText);
      _logOcrResult(
        stage: stage,
        text: text,
        confidence: confidence,
      );
      return _OcrResult(text: text, confidence: confidence);
    } catch (e) {
      debugPrint('OCR: stage=$stage failed (${e.toString()}).');
      return const _OcrResult(text: '', confidence: null);
    }
  }

  bool _shouldTryPreprocess(_OcrResult result) {
    final length = result.text.trim().length;
    if (length == 0) return true;

    final quality = _textQualityScore(result.text);
    final confidence = result.confidence ?? 0.0;
    if (confidence < 0.35) return true;
    if (length < 10) return true;
    return quality < 35.0;
  }

  bool _isBetter(_OcrResult candidate, _OcrResult baseline) {
    if (candidate.text.trim().isEmpty) return false;
    if (baseline.text.trim().isEmpty) return true;

    final candidateScore = _scoreCandidate(candidate);
    final baselineScore = _scoreCandidate(baseline);
    return candidateScore > baselineScore;
  }

  double _scoreCandidate(_OcrResult result) {
    final qualityScore = _textQualityScore(result.text);
    final confidenceScore = (result.confidence ?? 0.0) * 25.0;
    return qualityScore + confidenceScore;
  }

  double _textQualityScore(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0.0;

    final lines = trimmed.split(RegExp(r'\n+')).where((l) => l.trim().isNotEmpty).toList();
    final tokens = trimmed
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .toList();

    if (tokens.isEmpty) return 0.0;

    final wordCount = tokens.length;
    int validWords = 0;
    int brokenTokens = 0;
    int garbageTokens = 0;
    int repeatedTokens = 0;

    String? lastToken;
    int shortWords = 0;
    for (final token in tokens) {
      final normalized = token.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final hasAlphaNum = RegExp(r'[a-z0-9]').hasMatch(token);

      if (normalized.length >= 2 && hasAlphaNum) {
        validWords++;
      }

      if (normalized.length <= 1) {
        shortWords++;
      }

      if (!hasAlphaNum || RegExp(r'[^a-z0-9]{2,}').hasMatch(token)) {
        garbageTokens++;
      }

      if (RegExp(r'[a-z][0-9]|[0-9][a-z]').hasMatch(normalized)) {
        brokenTokens++;
      }

      if (lastToken != null && normalized == lastToken) {
        repeatedTokens++;
      }
      lastToken = normalized;
    }

    final validRatio = validWords / wordCount;
    final brokenRatio = brokenTokens / wordCount;
    final garbageRatio = garbageTokens / wordCount;
    final shortRatio = shortWords / wordCount;
    final repeatRatio = repeatedTokens / wordCount;

    final multiSpaceCount = RegExp(r'\s{2,}').allMatches(text).length;
    final spacingQuality = 1.0 - (multiSpaceCount / (wordCount + 1));

    int lineWithWords = 0;
    for (final line in lines) {
      if (line.trim().split(RegExp(r'\s+')).length >= 2) {
        lineWithWords++;
      }
    }
    final lineQuality = lines.isEmpty ? 0.0 : lineWithWords / lines.length;

    final score = (wordCount * 1.2) +
        (validRatio * 40.0) +
        (spacingQuality * 15.0) +
        (lineQuality * 15.0) -
        (brokenRatio * 30.0) -
        (garbageRatio * 40.0) -
        (shortRatio * 10.0) -
        (repeatRatio * 15.0);

    return score.clamp(0.0, 120.0);
  }

  Future<_ProcessedBytes?> _preprocessBytes(
    Uint8List bytes,
    int width,
    int height,
  ) async {
    try {
      final processed = await compute(_preprocessRawImageBytes, {
        'bytes': bytes,
        'width': width,
        'height': height,
        'maxDimension': maxImageDimension,
        'contrast': contrast,
        'brightness': brightness,
        'enableDenoise': enableDenoise,
        'denoiseRadius': denoiseRadius,
        'enableThresholding': enableThresholding,
      }).timeout(_preprocessTimeout);

      if (processed == null) return null;
      return _ProcessedBytes(
        bytes: processed['bytes'] as Uint8List,
        width: processed['width'] as int,
        height: processed['height'] as int,
      );
    } catch (_) {
      debugPrint('OCR: Preprocessing timed out, using original bytes.');
      return null;
    }
  }

  void _logOcrResult({
    required String stage,
    required String text,
    required double? confidence,
  }) {
    final confidenceLabel = confidence == null
        ? 'n/a'
        : confidence.toStringAsFixed(3);
    debugPrint(
      'OCR: stage=$stage rawLength=${text.length} confidence=$confidenceLabel',
    );
  }

  double? _averageBlockConfidence(RecognizedText recognizedText) {
    double total = 0.0;
    int count = 0;

    for (final block in recognizedText.blocks) {
      try {
        final confidence = (block as dynamic).confidence;
        if (confidence is num) {
          total += confidence.toDouble();
          count++;
        }
      } catch (_) {
        // Confidence not available on this platform/version.
      }
    }

    if (count == 0) return null;
    return total / count;
  }

  Future<_PreparedInputImage> _prepareInputImage(File imageFile) async {
    if (!enablePreprocessing) {
      return _PreparedInputImage(
        InputImage.fromFile(imageFile),
        usedPreprocessing: false,
        preprocessLabel: 'original',
      );
    }

    try {
      final bytes = await imageFile.readAsBytes();
      Uint8List? processedBytes;
      try {
        processedBytes = await compute(_preprocessImageBytes, {
          'bytes': bytes,
          'maxDimension': maxImageDimension,
          'contrast': contrast,
          'brightness': brightness,
          'enableDenoise': enableDenoise,
          'denoiseRadius': denoiseRadius,
          'enableThresholding': enableThresholding,
        }).timeout(_preprocessTimeout);
      } catch (_) {
        debugPrint('OCR: Preprocessing timed out, using original file.');
      }

      if (processedBytes == null) {
        return _PreparedInputImage(
          InputImage.fromFile(imageFile),
          usedPreprocessing: false,
          preprocessLabel: 'original',
        );
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'ocr_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final tempFile = File(path.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(processedBytes, flush: true);

      return _PreparedInputImage(
        InputImage.fromFile(tempFile),
        tempFile: tempFile,
        usedPreprocessing: true,
        preprocessLabel: 'preprocessed',
      );
    } catch (_) {
      return _PreparedInputImage(
        InputImage.fromFile(imageFile),
        usedPreprocessing: false,
        preprocessLabel: 'original',
      );
    }
  }

  Future<_PreparedInputImage> _prepareInputImageWithOverrides(
    File imageFile, {
    required bool enableThresholdingOverride,
    required bool enableDenoiseOverride,
  }) async {
    if (!enablePreprocessing) {
      return _PreparedInputImage(
        InputImage.fromFile(imageFile),
        usedPreprocessing: false,
        preprocessLabel: 'original',
      );
    }

    try {
      final bytes = await imageFile.readAsBytes();
      Uint8List? processedBytes;
      try {
        processedBytes = await compute(_preprocessImageBytes, {
          'bytes': bytes,
          'maxDimension': maxImageDimension,
          'contrast': contrast,
          'brightness': brightness,
          'enableDenoise': enableDenoiseOverride,
          'denoiseRadius': denoiseRadius,
          'enableThresholding': enableThresholdingOverride,
        }).timeout(_preprocessTimeout);
      } catch (_) {
        debugPrint('OCR: Preprocessing timed out, using original file.');
      }

      if (processedBytes == null) {
        return _PreparedInputImage(
          InputImage.fromFile(imageFile),
          usedPreprocessing: false,
          preprocessLabel: 'original',
        );
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'ocr_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final tempFile = File(path.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(processedBytes, flush: true);

      return _PreparedInputImage(
        InputImage.fromFile(tempFile),
        tempFile: tempFile,
        usedPreprocessing: true,
        preprocessLabel: 'preprocessed',
      );
    } catch (_) {
      return _PreparedInputImage(
        InputImage.fromFile(imageFile),
        usedPreprocessing: false,
        preprocessLabel: 'original',
      );
    }
  }

  _SelectedCandidate _selectBestCandidate(
    _OcrResult original,
    _OcrResult? preprocessed,
  ) {
    if (preprocessed == null) {
      return _SelectedCandidate(
        text: original.text,
        confidence: original.confidence,
        source: 'original',
      );
    }

    final chosen = _isBetter(preprocessed, original) ? preprocessed : original;
    final source = chosen == preprocessed ? 'preprocessed' : 'original';
    return _SelectedCandidate(
      text: chosen.text,
      confidence: chosen.confidence,
      source: source,
    );
  }

}

Uint8List? _preprocessImageBytes(Map<String, dynamic> payload) {
  final bytes = payload['bytes'] as Uint8List;
  final maxDimension = payload['maxDimension'] as int;
  final contrast = payload['contrast'] as double;
  final brightness = payload['brightness'] as double;
  final enableDenoise = payload['enableDenoise'] as bool? ?? true;
  final denoiseRadius = payload['denoiseRadius'] as int? ?? 1;
  final enableThresholding = payload['enableThresholding'] as bool? ?? true;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  var image = decoded;
  final width = image.width;
  final height = image.height;
  final maxSide = width > height ? width : height;

  if (maxSide > maxDimension) {
    final scale = maxDimension / maxSide;
    image = img.copyResize(
      image,
      width: (width * scale).round(),
      height: (height * scale).round(),
    );
  }

  image = img.grayscale(image);
  var stats = _computeLuminanceStats(image);

  final lowContrast = stats.stdDev < 0.18;
  final boostedContrast = lowContrast ? contrast + 0.1 : contrast;
  final boostedBrightness = lowContrast ? brightness + 0.01 : brightness;

  image = img.adjustColor(
    image,
    contrast: boostedContrast,
    brightness: boostedBrightness,
  );

  stats = _computeLuminanceStats(image);

  if (enableDenoise && stats.noise > 0.22 && denoiseRadius > 0) {
    image = img.gaussianBlur(image, radius: denoiseRadius);
    stats = _computeLuminanceStats(image);
  }

  if (enableThresholding && _shouldThreshold(stats)) {
    final threshold = _pickThreshold(stats.mean);
    image = img.luminanceThreshold(image, threshold: threshold);
  }

  final encoded = img.encodeJpg(image, quality: 92);
  return Uint8List.fromList(encoded);
}

Map<String, dynamic>? _preprocessRawImageBytes(Map<String, dynamic> payload) {
  final bytes = payload['bytes'] as Uint8List;
  final width = payload['width'] as int;
  final height = payload['height'] as int;
  final maxDimension = payload['maxDimension'] as int;
  final contrast = payload['contrast'] as double;
  final brightness = payload['brightness'] as double;
  final enableDenoise = payload['enableDenoise'] as bool? ?? true;
  final denoiseRadius = payload['denoiseRadius'] as int? ?? 1;
  final enableThresholding = payload['enableThresholding'] as bool? ?? true;

  if (width <= 0 || height <= 0) return null;

  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: bytes.buffer,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  );

  var processed = image;
  final maxSide = processed.width > processed.height
      ? processed.width
      : processed.height;

  if (maxSide > maxDimension) {
    final scale = maxDimension / maxSide;
    processed = img.copyResize(
      processed,
      width: (processed.width * scale).round(),
      height: (processed.height * scale).round(),
    );
  }

  processed = img.grayscale(processed);
  var stats = _computeLuminanceStats(processed);

  final lowContrast = stats.stdDev < 0.18;
  final boostedContrast = lowContrast ? contrast + 0.1 : contrast;
  final boostedBrightness = lowContrast ? brightness + 0.01 : brightness;

  processed = img.adjustColor(
    processed,
    contrast: boostedContrast,
    brightness: boostedBrightness,
  );

  stats = _computeLuminanceStats(processed);
  if (enableDenoise && stats.noise > 0.22 && denoiseRadius > 0) {
    processed = img.gaussianBlur(processed, radius: denoiseRadius);
    stats = _computeLuminanceStats(processed);
  }

  if (enableThresholding && _shouldThreshold(stats)) {
    final threshold = _pickThreshold(stats.mean);
    processed = img.luminanceThreshold(processed, threshold: threshold);
  }

  final outputBytes = processed.getBytes(
    order: img.ChannelOrder.bgra,
    alpha: 255,
  );

  return {
    'bytes': outputBytes,
    'width': processed.width,
    'height': processed.height,
  };
}

class _LuminanceStats {
  final double mean;
  final double stdDev;
  final double noise;

  const _LuminanceStats({
    required this.mean,
    required this.stdDev,
    required this.noise,
  });
}

_LuminanceStats _computeLuminanceStats(img.Image image) {
  final width = image.width;
  final height = image.height;
  if (width == 0 || height == 0) {
    return const _LuminanceStats(mean: 0.0, stdDev: 0.0, noise: 0.0);
  }

  final minSide = width < height ? width : height;
  final step = math.max(4, math.min(12, (minSide / 80).round()));

  double sum = 0.0;
  double sumSq = 0.0;
  double noiseSum = 0.0;
  int count = 0;
  int noiseCount = 0;

  for (int y = 0; y < height; y += step) {
    for (int x = 0; x < width; x += step) {
      final pixel = image.getPixel(x, y);
      final lum = pixel.luminanceNormalized.toDouble();
      sum += lum;
      sumSq += lum * lum;
      count++;

      if (x + step < width) {
        final right = image.getPixel(x + step, y);
        noiseSum += (lum - right.luminanceNormalized).abs();
        noiseCount++;
      }

      if (y + step < height) {
        final down = image.getPixel(x, y + step);
        noiseSum += (lum - down.luminanceNormalized).abs();
        noiseCount++;
      }
    }
  }

  final mean = count > 0 ? sum / count : 0.0;
  final variance = count > 0 ? (sumSq / count) - (mean * mean) : 0.0;
  final stdDev = variance > 0 ? math.sqrt(variance) : 0.0;
  final noise = noiseCount > 0 ? noiseSum / noiseCount : 0.0;

  return _LuminanceStats(mean: mean, stdDev: stdDev, noise: noise);
}

bool _shouldThreshold(_LuminanceStats stats) {
  final mean = stats.mean;
  final stdDev = stats.stdDev;
  final noise = stats.noise;

  final likelyScanned = mean >= 0.68 && stdDev <= 0.26;
  final moderateContrast = stdDev >= 0.24 && mean >= 0.55;
  final stableSurface = noise < 0.15;

  return stableSurface && (likelyScanned || moderateContrast);
}

double _pickThreshold(double mean) {
  final threshold = mean * 0.92;
  return threshold.clamp(0.46, 0.72);
}

class _PreparedInputImage {
  final InputImage inputImage;
  final File? tempFile;
  final bool usedPreprocessing;
  final String preprocessLabel;

  const _PreparedInputImage(
    this.inputImage, {
    this.tempFile,
    required this.usedPreprocessing,
    required this.preprocessLabel,
  });

  Future<void> dispose() async {
    final file = tempFile;
    if (file == null) return;
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore cleanup failures
    }
  }
}

class _OcrResult {
  final String text;
  final double? confidence;

  const _OcrResult({
    required this.text,
    required this.confidence,
  });
}

class _ProcessedBytes {
  final Uint8List bytes;
  final int width;
  final int height;

  const _ProcessedBytes({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

class _SelectedCandidate {
  final String text;
  final double? confidence;
  final String source;

  const _SelectedCandidate({
    required this.text,
    required this.confidence,
    required this.source,
  });
}

class OcrDebugResult {
  final String originalText;
  final double? originalConfidence;
  final int originalDurationMs;
  final String preprocessedText;
  final double? preprocessedConfidence;
  final int preprocessedDurationMs;
  final String selectedText;
  final double? selectedConfidence;
  final String selectedSource;
  final String cleanedText;
  final int wordCount;
  final bool preprocessingUsed;

  const OcrDebugResult({
    required this.originalText,
    required this.originalConfidence,
    required this.originalDurationMs,
    required this.preprocessedText,
    required this.preprocessedConfidence,
    required this.preprocessedDurationMs,
    required this.selectedText,
    required this.selectedConfidence,
    required this.selectedSource,
    required this.cleanedText,
    required this.wordCount,
    required this.preprocessingUsed,
  });
}
