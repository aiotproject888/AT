import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/emotion_report_data.dart';
import '../screens/pdf_report_preview_screen.dart';
import 'emotion_service.dart';

/// จุดเชื่อมของเพื่อน: รับข้อมูลจริงครบ 3 ช่วง แล้วคืนผล AI หรือ null
typedef ReportAiLoader = Future<ReportAiAdvice?> Function(
  EmotionReportData report, String snapshotKey,
);

class DashboardPdfConnector {
  DashboardPdfConnector._();
  static bool _opening = false;

  static Future<void> open({
    required BuildContext context,
    required String subjectName,
    required String subjectCode,
    required String academicYear,
    required String semester,
    required DateTime selectedDate,
    String instructorName = '',
    ReportAiLoader? aiLoader,
    // รองรับปุ่ม PDF เดิมระหว่างย้ายโค้ด ค่าต่อไปนี้ไม่ใช้สร้างรายงาน
    int? beforeRespondents,
    int? afterRespondents,
    int? beforePositivePercent,
    int? afterPositivePercent,
    Map<String, int>? beforeDistribution,
    Map<String, int>? afterDistribution,
  }) async {
    if (_opening) return;
    _opening = true;
    try {
      final service = EmotionService();
      const phases = {
        'before_class': 'ก่อนเรียน',
        'during_class': 'ระหว่างเรียน',
        'after_class': 'หลังเรียน',
      };
      final periods = await Future.wait(phases.entries.map((phase) async {
        final records = await service.getEmotionRecordsByDate(
          subjectCode: subjectCode, date: selectedDate, type: phase.key,
        );
        final counts = <String, int>{};
        for (final record in records) {
          final raw = record['counter'] ?? 1;
          final number = raw is num ? raw : num.tryParse(raw.toString());
          if (number == null || !number.isFinite || number < 0 ||
              number != number.truncateToDouble()) {
            throw FormatException('counter ไม่ถูกต้องในช่วง ${phase.value}');
          }
          final name = (record['emotion'] ?? record['emotion_name'])
              ?.toString().trim();
          final emotion = name == null || name.isEmpty ? 'ไม่ระบุอารมณ์' : name;
          counts[emotion] = (counts[emotion] ?? 0) + number.toInt();
        }
        return EmotionPeriodData(type: phase.key, label: phase.value, counts: counts);
      }));
      final dateKey = '${selectedDate.year}-${_two(selectedDate.month)}-${_two(selectedDate.day)}';
      var report = EmotionReportData(
        reportId: 'ET-$dateKey-${subjectCode.replaceAll(RegExp(r"[^A-Za-z0-9]"), "")}',
        subjectName: subjectName, subjectCode: subjectCode,
        academicYear: academicYear, semester: semester, dateKey: dateKey,
        instructorName: instructorName, periods: periods,
        generatedAt: DateTime.now(),
      );
      // TODO(AI): ส่ง aiLoader จากปุ่ม PDF; ห้ามใส่ข้อความตัวอย่างแทนผลจริง
      // snapshotKey ผูกผลกับวิชา วันที่ และยอดแต่ละอารมณ์ ณ ตอนส่ง AI
      final snapshotKey = jsonEncode({
        'subjectCode': subjectCode,
        'date': dateKey,
        'periods': {for (final p in periods) p.type: {
          for (final key in (p.counts.keys.toList()..sort())) key: p.counts[key],
        }},
      });
      if (aiLoader != null) {
        try {
          final advice = await aiLoader(report, snapshotKey);
          if (advice != null) {
            if (advice.snapshotKey != snapshotKey ||
                advice.technique.trim().isEmpty || advice.reason.trim().isEmpty) {
              throw StateError('ผล AI ไม่ตรงกับข้อมูลหรือข้อมูลไม่ครบ');
            }
            report = report.withAdvice(advice);
          }
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('โหลดคำแนะนำ AI ไม่สำเร็จ รายงานจะแสดงเฉพาะข้อมูลอารมณ์')),
            );
          }
        }
      }
      if (!context.mounted) return;
      await Navigator.push<void>(context, MaterialPageRoute<void>(
        builder: (_) => PdfReportPreviewScreen(report: report),
      ));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('สร้างรายงานไม่สำเร็จ: $error')),
        );
      }
    } finally {
      _opening = false;
    }
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
