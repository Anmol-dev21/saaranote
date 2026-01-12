import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service for extracting text from PDF files
class PdfTextService {
  /// Extract text from all pages of a PDF file
  /// 
  /// Returns a combined string of all text content from the PDF.
  /// Returns an empty string if extraction fails or PDF has no text.
  Future<String> extractTextFromPdf(File pdfFile) async {
    try {
      // Load PDF document from file bytes
      final bytes = await pdfFile.readAsBytes();
      final pdfDocument = PdfDocument(inputBytes: bytes);
      
      // Get total number of pages
      final pageCount = pdfDocument.pages.count;
      
      if (pageCount == 0) {
        pdfDocument.dispose();
        return '';
      }
      
      // Extract text from all pages
      final textBuffer = StringBuffer();
      
      for (int pageNum = 0; pageNum < pageCount; pageNum++) {
        try {
          // Extract text using PdfTextExtractor
          final PdfTextExtractor extractor = PdfTextExtractor(pdfDocument);
          final pageText = extractor.extractText(startPageIndex: pageNum, endPageIndex: pageNum);
          
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
      
      // Dispose the document
      pdfDocument.dispose();
      
      return textBuffer.toString().trim();
    } catch (e) {
      // Return empty string on any error (file not found, invalid PDF, etc.)
      return '';
    }
  }
}
