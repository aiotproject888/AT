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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0E0D18),

        appBar: AppBar(
          backgroundColor: const Color(0xFF33265F),
          foregroundColor: Colors.white,
          title: const Text('รายงานอารมณ์ผู้เรียน'),
        ),

        body: PdfPreview.builder(
          initialPageFormat: PdfPageFormat.a4,

          canChangeOrientation: false,
          canChangePageFormat: false,

          allowPrinting: true,
          allowSharing: true,

          pdfFileName: 'emotiteach_${report.reportId}.pdf',

          build: (_) => EmotionPdfReportService.generate(report),

          pagesBuilder: (context, pages) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 5.0,

                  // ถ่าง 2 นิ้วได้ทันที
                  scaleEnabled: true,

                  // ตอนซูมแล้วลากดูส่วนต่าง ๆ ได้
                  panEnabled: true,

                  constrained: false,

                  boundaryMargin: const EdgeInsets.all(100),

                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final page in pages)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            child: AspectRatio(
                              aspectRatio: page.aspectRatio,
                              child: Image(
                                image: page.image,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}