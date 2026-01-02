import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for extracting text from images using on-device OCR
/// 
/// Uses Google ML Kit Text Recognition for offline text extraction
class OcrService {
  final TextRecognizer _textRecognizer;

  /// Create an OcrService instance
  /// 
  /// By default, uses Latin script. For other scripts, pass a custom
  /// TextRecognizer configured for the target script.
  OcrService({TextRecognizer? textRecognizer})
      : _textRecognizer = textRecognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from an image file using on-device OCR
  /// 
  /// Returns the recognized text as a string. If no text is found,
  /// returns an empty string. Throws an exception if OCR processing fails.
  /// 
  /// Example:
  /// ```dart
  /// final ocrService = OcrService();
  /// final text = await ocrService.extractTextFromImage(imageFile);
  /// ```
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      // Validate file exists
      if (!await imageFile.exists()) {
        throw OcrException('Image file does not exist: ${imageFile.path}');
      }

      // Create input image from file
      final inputImage = InputImage.fromFile(imageFile);

      // Process the image
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract and return the text
      return recognizedText.text;
    } on Exception catch (e) {
      throw OcrException('Failed to extract text from image: ${e.toString()}');
    }
  }

  /// Extract text with detailed block information
  /// 
  /// Returns a structured result containing text blocks, lines, and elements
  /// with their bounding boxes and confidence levels.
  Future<OcrResult> extractTextWithDetails(File imageFile) async {
    try {
      // Validate file exists
      if (!await imageFile.exists()) {
        throw OcrException('Image file does not exist: ${imageFile.path}');
      }

      // Create input image from file
      final inputImage = InputImage.fromFile(imageFile);

      // Process the image
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Build structured result
      final blocks = <OcrTextBlock>[];

      for (final block in recognizedText.blocks) {
        final lines = <OcrTextLine>[];

        for (final line in block.lines) {
          final elements = <OcrTextElement>[];

          for (final element in line.elements) {
            elements.add(OcrTextElement(
              text: element.text,
              boundingBox: element.boundingBox,
              confidence: element.confidence,
            ));
          }

          lines.add(OcrTextLine(
            text: line.text,
            elements: elements,
            boundingBox: line.boundingBox,
            confidence: line.confidence,
          ));
        }

        blocks.add(OcrTextBlock(
          text: block.text,
          lines: lines,
          boundingBox: block.boundingBox,
          confidence: block.confidence,
        ));
      }

      return OcrResult(
        fullText: recognizedText.text,
        blocks: blocks,
      );
    } on Exception catch (e) {
      throw OcrException('Failed to extract text from image: ${e.toString()}');
    }
  }

  /// Check if the image likely contains text
  /// 
  /// Returns true if text is detected, false otherwise
  Future<bool> containsText(File imageFile) async {
    try {
      final text = await extractTextFromImage(imageFile);
      return text.trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Close and release resources
  /// 
  /// Should be called when the service is no longer needed
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

/// Structured OCR result with detailed information
class OcrResult {
  final String fullText;
  final List<OcrTextBlock> blocks;

  OcrResult({
    required this.fullText,
    required this.blocks,
  });

  /// Get total number of text blocks detected
  int get blockCount => blocks.length;

  /// Get total number of lines detected
  int get lineCount => blocks.fold(0, (sum, block) => sum + block.lines.length);

  /// Check if any text was detected
  bool get hasText => fullText.trim().isNotEmpty;
}

/// Represents a block of text in the OCR result
class OcrTextBlock {
  final String text;
  final List<OcrTextLine> lines;
  final Rect? boundingBox;
  final double? confidence;

  OcrTextBlock({
    required this.text,
    required this.lines,
    this.boundingBox,
    this.confidence,
  });
}

/// Represents a line of text within a block
class OcrTextLine {
  final String text;
  final List<OcrTextElement> elements;
  final Rect? boundingBox;
  final double? confidence;

  OcrTextLine({
    required this.text,
    required this.elements,
    this.boundingBox,
    this.confidence,
  });
}

/// Represents an individual text element (word/character)
class OcrTextElement {
  final String text;
  final Rect? boundingBox;
  final double? confidence;

  OcrTextElement({
    required this.text,
    this.boundingBox,
    this.confidence,
  });
}

/// Custom exception for OCR-related errors
class OcrException implements Exception {
  final String message;

  OcrException(this.message);

  @override
  String toString() => 'OcrException: $message';
}
