import 'dart:io';
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
    try {
      final bytes = await pdfFile.readAsBytes();
      final pdfDocument = sf_pdf.PdfDocument(inputBytes: bytes);
      final pageCount = pdfDocument.pages.count;

      if (pageCount == 0) {
        pdfDocument.dispose();
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

          if (pageText.isNotEmpty) {
            textBuffer.write(pageText);
            if (pageNum < pageCount - 1) {
              textBuffer.write('\n\n');
            }
          }
        } catch (_) {
          continue;
        }
      }

      pdfDocument.dispose();

      final extracted = textBuffer.toString().trim();
      if (extracted.isNotEmpty || _ocrService == null || !enableOcrFallback) {
        return extracted;
      }

      return await _extractTextWithOcr(pdfFile, maxPages: maxOcrPages);
    } catch (_) {
      return '';
    }
  }

  Future<String> _extractTextWithOcr(File pdfFile, {int maxPages = 3}) async {
    if (_ocrService == null) return '';

    final buffer = StringBuffer();

    try {
      final doc = await pdf_render.PdfDocument.openFile(pdfFile.path);
      final pageCount = doc.pageCount;
      final pageLimit = pageCount < maxPages ? pageCount : maxPages;

      for (int pageNumber = 1; pageNumber <= pageLimit; pageNumber++) {
        final page = await doc.getPage(pageNumber);

        final renderWidth = (page.width * 2).toInt();
        final renderHeight = (page.height * 2).toInt();

        final pageImage = await page.render(
          width: renderWidth,
          height: renderHeight,
        );

        final pageText = await _ocrService.extractTextFromImageBytes(
          pageImage.pixels,
          pageImage.width,
          pageImage.height,
        );

        if (pageText.trim().isNotEmpty) {
          buffer.write(pageText.trim());
          buffer.write('\n\n');
        }

        pageImage.dispose();
      }

      await doc.dispose();
    } catch (_) {
      return '';
    }

    return buffer.toString().trim();
  }
}