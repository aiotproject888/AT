import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/emotion_report_data.dart';
import '../services/emotion_pdf_report_service.dart';

class PdfReportPreviewScreen extends StatelessWidget {
  final EmotionReportData report;

  const PdfReportPreviewScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0D18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1233),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'รายงานผลการวิเคราะห์',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: PdfPreview(
        initialPageFormat: PdfPageFormat.a4,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'emotiteach_${report.reportId}.pdf',
        build: (_) => EmotionPdfReportService.generate(report),
      ),
    );
  }
}