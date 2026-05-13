import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;
import 'package:pdf_render/pdf_render.dart' as pdf_render;
import 'ocr_service.dart';

/// Service for extracting text from PDF files
class PdfTextService {
  final OcrService? _ocrService;

  PdfTextService([this._ocrService]);

  /// Extract text from all pages of a PDF file.
  ///
  /// Returns a combined string of all text content from the PDF.
  /// Returns an empty string if extraction fails or PDF has no text.
  Future<String> extractTextFromPdf(
    File pdfFile, {
    bool enableOcrFallback = true,
    int maxOcrPages = 3,
  }) async {
    sf_pdf.PdfDocument? pdfDocument;
    try {
      if (!await pdfFile.exists()) return '';
      final length = await pdfFile.length();
      if (length == 0) return '';
      final bytes = await pdfFile.readAsBytes();
      pdfDocument = sf_pdf.PdfDocument(inputBytes: bytes);
      final pageCount = pdfDocument.pages.count;

      if (pageCount == 0) {
        return '';
      }

      final textBuffer = StringBuffer();
      final extractor = sf_pdf.PdfTextExtractor(pdfDocument);

      for (int pageNum = 0; pageNum < pageCount; pageNum++) {
        try {
          final pageText = extractor.extractText(
            startPageIndex: pageNum,
            endPageIndex: pageNum,
          );

          final normalized = pageText.replaceAll('\u00a0', ' ').trimRight();
          if (normalized.isNotEmpty) {
            textBuffer.write(normalized);
            if (pageNum < pageCount - 1) {
              textBuffer.write('\n\n');
            }
          }
        } catch (_) {
          continue;
        }
      }

      final extracted = textBuffer.toString().trim();
      if (extracted.isNotEmpty || _ocrService == null || !enableOcrFallback) {
        return extracted;
      }

      return await _extractTextWithOcr(pdfFile, maxPages: maxOcrPages);
    } catch (_) {
      return '';
    } finally {
      pdfDocument?.dispose();
    }
  }

  Future<String> _extractTextWithOcr(File pdfFile, {int maxPages = 3}) async {
    if (_ocrService == null) return '';

    final buffer = StringBuffer();
    pdf_render.PdfDocument? doc;

    try {
      doc = await pdf_render.PdfDocument.openFile(pdfFile.path);
      final pageCount = doc.pageCount;
      final pageLimit = pageCount < maxPages ? pageCount : maxPages;

      for (int pageNumber = 1; pageNumber <= pageLimit; pageNumber++) {
        final page = await doc.getPage(pageNumber);
        try {
          final maxSide = page.width > page.height ? page.width : page.height;
          final baseScale = maxSide < 900
              ? 3.0
              : (maxSide < 1400 ? 2.5 : 2.0);
          final maxRenderDimension = 2200.0;
          final maxScale = maxRenderDimension / maxSide;
          final scale = math.min(baseScale, maxScale);
          final renderWidth = (page.width * scale).toInt();
          final renderHeight = (page.height * scale).toInt();

          final pageImage = await page.render(
            width: renderWidth,
            height: renderHeight,
          );

          try {
            final pageText = await _ocrService.extractTextFromImageBytes(
              pageImage.pixels,
              pageImage.width,
              pageImage.height,
            ).timeout(const Duration(seconds: 12));

            if (pageText.trim().isNotEmpty) {
              buffer.write(pageText.trim());
              buffer.write('\n\n');
            }
          } on TimeoutException {
            // Skip slow OCR pages to keep UI responsive.
          } finally {
            pageImage.dispose();
          }
        } finally {
          // PdfPage has no dispose; PdfDocument disposal cleans up pages.
        }
      }
    } catch (_) {
      return '';
    } finally {
      await doc?.dispose();
    }

    return buffer.toString().trim();
  }
}