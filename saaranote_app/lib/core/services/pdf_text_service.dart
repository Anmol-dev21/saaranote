import 'dart:io';
<<<<<<< Updated upstream
import 'package:pdf_text/pdf_text.dart';
=======
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;
import 'package:pdf_render/pdf_render.dart' as pdf_render;
import 'ocr_service.dart';
>>>>>>> Stashed changes

/// Service for extracting text from PDF files
class PdfTextService {
  final OcrService? _ocrService;

  PdfTextService([this._ocrService]);

  /// Extract text from all pages of a PDF file
  /// 
  /// Returns a combined string of all text content from the PDF.
  /// Returns an empty string if extraction fails or PDF has no text.
  Future<String> extractTextFromPdf(
    File pdfFile, {
    bool enableOcrFallback = true,
    int maxOcrPages = 3,
  }) async {
    try {
<<<<<<< Updated upstream
      // Create PDF document from file
      final pdfDocument = await PDFDoc.fromFile(pdfFile);
=======
      // Load PDF document from file bytes
      final bytes = await pdfFile.readAsBytes();
      final pdfDocument = sf_pdf.PdfDocument(inputBytes: bytes);
>>>>>>> Stashed changes
      
      // Get total number of pages
      final pageCount = pdfDocument.length;
      
      if (pageCount == 0) {
        return '';
      }
      
      // Extract text from all pages
      final textBuffer = StringBuffer();
      
      for (int pageNum = 1; pageNum <= pageCount; pageNum++) {
        try {
<<<<<<< Updated upstream
          final pageText = await pdfDocument.pageAt(pageNum).text;
=======
          // Extract text using PdfTextExtractor
          final sf_pdf.PdfTextExtractor extractor = sf_pdf.PdfTextExtractor(pdfDocument);
          final pageText = extractor.extractText(startPageIndex: pageNum, endPageIndex: pageNum);
>>>>>>> Stashed changes
          
          if (pageText.isNotEmpty) {
            textBuffer.write(pageText);
            
            // Add page separator if not the last page
            if (pageNum < pageCount) {
              textBuffer.write('\n\n');
            }
          }
        } catch (e) {
          // Continue with next page if one page fails
          continue;
        }
      }
      
<<<<<<< Updated upstream
      return textBuffer.toString().trim();
=======
      // Dispose the document
      pdfDocument.dispose();

      final extracted = textBuffer.toString().trim();

      if (extracted.isNotEmpty || _ocrService == null || !enableOcrFallback) {
        return extracted;
      }

      return await _extractTextWithOcr(pdfFile, maxPages: maxOcrPages);
>>>>>>> Stashed changes
    } catch (e) {
      // Return empty string on any error (file not found, invalid PDF, etc.)
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

        final pageText = await _ocrService!.extractTextFromImageBytes(
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
    } catch (e) {
      return '';
    }

    return buffer.toString().trim();
  }
}
