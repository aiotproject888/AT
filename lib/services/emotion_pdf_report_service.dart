import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/emotion_report_data.dart';

class EmotionPdfReportService {
  EmotionPdfReportService._();

  // ============================================================
  // Colors
  // ============================================================

  static final PdfColor _purple = _hex('#6C52E5');
  static final PdfColor _darkPurple = _hex('#33265F');
  static final PdfColor _ink = _hex('#1F2030');
  static final PdfColor _muted = _hex('#676A7B');
  static final PdfColor _line = _hex('#E3E4EC');
  static final PdfColor _panel = _hex('#F6F5FB');
  static final PdfColor _lightPurple = _hex('#F1EEFF');

  static final PdfColor _green = _hex('#2EB67D');
  static final PdfColor _orange = _hex('#F28C45');
  static final PdfColor _blue = _hex('#4E8BE8');

  static final PdfColor _positive = _hex('#2EB67D');
  static final PdfColor _negative = _hex('#E65C5C');
  static final PdfColor _neutral = _hex('#A7A9B7');

  // ============================================================
  // Generate PDF
  // ============================================================

  static Future<Uint8List> generate(EmotionReportData data) async {
    final regular = await PdfGoogleFonts.sarabunRegular();
    final bold = await PdfGoogleFonts.sarabunBold();

    final document = pw.Document(
      title: 'รายงานอารมณ์ผู้เรียน',
      author: 'EmotiTeach',
      subject: data.subjectName,
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(30, 22, 30, 20),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (_) => pw.Container(
          width: double.infinity,
          height: double.infinity,
          color: PdfColors.white,
          child: _buildReport(data),
        ),
      ),
    );

