import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// Removed external test-only dependencies (optional/uuid) to simplify example tests

import 'test_doc_info.dart';

class PdfTestUtils {
  final String testDirectoryPath;

  PdfTestUtils(this.testDirectoryPath);

  /// Creates a basic, single or multipage pdf document with optional info and
  /// saves it to a File that is subsequently returned wrapped in a Future
  Future<File> createPdfFile(List<List<String>> pages,
      {TestDocInfo? info}) async {
    final pdf = info != null
      ? pw.Document(
        title: info.title,
        author: info.author,
        creator: info.creator,
        subject: info.subject,
        keywords: info.keywords)
      : pw.Document();

    final pdfPages = pages
        .map((page) => pw.MultiPage(

            /// a3 format so long lines will hopefully not be broken
            pageFormat: PdfPageFormat.a3,
            build: (pw.Context context) =>
                page.map((line) => pw.Paragraph(text: line)).toList()))
        .toList();
    for (var page in pdfPages) {
      pdf.addPage(page);
    }

    String testFile = join(testDirectoryPath, "${DateTime.now().microsecondsSinceEpoch}.pdf");
    final file = File(testFile);

    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

bool get isIos => defaultTargetPlatform == TargetPlatform.iOS;

/// A trick to wait till all awaits defined inside tester function get their
/// results so the checks are finished. (avoiding awkward expectAsync calls)
Future<void> forEach<T>(List<T> docs, Future<void> Function(T e) tester) =>
    Future.wait(docs.map((e) => tester(e)));
