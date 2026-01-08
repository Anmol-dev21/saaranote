import 'dart:io';
import 'package:pdf_text/pdf_text.dart';

/// Service for extracting text from PDF files
class PdfTextService {
  /// Extract text from all pages of a PDF file
  /// 
  /// Returns a combined string of all text content from the PDF.
  /// Returns an empty string if extraction fails or PDF has no text.
  Future<String> extractTextFromPdf(File pdfFile) async {
    try {
      // Create PDF document from file
      final pdfDocument = await PDFDoc.fromFile(pdfFile);
      
      // Get total number of pages
      final pageCount = pdfDocument.length;
      
      if (pageCount == 0) {
        return '';
      }
      
      // Extract text from all pages
      final textBuffer = StringBuffer();
      
      for (int pageNum = 1; pageNum <= pageCount; pageNum++) {
        try {
          final pageText = await pdfDocument.pageAt(pageNum).text;
          
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
      
      return textBuffer.toString().trim();
    } catch (e) {
      // Return empty string on any error (file not found, invalid PDF, etc.)
      return '';
    }
  }
}