    return document.save();
  }

  // ============================================================
  // Main Report
  // ============================================================

  static pw.Widget _buildReport(EmotionReportData data) {
    final before = _period(data, 'before_class', 'ก่อนเรียน');

    final during = _period(data, 'during_class', 'ระหว่างเรียน');

    final after = _period(data, 'after_class', 'หลังเรียน');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // --------------------------------------------------------
        // Header
        // --------------------------------------------------------
        _header(),

        pw.SizedBox(height: 7),

        // --------------------------------------------------------
        // Subject information
        // --------------------------------------------------------
        _subjectInfo(data),

        pw.SizedBox(height: 7),

        // --------------------------------------------------------
        // Overview
        // --------------------------------------------------------
        _sectionTitle('ภาพรวมอารมณ์ผู้เรียน'),

        pw.SizedBox(height: 4),

        _responseSummary(before: before, during: during, after: after),

        pw.SizedBox(height: 5),

        _emotionScoreChart(before: before, during: during, after: after),

        pw.SizedBox(height: 7),

        // --------------------------------------------------------
        // Emotion comparison table
        // --------------------------------------------------------
        _sectionTitle('การเปลี่ยนแปลงอารมณ์'),

        pw.SizedBox(height: 4),

        _emotionComparisonTable(before: before, during: during, after: after),

        pw.SizedBox(height: 6),

        // --------------------------------------------------------
        // Watch points
        // --------------------------------------------------------
        _sectionTitle('จุดที่ควรเฝ้าระวัง'),

        pw.SizedBox(height: 4),

        _watchPoints(before: before, during: during, after: after),

        pw.SizedBox(height: 6),

        // --------------------------------------------------------
        // AI Recommendation
        // --------------------------------------------------------
        _sectionTitle('การวิเคราะห์และคำแนะนำจาก AI'),

        pw.SizedBox(height: 4),

        _aiRecommendation(data.aiAdvice),

        if (data.aiAdvice?.actions.isNotEmpty == true) ...[
          pw.SizedBox(height: 4),
          _aiActions(data.aiAdvice!.actions),
        ],

        pw.Spacer(),

        // --------------------------------------------------------
        // Note
        // --------------------------------------------------------
        pw.Text(
          'ข้อมูลนี้ใช้ประกอบการวางแผนการสอน ผู้ตอบแต่ละช่วงอาจเป็นคนละกลุ่ม '
          'และการกดซ้ำอาจทำให้คนเดิมถูกนับมากกว่าหนึ่งครั้ง',
          style: pw.TextStyle(fontSize: 6.2, color: _muted),
        ),

        pw.SizedBox(height: 4),

        _footer(data),
      ],
    );
  }

  // ============================================================
  // Header
  // ============================================================

  static pw.Widget _header() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: pw.BoxDecoration(
        color: _darkPurple,
        borderRadius: pw.BorderRadius.circular(9),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 34,
            height: 34,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: _purple,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              'ET',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(width: 9),

          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'EmotiTeach',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'รายงานอารมณ์ผู้เรียน',
                  style: pw.TextStyle(color: _hex('#D9D3FF'), fontSize: 7.5),
                ),
              ],
            ),
          ),

          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _hex('#493B7A'),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Text(
              'ก่อนเรียน / ระหว่างเรียน / หลังเรียน',
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 6.5),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Subject Info
  // ============================================================

  static pw.Widget _subjectInfo(EmotionReportData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _infoItem('รายวิชา', data.subjectName, flex: 2),
          _infoItem('รหัสวิชา', data.subjectCode),
          _infoItem('ปีการศึกษา', data.academicYear),
          _infoItem('ภาคเรียน', data.semester),
          _infoItem('วันที่', data.dateKey, flex: 2),
        ],
      ),
    );
  }

  static pw.Widget _infoItem(String title, String value, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _smallLabel(title),
          pw.SizedBox(height: 1.5),
          pw.Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 7.6,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Response Summary
  // ============================================================

  static pw.Widget _responseSummary({
    required EmotionPeriodData before,
    required EmotionPeriodData during,
    required EmotionPeriodData after,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _responseCard(
            label: 'ก่อนเรียน',
            count: before.total,
            color: _blue,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: _responseCard(
            label: 'ระหว่างเรียน',
            count: during.total,
            color: _orange,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: _responseCard(
            label: 'หลังเรียน',
            count: after.total,
            color: _green,
          ),
        ),
      ],
    );
  }

  static pw.Widget _responseCard({
    required String label,
    required int count,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(7),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 7,
            height: 7,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 6.5, color: _muted),
            ),
          ),
          pw.Text(
            '$count คน',
            style: pw.TextStyle(
              fontSize: 7.2,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Emotion Score Chart
  // ============================================================

  static pw.Widget _emotionScoreChart({
    required EmotionPeriodData before,
    required EmotionPeriodData during,
    required EmotionPeriodData after,
  }) {
    final beforeScore = _calculateEmotionScore(before.counts);
    final duringScore = _calculateEmotionScore(during.counts);
    final afterScore = _calculateEmotionScore(after.counts);

    final hasBefore = before.hasResponses;
    final hasDuring = during.hasResponses;
    final hasAfter = after.hasResponses;

    return pw.Container(
      width: double.infinity,
      height: 132,
      padding: const pw.EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'แนวโน้มคะแนนอารมณ์',
                style: pw.TextStyle(
                  fontSize: 7,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
            ],
          ),

          pw.SizedBox(height: 5),

          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ------------------------------------------------
                // Y Axis
                // ------------------------------------------------
                pw.SizedBox(width: 4),

                // ------------------------------------------------
                // Chart
                // ------------------------------------------------
                pw.Expanded(
                  child: _scoreChartArea(
                    beforeScore: beforeScore,
                    duringScore: duringScore,
                    afterScore: afterScore,
                    hasBefore: hasBefore,
                    hasDuring: hasDuring,
                    hasAfter: hasAfter,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _scoreChartArea({
    required double beforeScore,
    required double duringScore,
    required double afterScore,
    required bool hasBefore,
    required bool hasDuring,
    required bool hasAfter,
  }) {
    return pw.Column(
      children: [
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // แกน Y
              pw.Container(
                width: 38,
                padding: const pw.EdgeInsets.only(right: 5),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'ดีมาก',
                      style: pw.TextStyle(
                        fontSize: 6.5,
                        color: _green,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'กลาง',
                      style: pw.TextStyle(
                        fontSize: 6.5,
                        color: _muted,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'แย่มาก',
                      style: pw.TextStyle(
                        fontSize: 6.5,
                        color: _negative,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // พื้นที่กราฟ
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    // เส้นระดับ ดีมาก / กลาง / แย่มาก
                    pw.Positioned.fill(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Container(height: 0.6, color: _line),
                          pw.Container(height: 0.8, color: _line),
                          pw.Container(height: 0.6, color: _line),
                        ],
                      ),
                    ),

                    // แท่งกราฟ
                    pw.Positioned.fill(
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          _scoreBar(
                            score: beforeScore,
                            hasData: hasBefore,
                            color: _blue,
                          ),
                          _scoreBar(
                            score: duringScore,
                            hasData: hasDuring,
                            color: _orange,
                          ),
                          _scoreBar(
                            score: afterScore,
                            hasData: hasAfter,
                            color: _green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 5),

        pw.Row(
          children: [
            pw.SizedBox(width: 38),
            _chartBottomLabel('ก่อนเรียน'),
            _chartBottomLabel('ระหว่างเรียน'),
            _chartBottomLabel('หลังเรียน'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _scoreBar({
    required double score,
    required bool hasData,
    required PdfColor color,
  }) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10),
        child: pw.Stack(
          children: [
            if (hasData)
              pw.Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: pw.Container(
                  height: ((score + 1) / 2) * 100,
                  decoration: pw.BoxDecoration(
                    color: color,
                    borderRadius: const pw.BorderRadius.vertical(
                      top: pw.Radius.circular(4),
                    ),
                  ),
                ),
              ),

            if (!hasData)
              pw.Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: pw.Container(height: 2, color: _line),
              ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _chartBottomLabel(String text) {
    return pw.Expanded(
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 6,
          color: _ink,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static double _calculateEmotionScore(Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return 0;
    }

    int positive = 0;
    int negative = 0;
    int total = 0;

    distribution.forEach((emotion, count) {
      total += count;

      if (emotion == 'รู้สึกสนใจ' ||
          emotion == 'รู้สึกตื่นเต้น' ||
          emotion == 'รู้สึกสนุกสนาน') {
        positive += count;
      } else if (emotion == 'รู้สึกวิตกกังวล' ||
          emotion == 'รู้สึกเครียด' ||
          emotion == 'รู้สึกเบื่อหน่าย' ||
          emotion == 'รู้สึกกลัว') {
        negative += count;
      }
    });

    if (total == 0) {
      return 0;
    }

    // คะแนนอยู่ระหว่าง -1 ถึง 1
    //
    // -1 = อารมณ์ด้านลบทั้งหมด
    //  0 = อารมณ์กลาง
    // +1 = อารมณ์ด้านบวกทั้งหมด
    return (positive - negative) / total;
  }

  // ============================================================
  // Emotion Comparison Table
  static pw.Widget _emotionComparisonTable({
    required EmotionPeriodData before,
    required EmotionPeriodData during,
    required EmotionPeriodData after,
  }) {
    const emotions = [
      'รู้สึกสนใจ',
      'รู้สึกตื่นเต้น',
      'รู้สึกสนุกสนาน',
      'รู้สึกวิตกกังวล',
      'รู้สึกเครียด',
      'รู้สึกเบื่อหน่าย',
      'รู้สึกกลัว',
      'รู้สึกเฉยๆ',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.4),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1.9),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _darkPurple),
          children: [
            _tableCell('อารมณ์', header: true),
            _tableCell('ก่อนเรียน', header: true, center: true),
            _tableCell('ระหว่างเรียน', header: true, center: true),
            _tableCell('หลังเรียน', header: true, center: true),
            _tableCell('แนวโน้ม', header: true, center: true),
          ],
        ),

        for (var index = 0; index < emotions.length; index++)
          _emotionTableRow(
            emotion: emotions[index],
            before: before,
            during: during,
            after: after,
            index: index,
          ),
      ],
    );
  }

  static pw.TableRow _emotionTableRow({
    required String emotion,
    required EmotionPeriodData before,
    required EmotionPeriodData during,
    required EmotionPeriodData after,
    required int index,
  }) {
    final beforeValue = before.counts[emotion] ?? 0;

    final duringValue = during.counts[emotion] ?? 0;

    final afterValue = after.counts[emotion] ?? 0;

    final trend = _trend(
      emotion: emotion,
      before: beforeValue,
      during: duringValue,
      after: afterValue,
      hasBefore: before.hasResponses,
      hasDuring: during.hasResponses,
      hasAfter: after.hasResponses,
    );

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: index.isEven ? PdfColors.white : _panel,
      ),
      children: [
        _tableCell(_displayEmotion(emotion), bold: true),
        _tableCell(before.hasResponses ? '$beforeValue' : '-', center: true),
        _tableCell(during.hasResponses ? '$duringValue' : '-', center: true),
        _tableCell(after.hasResponses ? '$afterValue' : '-', center: true),
        _trendCell(trend),
      ],
    );
  }

  // ============================================================
  // Trend
  // ============================================================

  static _TrendResult _trend({
    required String emotion,
    required int before,
    required int during,
    required int after,
    required bool hasBefore,
    required bool hasDuring,
    required bool hasAfter,
  }) {
    if (!hasBefore && !hasDuring && !hasAfter) {
      return const _TrendResult(text: 'ไม่มีข้อมูล', type: _TrendType.neutral);
    }

    final values = <int>[];

    if (hasBefore) {
      values.add(before);
    }

    if (hasDuring) {
      values.add(during);
    }

    if (hasAfter) {
      values.add(after);
    }

    if (values.length < 2) {
      return const _TrendResult(text: 'ข้อมูลไม่ครบ', type: _TrendType.neutral);
    }

    final first = values.first;
    final last = values.last;

    if (first == last) {
      return const _TrendResult(text: 'คงที่', type: _TrendType.neutral);
    }

    final isNegative = _negativeEmotions.contains(emotion);

    if (last > first) {
      if (isNegative) {
        return const _TrendResult(
          text: '↑ ควรเฝ้าระวัง',
          type: _TrendType.warning,
        );
      }

      return const _TrendResult(text: '↑ ดีขึ้น', type: _TrendType.good);
    }

    if (isNegative) {
      return const _TrendResult(text: '↓ ดีขึ้น', type: _TrendType.good);
    }

    return const _TrendResult(text: '↓ ลดลง', type: _TrendType.neutral);
  }

  static pw.Widget _trendCell(_TrendResult result) {
    PdfColor color;

    switch (result.type) {
      case _TrendType.good:
        color = _positive;
        break;

      case _TrendType.warning:
        color = _negative;
        break;

      case _TrendType.neutral:
        color = _muted;
        break;
    }

    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        result.text,
        maxLines: 1,
        style: pw.TextStyle(
          fontSize: 6.3,
          color: color,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // Watch Points
  // ============================================================

  static pw.Widget _watchPoints({
    required EmotionPeriodData before,
    required EmotionPeriodData during,
    required EmotionPeriodData after,
  }) {
    final points = <String>[];

    const watchedEmotions = [
      'รู้สึกวิตกกังวล',
      'รู้สึกเครียด',
      'รู้สึกเบื่อหน่าย',
      'รู้สึกกลัว',
    ];

    for (final emotion in watchedEmotions) {
      final beforeValue = before.counts[emotion] ?? 0;

      final duringValue = during.counts[emotion] ?? 0;

      final afterValue = after.counts[emotion] ?? 0;

      final hasData =
          before.hasResponses || during.hasResponses || after.hasResponses;

      if (!hasData) {
        continue;
      }

      final maxValue = [
        beforeValue,
        duringValue,
        afterValue,
      ].reduce((a, b) => a > b ? a : b);

      if (maxValue > 0) {
        final phase = _highestPhase(
          beforeValue,
          duringValue,
          afterValue,
          before,
          during,
          after,
        );

        points.add(
          '${_displayEmotion(emotion)} พบสูงสุดในช่วง$phase '
          '$maxValue คน',
        );
      }
    }

    if (points.isEmpty) {
      return _infoPanel(
        icon: '✓',
        title: 'ไม่พบอารมณ์เชิงลบที่มีจำนวนการตอบมากกว่า 0',
        color: _positive,
      );
    }

    return _infoPanel(
      icon: '!',
      title: 'ประเด็นที่พบจากข้อมูล',
      color: _orange,
      children: points,
    );
  }

  static String _highestPhase(
    int beforeValue,
    int duringValue,
    int afterValue,
    EmotionPeriodData before,
    EmotionPeriodData during,
    EmotionPeriodData after,
  ) {
    if (afterValue >= duringValue && afterValue >= beforeValue) {
      return after.label;
    }

    if (duringValue >= beforeValue) {
      return during.label;
    }

    return before.label;
  }

  static pw.Widget _infoPanel({
    required String icon,
    required String title,
    required PdfColor color,
    List<String> children = const [],
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(7),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 18,
            height: 18,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              icon,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(width: 7),

          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 7.3,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                if (children.isNotEmpty) ...[
                  pw.SizedBox(height: 2),

                  for (final child in children)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 1),
                      child: pw.Text(
                        '• $child',
                        maxLines: 1,
                        style: pw.TextStyle(fontSize: 6.4, color: _muted),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AI Recommendation
  // ============================================================

  static pw.Widget _aiRecommendation(ReportAiAdvice? advice) {
    if (advice == null) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
          color: _panel,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _line),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _aiIcon(),

            pw.SizedBox(width: 7),

            pw.Expanded(
              child: pw.Text(
                'ยังไม่มีคำแนะนำจาก AI สำหรับข้อมูลชุดนี้',
                style: pw.TextStyle(fontSize: 7.2, color: _muted),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: _lightPurple,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _hex('#DDD6FF')),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _aiIcon(),

          pw.SizedBox(width: 8),

          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'เทคนิคที่ควรเพิ่มหรือปรับ',
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: _muted,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 2),

                pw.Text(
                  _cleanPdfText(advice.technique),
                  maxLines: 3,
                  style: pw.TextStyle(
                    fontSize: 8.2,
                    color: _darkPurple,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 4),

                pw.Text(
                  'เหตุผลจากข้อมูล 3 ช่วง',
                  style: pw.TextStyle(
                    fontSize: 6.8,
                    color: _muted,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 1.5),

                pw.Text(
                  _cleanPdfText(advice.reason),
                  maxLines: 5,
                  style: pw.TextStyle(
                    fontSize: 6.8,
                    color: _ink,
                    lineSpacing: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _aiIcon() {
    return pw.Container(
      width: 25,
      height: 25,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: _purple,
        borderRadius: pw.BorderRadius.circular(7),
      ),
      child: pw.Text(
        'AI',
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // AI Actions
  // ============================================================

  static pw.Widget _aiActions(List<TeachingAction> actions) {
    final limitedActions = actions.take(3).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.1),
        1: pw.FlexColumnWidth(5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _darkPurple),
          children: [
            _tableCell('ช่วงเวลา', header: true, center: true),
            _tableCell('กิจกรรม / วิธีการที่แนะนำ', header: true),
          ],
        ),

        for (var index = 0; index < limitedActions.length; index++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven ? PdfColors.white : _panel,
            ),
            children: [
              _tableCell(limitedActions[index].phase, bold: true, center: true),
              _tableCell(_cleanPdfText(limitedActions[index].action)),
            ],
          ),
      ],
    );
  }

  // ============================================================
  // Helpers
  // ============================================================

  //ทำความสะอาดข้อความก่อนใส่ใน PDF เพื่อหลีกเลี่ยงปัญหาอักขระแปลก ๆ หลังจากการวิเคราะห์จาก AI

  static String _cleanPdfText(String text) {
    return text
        // Dash ที่อาจแสดงเป็นกล่องใน PDF
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('−', '-')
        // จุดไข่ปลา
        .replaceAll('…', '...')
        // อักขระที่ไม่จำเป็น / มองไม่เห็น
        .replaceAll('\u200B', '')
        .replaceAll('\u200C', '')
        .replaceAll('\u200D', '')
        .replaceAll('\uFEFF', '')
        .replaceAll('\u2010', '-') // hyphen
        .replaceAll('\u2011', '-') // non-breaking hyphen
        .replaceAll('\u2012', '-') // figure dash
        .replaceAll('\u2013', '-') // en dash
        .replaceAll('\u2014', '-') // em dash
        .replaceAll('\u2212', '-') // minus sign
        .replaceAll('\u00A0', ' ') // non-breaking space
        .replaceAll('\u202F', ' ') // narrow no-break space
        // ทำ whitespace ให้เป็นระเบียบ
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static EmotionPeriodData _period(
    EmotionReportData data,
    String type,
    String label,
  ) {
    for (final period in data.periods) {
      if (period.type == type) {
        return period;
      }
    }

    return EmotionPeriodData(type: type, label: label, counts: const {});
  }

  static const Set<String> _negativeEmotions = {
    'รู้สึกวิตกกังวล',
    'รู้สึกเครียด',
    'รู้สึกเบื่อหน่าย',
    'รู้สึกกลัว',
  };

  static String _displayEmotion(String emotion) {
    const labels = <String, String>{
      'รู้สึกสนใจ': 'สนใจ',
      'รู้สึกตื่นเต้น': 'ตื่นเต้น',
      'รู้สึกสนุกสนาน': 'สนุกสนาน',
      'รู้สึกวิตกกังวล': 'วิตกกังวล',
      'รู้สึกเครียด': 'เครียด',
      'รู้สึกเบื่อหน่าย': 'เบื่อหน่าย',
      'รู้สึกกลัว': 'กลัว',
      'รู้สึกเฉยๆ': 'เฉย ๆ',
      'รู้สึกเฉย ๆ': 'เฉย ๆ',
    };

    return labels[emotion] ?? emotion.replaceFirst('รู้สึก', '');
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Row(
      children: [
        pw.Container(
          width: 3,
          height: 13,
          decoration: pw.BoxDecoration(
            color: _purple,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9.5,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _smallLabel(String text) {
    return pw.Text(text, style: pw.TextStyle(fontSize: 6.2, color: _muted));
  }

  static pw.Widget _tableCell(
    String text, {
    bool header = false,
    bool bold = false,
    bool center = false,
  }) {
    return pw.Container(
      constraints: const pw.BoxConstraints(minHeight: 18),
      alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: pw.Text(
        _cleanPdfText(text),
        maxLines: 4,
        style: pw.TextStyle(
          fontSize: header ? 6.4 : 6.2,
          color: header ? PdfColors.white : (bold ? _darkPurple : _ink),
          fontWeight: header || bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _footer(EmotionReportData data) {
    return pw.Column(
      children: [
        pw.Divider(color: _line, height: 1),

        pw.SizedBox(height: 3),

        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'สร้างโดยระบบ EmotiTeach | '
                '${data.generatedAt.toLocal().toString().split('.').first}',
                style: pw.TextStyle(fontSize: 5.8, color: _muted),
              ),
            ),

            pw.Text(
              '${data.reportId} | 1/1',
              style: pw.TextStyle(fontSize: 5.8, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  static PdfColor _hex(String hex) {
    final value = hex.replaceFirst('#', '');

    return PdfColor.fromInt(0xFF000000 | int.parse(value, radix: 16));
  }
}

// ================================================================
// Trend Models
// ================================================================

enum _TrendType { good, warning, neutral }

class _TrendResult {
  final String text;
  final _TrendType type;

  const _TrendResult({required this.text, required this.type});
}
