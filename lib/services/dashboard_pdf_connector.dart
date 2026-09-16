import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/emotion_report_data.dart';
import '../screens/pdf_report_preview_screen.dart';
import 'chat_service.dart';
import 'emotion_service.dart';

/// จุดเชื่อมสำหรับสร้างรายงาน PDF
/// ดึงข้อมูลอารมณ์ 3 ช่วง → ส่งให้ Report AI → เปิด PDF
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
  }) async {
    if (_opening) return;

    _opening = true;

    try {
      final service = EmotionService();

      // ============================================================
      // 1. ดึงข้อมูลอารมณ์ทั้ง 3 ช่วง
      // ============================================================

      const phases = {
        'before_class': 'ก่อนเรียน',
        'during_class': 'ระหว่างเรียน',
        'after_class': 'หลังเรียน',
      };

      final periods = await Future.wait(
        phases.entries.map(
          (phase) async {
            final records = await service.getEmotionRecordsByDate(
              subjectCode: subjectCode,
              date: selectedDate,
              type: phase.key,
            );

            final counts = <String, int>{};

            for (final record in records) {
              final raw = record['counter'] ?? 1;

              final number =
                  raw is num ? raw : num.tryParse(raw.toString());

              if (number == null ||
                  !number.isFinite ||
                  number < 0 ||
                  number != number.truncateToDouble()) {
                throw FormatException(
                  'counter ไม่ถูกต้องในช่วง ${phase.value}',
                );
              }

              final name =
                  (record['emotion'] ?? record['emotion_name'])
                      ?.toString()
                      .trim();

              final emotion =
                  name == null || name.isEmpty
                      ? 'ไม่ระบุอารมณ์'
                      : name;

              counts[emotion] =
                  (counts[emotion] ?? 0) + number.toInt();
            }

            return EmotionPeriodData(
              type: phase.key,
              label: phase.value,
              counts: counts,
            );
          },
        ),
      );

      // ============================================================
      // 2. สร้างวันที่ของรายงาน
      // ============================================================

      final dateKey =
          '${selectedDate.year}-'
          '${_two(selectedDate.month)}-'
          '${_two(selectedDate.day)}';

      // ============================================================
      // 3. สร้าง Report
      // ============================================================

      var report = EmotionReportData(
        reportId:
            'ET-$dateKey-'
            '${subjectCode.replaceAll(RegExp(r"[^A-Za-z0-9]"), "")}',
        subjectName: subjectName,
        subjectCode: subjectCode,
        academicYear: academicYear,
        semester: semester,
        dateKey: dateKey,
        instructorName: instructorName,
        periods: periods,
        generatedAt: DateTime.now(),
      );

      // ============================================================
      // 4. สร้าง snapshotKey
      // ============================================================

      final snapshotKey = jsonEncode({
        'subjectCode': subjectCode,
        'date': dateKey,
        'periods': {
          for (final period in periods)
            period.type: {
              for (final key in (period.counts.keys.toList()..sort()))
                key: period.counts[key],
            },
        },
      });

      // ============================================================
      // 5. เตรียมข้อมูลอารมณ์สำหรับส่งให้ Report AI
      // ============================================================

      final emotionData = {
        'subjectCode': subjectCode,
        'date': dateKey,
        'periods': {
          for (final period in periods)
            period.type: {
              'label': period.label,
              'total': period.total,
              'counts': period.counts,
            },
        },
      };

      // ============================================================
      // 6. เรียก Report AI
      // ============================================================

      try {
        final chatService = ChatService();

        final aiReply = await chatService.sendMessage(
          message:
              'วิเคราะห์ข้อมูลอารมณ์ทั้ง 3 ช่วง '
              'และสร้างคำแนะนำสำหรับรายงานตามรูปแบบ JSON',
          emotionData: emotionData,
          subjectCode: subjectCode,
          reportAnalysis: true,
        );

        // ==========================================================
        // 7. แปลง JSON ที่ AI ส่งกลับมา
        // ==========================================================

        final advice = _parseAiAdvice(
          aiReply,
          snapshotKey,
        );

        if (advice != null) {
          report = report.withAdvice(advice);
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'โหลดคำแนะนำ AI ไม่สำเร็จ รายงานจะแสดงเฉพาะข้อมูลอารมณ์',
              ),
            ),
          );
        }
      }

      // ============================================================
      // 8. เปิดหน้า PDF
      // ============================================================

      if (!context.mounted) return;

      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PdfReportPreviewScreen(
            report: report,
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'สร้างรายงานไม่สำเร็จ: $error',
            ),
          ),
        );
      }
    } finally {
      _opening = false;
    }
  }

  // ================================================================
  // แปลง JSON จาก AI → ReportAiAdvice
  // ================================================================

  static ReportAiAdvice? _parseAiAdvice(
    String aiReply,
    String snapshotKey,
  ) {
    try {
      var text = aiReply.trim();

      // ------------------------------------------------------------
      // เผื่อ AI ส่ง ```json ... ```
      // ------------------------------------------------------------

      if (text.startsWith('```')) {
        text = text.replaceFirst(
          RegExp(r'^```(?:json)?\s*'),
          '',
        );

        text = text.replaceFirst(
          RegExp(r'\s*```$'),
          '',
        );
      }

      text = text.trim();

      // ------------------------------------------------------------
      // แปลง JSON
      // ------------------------------------------------------------

      final decoded = jsonDecode(text);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'รูปแบบผล AI ไม่ใช่ JSON object',
        );
      }

      final technique =
          decoded['technique']?.toString().trim() ?? '';

      final reason =
          decoded['reason']?.toString().trim() ?? '';

      if (technique.isEmpty || reason.isEmpty) {
        throw const FormatException(
          'ผล AI ไม่มี technique หรือ reason',
        );
      }

      // ------------------------------------------------------------
      // อ่าน actions
      // ------------------------------------------------------------

      final actions = <TeachingAction>[];

      final rawActions = decoded['actions'];

      if (rawActions is List) {
        for (final item in rawActions) {
          if (item is! Map) continue;

          final phase =
              item['phase']?.toString().trim() ?? '';

          final action =
              item['action']?.toString().trim() ?? '';

          if (phase.isEmpty || action.isEmpty) {
            continue;
          }

          actions.add(
            TeachingAction(
              phase: phase,
              action: action,
            ),
          );
        }
      }

      // ------------------------------------------------------------
      // สร้างผล AI
      // ------------------------------------------------------------

      return ReportAiAdvice(
        snapshotKey: snapshotKey,
        technique: technique,
        reason: reason,
        actions: actions,
      );
    } catch (error) {
      debugPrint(
        'Report AI JSON parse error: $error',
      );

      debugPrint(
        'AI Reply: $aiReply',
      );

      return null;
    }
  }

  static String _two(int value) {
    return value.toString().padLeft(2, '0');
  }
}