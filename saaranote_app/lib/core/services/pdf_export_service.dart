import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_summary.dart';
import '../../domain/entities/flashcard.dart';

/// Service for exporting notes to PDF format
class PdfExportService {
  /// Export a note to PDF file
  /// 
  /// Creates a formatted PDF document with the note content,
  /// summary, and optional flashcards.
  /// Returns a File object pointing to the generated PDF in temp directory.
  Future<File> exportNoteToPdf(
    Note note, {
    NoteSummary? summary,
    List<Flashcard>? flashcards,
  }) async {
    final pdf = pw.Document();

    // Add pages to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Title section
            _buildTitle(note.title),
            pw.SizedBox(height: 8),
            _buildMetadata(note),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),

            // Content section
            _buildSectionHeader('Content'),
            pw.SizedBox(height: 10),
            _buildContent(note.content),
            pw.SizedBox(height: 20),

            // Summary section (if available)
            if (summary != null) ...[
              pw.Divider(),
              pw.SizedBox(height: 20),
              _buildSectionHeader('Summary'),
              pw.SizedBox(height: 10),
              _buildSummary(summary.summaryText),
              pw.SizedBox(height: 20),
            ],

            // Key points section
            pw.Divider(),
            pw.SizedBox(height: 20),
            _buildSectionHeader('Key Points'),
            pw.SizedBox(height: 10),
            _buildKeyPoints(note.content),
            pw.SizedBox(height: 20),

            // Flashcards section (if available)
            if (flashcards != null && flashcards.isNotEmpty) ...[
              pw.Divider(),
              pw.SizedBox(height: 20),
              _buildSectionHeader('Flashcards'),
              pw.SizedBox(height: 10),
              _buildFlashcards(flashcards),
            ],
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          );
        },
      ),
    );

    // Save to temporary directory with fallback
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _sanitizeFileName(note.title);
      final file = File('${tempDir.path}/$fileName.pdf');
      
      await file.writeAsBytes(await pdf.save());
      
      return file;
    } catch (e) {
      // Fallback to app documents directory if temp directory fails
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = _sanitizeFileName(note.title);
      final file = File('${appDir.path}/$fileName.pdf');
      
      await file.writeAsBytes(await pdf.save());
      
      return file;
    }
  }

  /// Build title section
  pw.Widget _buildTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue900,
      ),
    );
  }

  /// Build metadata section
  pw.Widget _buildMetadata(Note note) {
    final createdDate = _formatDate(note.createdAt);
    final updatedDate = _formatDate(note.updatedAt);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Created: $createdDate',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Last Updated: $updatedDate',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  /// Build section header
  pw.Widget _buildSectionHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue800,
      ),
    );
  }

  /// Build content section
  pw.Widget _buildContent(String content) {
    return pw.Text(
      content,
      style: const pw.TextStyle(
        fontSize: 12,
        lineSpacing: 1.5,
      ),
      textAlign: pw.TextAlign.justify,
    );
  }

  /// Build summary section
  pw.Widget _buildSummary(String summaryText) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
      ),
      child: pw.Text(
        summaryText,
        style: const pw.TextStyle(
          fontSize: 12,
          lineSpacing: 1.4,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  /// Build key points section
  pw.Widget _buildKeyPoints(String content) {
    final sentences = content.split('.').where((s) => s.trim().isNotEmpty).take(5).toList();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: sentences.map((sentence) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 6,
                height: 6,
                margin: const pw.EdgeInsets.only(top: 5, right: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue600,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  sentence.trim(),
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.3),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build flashcards section
  pw.Widget _buildFlashcards(List<Flashcard> flashcards) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: flashcards.asMap().entries.map((entry) {
        final index = entry.key;
        final flashcard = entry.value;
        
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Flashcard ${index + 1}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Q: ',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      flashcard.question,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'A: ',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      flashcard.answer,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Sanitize file name by removing invalid characters
  String _sanitizeFileName(String fileName) {
    // Remove invalid characters and limit length
    String sanitized = fileName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }
    
    if (sanitized.isEmpty) {
      sanitized = 'note_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return sanitized;
  }
}
