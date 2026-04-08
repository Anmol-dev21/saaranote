import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

/// Service for extracting text from PDF files
class PdfTextService {
  /// Extract text from all pages of a PDF file
  /// 
  /// Returns a combined string of all text content from the PDF.
  /// Returns an empty string if extraction fails or PDF has no text.
  Future<String> extractTextFromPdf(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final pdfDocument = sf_pdf.PdfDocument(inputBytes: bytes);
      final pageCount = pdfDocument.pages.count;
      
      if (pageCount == 0) {
        pdfDocument.dispose();
        return '';
      }
      
      // Extract text from all pages
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
      pdfDocument.dispose();
      return textBuffer.toString().trim();
    } catch (e) {
      // Return empty string on any error (file not found, invalid PDF, etc.)
      return '';
    }
  }
}
