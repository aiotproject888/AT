import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/emotion_report_data.dart';

class EmotionPdfReportService {
  EmotionPdfReportService._();

  static final PdfColor _purple = _hex('#6C52E5');
  static final PdfColor _darkPurple = _hex('#33265F');
  static final PdfColor _ink = _hex('#1F2030');
  static final PdfColor _muted = _hex('#676A7B');
  static final PdfColor _line = _hex('#E3E4EC');
  static final PdfColor _panel = _hex('#F6F5FB');
  static final PdfColor _green = _hex('#2EB67D');
  static final PdfColor _orange = _hex('#F28C45');
  static final PdfColor _blue = _hex('#4E8BE8');

  static Future<Uint8List> generate(EmotionReportData data) async {
    final regularFont = await PdfGoogleFonts.sarabunRegular();
    final boldFont = await PdfGoogleFonts.sarabunBold();
    final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);

    final document = pw.Document(
      title: 'EmotiTeach Emotion Analysis Report',
      author: 'EmotiTeach',
      subject: data.subjectName,
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 26, 34, 24),
        theme: theme,
        build: (_) => _buildReport(data),
      ),
    );

    return document.save();
  }

  static pw.Widget _buildReport(EmotionReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _header('รายงานผลการวิเคราะห์อารมณ์ผู้เรียน'),
        pw.SizedBox(height: 10),
        _subjectInfo(data),
        pw.SizedBox(height: 11),
        _sectionTitle('ภาพรวม'),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            _kpi('อารมณ์หลักหลังเรียน', data.dominantEmotion, _purple),
            pw.SizedBox(width: 6),
            _kpi(
              'อารมณ์เชิงบวกหลังเรียน',
              '${_number(data.afterPositivePercent)}%',
              _green,
            ),
            pw.SizedBox(width: 6),
            _kpi('ผู้ตอบก่อนเรียน', '${data.beforeRespondents} คน', _blue),
            pw.SizedBox(width: 6),
            _kpi('ผู้ตอบหลังเรียน', '${data.afterRespondents} คน', _orange),
          ],
        ),
        pw.SizedBox(height: 11),
        _sectionTitle('เปรียบเทียบอารมณ์ก่อนเรียนและหลังเรียน'),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _periodCard(
                title: 'ก่อนเรียน',
                respondents: data.beforeRespondents,
                positivePercent: data.beforePositivePercent,
                distribution: data.beforeEmotionDistribution,
                accent: _blue,
              ),
            ),
            pw.SizedBox(width: 9),
            pw.Expanded(
              child: _periodCard(
                title: 'หลังเรียน',
                respondents: data.afterRespondents,
                positivePercent: data.afterPositivePercent,
                distribution: data.afterEmotionDistribution,
                accent: _purple,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        _analysisCard(data),
        pw.SizedBox(height: 10),
        _recommendationCard(data),
        pw.SizedBox(height: 10),
        _sectionTitle('แผนปรับการสอน'),
        pw.SizedBox(height: 5),
        _actionTable(data.teachingActions),
        pw.Spacer(),
        pw.Text(
          'คำแนะนำจาก AI ใช้เพื่อสนับสนุนการตัดสินใจของผู้สอนเท่านั้น '
          'รายงานนี้แสดงข้อมูลแบบภาพรวมและไม่เปิดเผยรายชื่อผู้เรียน',
          style: pw.TextStyle(fontSize: 6.8, color: _muted),
        ),
        pw.SizedBox(height: 5),
        _footer(data),
      ],
    );
  }

  static pw.Widget _header(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: pw.BoxDecoration(
        color: _darkPurple,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 38,
            height: 38,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(color: _purple, shape: pw.BoxShape.circle),
            child: pw.Text(
              'ET',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 11),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'EmotiTeach',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  title,
                  style: pw.TextStyle(color: _hex('#D9D3FF'), fontSize: 8.5),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _hex('#493B7A'),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              'ก่อนเรียน / หลังเรียน',
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 7.5),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _subjectInfo(EmotionReportData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(9),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoItem('รายวิชา', data.subjectName, flex: 2),
              _infoItem('รหัสวิชา', data.subjectCode),
              _infoItem('ผู้สอน', data.instructorName),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'ปีการศึกษา ${data.academicYear} | ภาคเรียน ${data.semester}',
                  style: pw.TextStyle(fontSize: 7.4, color: _muted),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  '${data.sessionDate} | ${data.sessionTime} | ${data.lessonTopic}',
                  style: pw.TextStyle(fontSize: 7.4, color: _muted),
                ),
              ),
            ],
          ),
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
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 9.3,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _kpi(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        height: 52,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: _panel,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(child: _smallLabel(title)),
              ],
            ),
            pw.Spacer(),
            pw.Text(
              value,
              maxLines: 1,
              style: pw.TextStyle(
                fontSize: 10.5,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _periodCard({
    required String title,
    required int respondents,
    required double positivePercent,
    required List<EmotionSlice> distribution,
    required PdfColor accent,
  }) {
    final dominant = distribution.isEmpty
        ? const EmotionSlice(name: '-', percent: 0, colorHex: '#6C52E5')
        : distribution.first;

    return pw.Container(
      height: 144,
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(9),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(width: 4, height: 14, color: accent),
              pw.SizedBox(width: 6),
              pw.Text(title, style: _cardTitle()),
              pw.Spacer(),
              pw.Text(
                'ผู้ตอบ $respondents คน',
                style: pw.TextStyle(fontSize: 7.5, color: _muted),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Container(
                width: 66,
                height: 66,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: _hex(dominant.colorHex), width: 10),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      '${_number(dominant.percent)}%',
                      style: pw.TextStyle(
                        fontSize: 12.5,
                        color: _ink,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(dominant.name, style: pw.TextStyle(fontSize: 7, color: _muted)),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  children: distribution
                      .map(
                        (item) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 6,
                                height: 6,
                                decoration: pw.BoxDecoration(
                                  color: _hex(item.colorHex),
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.SizedBox(width: 5),
                              pw.Expanded(
                                child: pw.Text(
                                  item.name,
                                  style: pw.TextStyle(fontSize: 7.3, color: _ink),
                                ),
                              ),
                              pw.Text(
                                '${_number(item.percent)}%',
                                style: pw.TextStyle(
                                  fontSize: 7.3,
                                  color: _muted,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Row(
            children: [
              pw.Text('อารมณ์เชิงบวก', style: pw.TextStyle(fontSize: 7.2, color: _muted)),
              pw.SizedBox(width: 6),
              pw.Container(
                width: 82,
                height: 5,
                decoration: pw.BoxDecoration(
                  color: _line,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Container(
                    width: 82 *
                        (positivePercent / 100).clamp(0.0, 1.0).toDouble(),
                    height: 5,
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                '${_number(positivePercent)}%',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _analysisCard(EmotionReportData data) {
    final change = data.afterPositivePercent - data.beforePositivePercent;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: pw.BoxDecoration(
        color: _hex('#F1EEFF'),
        borderRadius: pw.BorderRadius.circular(9),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 4, height: 38, color: _purple),
          pw.SizedBox(width: 9),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('สรุปผลการวิเคราะห์', style: _cardTitle()),
                pw.SizedBox(height: 3),
                pw.Text(
                  data.analysisSummary,
                  style: pw.TextStyle(fontSize: 8.1, color: _ink, lineSpacing: 1.8),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _green,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              '${change >= 0 ? '+' : ''}${_number(change)} จุด',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _recommendationCard(EmotionReportData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(9),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 83,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('คำแนะนำจาก AI', style: _cardTitle()),
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _hex('#FFF0CF'),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    'ความสำคัญ: ${data.recommendationPriority}',
                    style: pw.TextStyle(fontSize: 6.8, color: _hex('#9B6814')),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  data.recommendedTechnique,
                  style: pw.TextStyle(
                    fontSize: 10.2,
                    color: _darkPurple,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  data.recommendationReason,
                  style: pw.TextStyle(fontSize: 7.7, color: _ink, lineSpacing: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _actionTable(List<TeachingAction> actions) {
    return pw.Table(
      border: pw.TableBorder.all(color: _line),
      columnWidths: const {
        0: pw.FixedColumnWidth(80),
        1: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _darkPurple),
          children: [
            _tableCell('ช่วงเวลา', header: true),
            _tableCell('สิ่งที่แนะนำ', header: true),
          ],
        ),
        ...actions.asMap().entries.map(
          (entry) => pw.TableRow(
            decoration: pw.BoxDecoration(
              color: entry.key.isEven ? PdfColors.white : _panel,
            ),
            children: [
              _tableCell(entry.value.phase, bold: true),
              _tableCell(entry.value.action),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool header = false,
    bool bold = false,
  }) {
    return pw.Container(
      constraints: pw.BoxConstraints(minHeight: header ? 23 : 28),
      alignment: pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header ? 7.8 : 7.4,
          color: header ? PdfColors.white : (bold ? _darkPurple : _ink),
          fontWeight: header || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          lineSpacing: 1.2,
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 10.8, color: _ink, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _smallLabel(String text) {
    return pw.Text(text, style: pw.TextStyle(fontSize: 7.2, color: _muted));
  }

  static pw.TextStyle _cardTitle() {
    return pw.TextStyle(fontSize: 9, color: _ink, fontWeight: pw.FontWeight.bold);
  }

  static pw.Widget _footer(EmotionReportData data) {
    return pw.Column(
      children: [
        pw.Divider(color: _line, height: 1),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'สร้างโดยระบบ EmotiTeach | ${data.generatedAt}',
                style: pw.TextStyle(fontSize: 6.5, color: _muted),
              ),
            ),
            pw.Text(
              '${data.reportId} | 1/1',
              style: pw.TextStyle(fontSize: 6.5, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  static String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  static PdfColor _hex(String hex) {
    final value = hex.replaceFirst('#', '');
    final rgb = int.parse(value, radix: 16);
    return PdfColor.fromInt(0xFF000000 | rgb);
  }
}