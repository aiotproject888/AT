import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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
    required String sessionId,
    String instructorName = '',
  }) async {
    if (_opening) return;

    _opening = true;

    try {
      final service = EmotionService();

      // ============================================================
      // 1. ดึงข้อมูล Session เพื่อใช้ระบุวันที่และเวลา
      // ============================================================

      DateTime? sessionStartTime;
      DateTime? sessionEndTime;

      final sessionSnapshot = await FirebaseFirestore.instance
          .collection('class_sessions')
          .doc(sessionId)
          .get();

      if (sessionSnapshot.exists) {
        final sessionData = sessionSnapshot.data();

        final startTimestamp = sessionData?['startTime'];
        final endTimestamp = sessionData?['endTime'];

        if (startTimestamp is Timestamp) {
          sessionStartTime = startTimestamp.toDate();
        }

        if (endTimestamp is Timestamp) {
          sessionEndTime = endTimestamp.toDate();
        }
      }

      // ============================================================
      // 2. ดึงข้อมูลอารมณ์ทั้ง 3 ช่วงของ Session เดียวกัน
      // ============================================================

      const phases = {
        'before_class': 'ก่อนเรียน',
        'during_class': 'ระหว่างเรียน',
        'after_class': 'หลังเรียน',
      };

      final periods = await Future.wait(
        phases.entries.map((phase) async {
          final records = await service.getEmotionRecordsBySession(
            subjectCode: subjectCode,
            sessionId: sessionId,
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

            final emotion = name == null || name.isEmpty
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
        }),
      );

      // ============================================================
      // 3. สร้างวันที่ของรายงาน
      // ============================================================

      final dateKey =
          '${selectedDate.year}-'
          '${_two(selectedDate.month)}-'
          '${_two(selectedDate.day)}';

      // ============================================================
      // 4. สร้าง Report
      // ============================================================

      var report = EmotionReportData(
        reportId:
            'ET-$dateKey-'
            '${subjectCode.replaceAll(RegExp(r"[^A-Za-z0-9]"), "")}-'
            '${sessionId.substring(0, sessionId.length > 8 ? 8 : sessionId.length)}',
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
      // 5. สร้าง snapshotKey
      // ============================================================

      final snapshotKey = jsonEncode({
        'subjectCode': subjectCode,
        'sessionId': sessionId,
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
      // 6. เตรียมข้อมูลอารมณ์สำหรับส่งให้ Report AI
      // ============================================================

      final emotionData = {
        'subjectCode': subjectCode,
        'sessionId': sessionId,
        'date': dateKey,

        // เวลาเริ่มและสิ้นสุดของ Session
        'startTime': sessionStartTime?.toIso8601String(),
        'endTime': sessionEndTime?.toIso8601String(),

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
      // 7. เรียก Report AI
      // ============================================================

      try {
        final chatService = ChatService();

        final aiReply = await chatService.sendMessage(
          message: '''
วิเคราะห์ข้อมูลอารมณ์ของผู้เรียนทั้ง 3 ช่วง ได้แก่ ก่อนเรียน ระหว่างเรียน และหลังเรียน
แล้วสร้างคำแนะนำสำหรับอาจารย์ผู้สอนในรูปแบบ JSON ตามโครงสร้างที่กำหนด

คำแนะนำต้อง:
- อ้างอิงจากข้อมูลอารมณ์ที่ได้รับจริง
- เน้นแนวทางที่สามารถนำไปใช้ในการจัดการเรียนการสอนได้จริง
- หากเป็นรายวิชาด้านคอมพิวเตอร์ เทคโนโลยี หรือการเขียนโปรแกรม
  ให้เน้นวิธีสอนที่เกี่ยวข้องกับการปฏิบัติ การเขียนโค้ด การแก้โจทย์
  การสาธิต การแบ่งโจทย์เป็นขั้นตอน การทำงานเป็นคู่/กลุ่ม
  การทบทวนพื้นฐาน และการให้ Feedback
- ไม่ควรแนะนำ "Ice Breaker" หรือกิจกรรมละลายพฤติกรรมเป็นคำแนะนำหลัก
  เว้นแต่ข้อมูลอารมณ์และบริบทจะสนับสนุนอย่างชัดเจน
- หลีกเลี่ยงคำแนะนำทั่วไปที่ไม่เกี่ยวข้องกับลักษณะการเรียน
- ไม่สร้างข้อมูลจำนวนผู้เรียนหรืออารมณ์ที่ไม่มีอยู่ในข้อมูล
- ใช้ภาษาไทยเป็นหลัก
- คำแนะนำควรสั้น กระชับ และนำไปปฏิบัติได้

สร้างผลลัพธ์เป็น JSON เท่านั้น
''',
          emotionData: emotionData,
          subjectCode: subjectCode,
          reportAnalysis: true,
        );

        // ==========================================================
        // 8. แปลง JSON ที่ AI ส่งกลับมา
        // ==========================================================

        final advice = _parseAiAdvice(aiReply, snapshotKey);

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
      // 9. เปิดหน้า PDF
      // ============================================================

      if (!context.mounted) return;

      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PdfReportPreviewScreen(report: report),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('สร้างรายงานไม่สำเร็จ: $error'),
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