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
  /// Extract text from all pages of a PDF file
  /// 
  /// Returns a combined string of all text content from the PDF.
  /// Returns an empty string if extraction fails or PDF has no text.
<<<<<<< Updated upstream
  Future<String> extractTextFromPdf(File pdfFile) async {
    try {
      // Create PDF document from file
      final pdfDocument = await PDFDoc.fromFile(pdfFile);
      
=======
  Future<String> extractTextFromPdf(
    File pdfFile, {
    bool enableOcrFallback = true,
    int maxOcrPages = 3,
  }) async {
        try {
      // Load PDF document from file bytes
      final bytes = await pdfFile.readAsBytes();
      final pdfDocument = sf_pdf.PdfDocument(inputBytes: bytes);

>>>>>>> Stashed changes
      // Get total number of pages
      final pageCount = pdfDocument.pages.count;
      
      if (pageCount == 0) {
        return '';
      }
      
      // Extract text from all pages
      final textBuffer = StringBuffer();
      
      for (int pageNum = 0; pageNum < pageCount; pageNum++) {
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
            if (pageNum < pageCount - 1) {
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
}
