import 'package:flutter/material.dart';

import '../models/emotion_report_data.dart';
import '../screens/pdf_report_preview_screen.dart';

/// Converts the data already loaded by SubjectDashboard into the A4 report.
class DashboardPdfConnector {
  DashboardPdfConnector._();

  static Future<void> open({
    required BuildContext context,
    required String subjectName,
    required String subjectCode,
    required String academicYear,
    required String semester,
    required DateTime selectedDate,
    required int beforeRespondents,
    required int afterRespondents,
    required int beforePositivePercent,
    required int afterPositivePercent,
    required Map<String, int> beforeDistribution,
    required Map<String, int> afterDistribution,
    String instructorName = 'ไม่ระบุ',
  }) async {
    final beforeSlices = _toSlices(beforeDistribution);
    final afterSlices = _toSlices(afterDistribution);

    final report = EmotionReportData(
      reportId: _reportId(subjectCode, selectedDate),
      subjectName: subjectName,
      subjectCode: subjectCode,
      academicYear: academicYear,
      semester: semester,
      instructorName: instructorName,
      sessionDate: _formatThaiDate(selectedDate),
      sessionTime: '-',
      lessonTopic: 'สรุปภาพรวมอารมณ์ผู้เรียน',
      beforeRespondents: beforeRespondents,
      afterRespondents: afterRespondents,
      beforeEmotionDistribution: beforeSlices,
      afterEmotionDistribution: afterSlices,
      beforePositivePercent: beforePositivePercent.toDouble(),
      afterPositivePercent: afterPositivePercent.toDouble(),
      dominantEmotion: _dominantEmotion(afterSlices, beforeSlices),
      alertLevel: _alertLevel(afterRespondents, afterPositivePercent),
      analysisSummary: _analysisSummary(
        beforeRespondents: beforeRespondents,
        afterRespondents: afterRespondents,
        beforePositivePercent: beforePositivePercent,
        afterPositivePercent: afterPositivePercent,
        afterSlices: afterSlices,
      ),
      recommendedTechnique: _recommendedTechnique(
        afterRespondents,
        afterPositivePercent,
      ),
      recommendationReason: _recommendationReason(
        afterRespondents,
        afterPositivePercent,
      ),
      recommendationPriority: _recommendationPriority(
        afterRespondents,
        afterPositivePercent,
      ),
      teachingActions: _teachingActions(afterPositivePercent),
      generatedAt: _formatGeneratedAt(DateTime.now()),
    );

    if (!context.mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PdfReportPreviewScreen(report: report),
      ),
    );
  }

  static List<EmotionSlice> _toSlices(Map<String, int> distribution) {
    final total = distribution.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return const [];

    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(4).map((entry) {
      return EmotionSlice(
        name: _displayEmotion(entry.key),
        percent: entry.value * 100 / total,
        colorHex: _emotionColor(entry.key),
      );
    }).toList(growable: false);
  }

  static String _dominantEmotion(
    List<EmotionSlice> after,
    List<EmotionSlice> before,
  ) {
    if (after.isNotEmpty) return after.first.name;
    if (before.isNotEmpty) return before.first.name;
    return 'ยังไม่มีข้อมูล';
  }

  static String _analysisSummary({
    required int beforeRespondents,
    required int afterRespondents,
    required int beforePositivePercent,
    required int afterPositivePercent,
    required List<EmotionSlice> afterSlices,
  }) {
    if (beforeRespondents == 0 && afterRespondents == 0) {
      return 'ยังไม่มีข้อมูลอารมณ์ของผู้เรียนในวันที่เลือก จึงยังไม่สามารถเปรียบเทียบผลก่อนเรียนและหลังเรียนได้';
    }
    if (beforeRespondents == 0) {
      return 'มีข้อมูลหลังเรียน $afterRespondents คน แต่ยังไม่มีข้อมูลก่อนเรียน จึงยังไม่สามารถสรุปการเปลี่ยนแปลงของอารมณ์ได้';
    }
    if (afterRespondents == 0) {
      return 'มีข้อมูลก่อนเรียน $beforeRespondents คน และกำลังรอข้อมูลหลังเรียนเพื่อเปรียบเทียบการเปลี่ยนแปลงของอารมณ์ผู้เรียน';
    }

    final change = afterPositivePercent - beforePositivePercent;
    final direction = change > 0
        ? 'เพิ่มขึ้น $change จุด'
        : change < 0
            ? 'ลดลง ${change.abs()} จุด'
            : 'ไม่เปลี่ยนแปลง';
    final dominant = afterSlices.isEmpty ? 'ไม่พบข้อมูล' : afterSlices.first.name;

    return 'หลังเรียน อารมณ์เชิงบวก$direction จาก $beforePositivePercent% เป็น '
        '$afterPositivePercent% โดยอารมณ์หลักหลังเรียนคือ $dominant';
  }

  static String _recommendedTechnique(int respondents, int positivePercent) {
    if (respondents == 0) return 'รอข้อมูลหลังเรียนก่อนวิเคราะห์';
    if (positivePercent < 40) return 'ทบทวนเนื้อหา + ตรวจสอบความเข้าใจ';
    if (positivePercent < 70) return 'Exit Ticket + ทบทวนจุดที่ยังสับสน';
    return 'คงรูปแบบกิจกรรม + Exit Ticket';
  }

  static String _recommendationReason(int respondents, int positivePercent) {
    if (respondents == 0) {
      return 'ควรรอให้ผู้เรียนบันทึกอารมณ์หลังเรียนก่อน เพื่อให้คำแนะนำอ้างอิงจากข้อมูลที่ครบถ้วน';
    }
    if (positivePercent < 40) {
      return 'อารมณ์เชิงบวกหลังเรียนยังอยู่ในระดับต่ำ ควรลดความซับซ้อนของเนื้อหา เพิ่มตัวอย่าง และหยุดตรวจสอบความเข้าใจเป็นระยะ';
    }
    if (positivePercent < 70) {
      return 'ควรใช้คำถามสั้นท้ายคาบเพื่อยืนยันความเข้าใจ และนำประเด็นที่ผู้เรียนยังสับสนไปทบทวนในครั้งถัดไป';
    }
    return 'ภาพรวมหลังเรียนเป็นบวก ควรรักษารูปแบบกิจกรรมเดิม พร้อมใช้คำถามสั้นท้ายคาบเพื่อตรวจสอบความเข้าใจ';
  }

  static String _recommendationPriority(int respondents, int positivePercent) {
    if (respondents == 0) return 'รอข้อมูล';
    if (positivePercent < 40) return 'สูง';
    if (positivePercent < 70) return 'ปานกลาง';
    return 'ต่ำ';
  }

  static String _alertLevel(int respondents, int positivePercent) {
    if (respondents == 0) return 'รอข้อมูล';
    if (positivePercent < 40) return 'ควรติดตาม';
    return 'ปกติ';
  }

  static List<TeachingAction> _teachingActions(int afterPositivePercent) {
    return [
      const TeachingAction(
        phase: 'ก่อนเรียน',
        action: 'ใช้คำถามนำสั้น ๆ เพื่อสำรวจความรู้เดิมและอารมณ์ก่อนเริ่มบทเรียน',
      ),
      const TeachingAction(
        phase: 'หลังเรียน',
        action: 'ใช้ Exit Ticket 1 ข้อ เพื่อตรวจสอบความเข้าใจและอารมณ์หลังเรียน',
      ),
      TeachingAction(
        phase: 'ครั้งถัดไป',
        action: afterPositivePercent < 70
            ? 'ทบทวนหัวข้อที่ผู้เรียนยังสับสนก่อนเข้าสู่เนื้อหาใหม่'
            : 'รักษารูปแบบกิจกรรมที่ได้ผลและเพิ่มคำถามเพื่อต่อยอดการเรียนรู้',
      ),
    ];
  }

  static String _displayEmotion(String emotion) {
    const labels = {
      'รู้สึกสนใจ': 'สนใจ',
      'รู้สึกตื่นเต้น': 'ตื่นเต้น',
      'รู้สึกสนุกสนาน': 'สนุก',
      'รู้สึกวิตกกังวล': 'กังวล',
      'รู้สึกเครียด': 'เครียด',
      'รู้สึกเบื่อหน่าย': 'เบื่อ',
      'รู้สึกกลัว': 'กลัว',
    };
    return labels[emotion] ?? emotion.replaceFirst('รู้สึก', '');
  }

  static String _emotionColor(String emotion) {
    const colors = {
      'รู้สึกสนใจ': '#2EB67D',
      'รู้สึกตื่นเต้น': '#22B8CF',
      'รู้สึกสนุกสนาน': '#6C52E5',
      'รู้สึกวิตกกังวล': '#4E8BE8',
      'รู้สึกเครียด': '#E65C5C',
      'รู้สึกเบื่อหน่าย': '#A7A9B7',
      'รู้สึกกลัว': '#F28C45',
    };
    return colors[emotion] ?? '#8A7CE0';
  }

  static String _reportId(String subjectCode, DateTime date) {
    final code = subjectCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return 'ET-${date.year + 543}${_two(date.month)}${_two(date.day)}-$code';
  }

  static String _formatThaiDate(DateTime date) {
    const months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  static String _formatGeneratedAt(DateTime date) {
    return '${_formatThaiDate(date)} เวลา ${_two(date.hour)}:${_two(date.minute)} น.';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
