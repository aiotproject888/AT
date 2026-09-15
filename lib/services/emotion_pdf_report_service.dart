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
        margin: const pw.EdgeInsets.fromLTRB(34, 26, 34, 24),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (_) => _buildReport(data),
      ),
    );
    return document.save();
  }

  static pw.Widget _buildReport(EmotionReportData data) {
    final before = _period(data, 'before_class', 'ก่อนเรียน');
    final during = _period(data, 'during_class', 'ระหว่างเรียน');
    final after = _period(data, 'after_class', 'หลังเรียน');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _header(),
        pw.SizedBox(height: 10),
        _subjectInfo(data),
        pw.SizedBox(height: 10),
        _sectionTitle('ภาพรวม'),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            _kpi('ก่อนเรียน', _totalText(before), _blue),
            pw.SizedBox(width: 6),
            _kpi('ระหว่างเรียน', _totalText(during), _orange),
            pw.SizedBox(width: 6),
            _kpi('หลังเรียน', _totalText(after), _green),
            pw.SizedBox(width: 6),
            _kpi('อารมณ์เด่นหลังเรียน', _dominantShort(after), _purple),
          ],
        ),
        pw.SizedBox(height: 10),
        _sectionTitle('อารมณ์ผู้เรียนในแต่ละช่วง'),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _periodCard(before, _blue)),
            pw.SizedBox(width: 7),
            pw.Expanded(child: _periodCard(during, _orange)),
            pw.SizedBox(width: 7),
            pw.Expanded(child: _periodCard(after, _purple)),
          ],
        ),
        pw.SizedBox(height: 10),
        _summaryCard(data, before, during, after),
        pw.SizedBox(height: 10),
        _recommendationCard(data.aiAdvice),
        if (data.aiAdvice?.actions.isNotEmpty == true) ...[
          pw.SizedBox(height: 9),
          _sectionTitle('กิจกรรมที่ AI แนะนำ'),
          pw.SizedBox(height: 5),
          _actionTable(data.aiAdvice!.actions.take(3).toList()),
        ],
        pw.Spacer(),
        pw.Text(
          'ข้อมูลนี้ใช้ประกอบการวางแผนการสอน ผู้ตอบแต่ละช่วงอาจเป็นคนละกลุ่ม '
          'และการกดซ้ำอาจทำให้คนเดิมถูกนับมากกว่าหนึ่งครั้ง',
          style: pw.TextStyle(fontSize: 6.8, color: _muted),
        ),
        pw.SizedBox(height: 5),
        _footer(data),
      ],
    );
  }

  static pw.Widget _header() => pw.Container(
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
              decoration: pw.BoxDecoration(
                color: _purple,
                shape: pw.BoxShape.circle,
              ),
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
                    'รายงานอารมณ์ผู้เรียน',
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
                'ก่อนเรียน / ระหว่างเรียน / หลังเรียน',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 7.2),
              ),
            ),
          ],
        ),
      );

  static pw.Widget _subjectInfo(EmotionReportData data) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line),
          borderRadius: pw.BorderRadius.circular(9),
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

  static pw.Widget _infoItem(String title, String value, {int flex = 1}) =>
      pw.Expanded(
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
                fontSize: 8.5,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  static pw.Widget _kpi(String title, String value, PdfColor color) => pw.Expanded(
        child: pw.Container(
          height: 48,
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
                    decoration: pw.BoxDecoration(
                      color: color,
                      shape: pw.BoxShape.circle,
                    ),
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
                  fontSize: 10,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

  static pw.Widget _periodCard(EmotionPeriodData period, PdfColor accent) {
    final entries = period.counts.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final dominant = entries.isEmpty ? null : entries.first;

    return pw.Container(
      height: 142,
      padding: const pw.EdgeInsets.all(9),
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
              pw.SizedBox(width: 5),
              pw.Text(period.label, style: _cardTitle()),
              pw.Spacer(),
              pw.Text(
                period.hasResponses ? 'ผู้ตอบ ${period.total} คน' : 'ยังไม่มีข้อมูล',
                style: pw.TextStyle(fontSize: 6.8, color: _muted),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          if (!period.hasResponses)
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  'รอข้อมูลการบันทึกอารมณ์',
                  style: pw.TextStyle(fontSize: 7.5, color: _muted),
                ),
              ),
            )
          else
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 56,
                    height: 56,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: accent, width: 9),
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          '${dominant!.value} คน',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            color: _ink,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _displayEmotion(dominant.key),
                          maxLines: 1,
                          style: pw.TextStyle(fontSize: 5.8, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 7),
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        for (final entry in entries)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2.5),
                            child: pw.Row(
                              children: [
                                pw.Container(
                                  width: 5,
                                  height: 5,
                                  decoration: pw.BoxDecoration(
                                    color: _emotionColor(entry.key),
                                    shape: pw.BoxShape.circle,
                                  ),
                                ),
                                pw.SizedBox(width: 4),
                                pw.Expanded(
                                  child: pw.Text(
                                    _displayEmotion(entry.key),
                                    maxLines: 1,
                                    style: pw.TextStyle(fontSize: 6.5, color: _ink),
                                  ),
                                ),
                                pw.Text(
                                  '${entry.value} คน',
                                  style: pw.TextStyle(
                                    fontSize: 6.5,
                                    color: _muted,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
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
        ],
      ),
    );
  }

  static pw.Widget _summaryCard(
    EmotionReportData data,
    EmotionPeriodData before,
    EmotionPeriodData during,
    EmotionPeriodData after,
  ) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: pw.BoxDecoration(
          color: _hex('#F1EEFF'),
          borderRadius: pw.BorderRadius.circular(9),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(width: 4, height: 42, color: _purple),
            pw.SizedBox(width: 9),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('สรุปอารมณ์ของผู้เรียน', style: _cardTitle()),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '${_dominantSentence(before)}  '
                    '${_dominantSentence(during)}  '
                    '${_dominantSentence(after)}',
                    style: pw.TextStyle(fontSize: 7.8, color: _ink, lineSpacing: 1.5),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _followUpSignal(data),
                    style: pw.TextStyle(fontSize: 7.5, color: _muted, lineSpacing: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  static pw.Widget _recommendationCard(ReportAiAdvice? advice) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: pw.BoxDecoration(
          color: _panel,
          borderRadius: pw.BorderRadius.circular(9),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 90,
              child: pw.Text('คำแนะนำจาก AI', style: _cardTitle()),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: advice == null
                  ? pw.Text(
                      'ยังไม่มีคำแนะนำสำหรับข้อมูลชุดนี้',
                      style: pw.TextStyle(fontSize: 8, color: _muted),
                    )
                  : pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _excerpt(advice.technique, 120),
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            color: _darkPurple,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          _excerpt(advice.reason, 180),
                          style: pw.TextStyle(fontSize: 7.5, color: _ink),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );

  static pw.Widget _actionTable(List<TeachingAction> actions) => pw.Table(
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
          for (var index = 0; index < actions.length; index++)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: index.isEven ? PdfColors.white : _panel,
              ),
              children: [
                _tableCell(actions[index].phase, bold: true),
                _tableCell(_excerpt(actions[index].action, 100)),
              ],
            ),
        ],
      );

  static EmotionPeriodData _period(
    EmotionReportData data,
    String type,
    String label,
  ) {
    for (final period in data.periods) {
      if (period.type == type) return period;
    }
    return EmotionPeriodData(type: type, label: label, counts: const {});
  }

  static String _totalText(EmotionPeriodData period) =>
      period.hasResponses ? '${period.total} คน' : '-';

  static String _dominantShort(EmotionPeriodData period) {
    final leaders = _leadingEmotions(period);
    if (leaders.isEmpty) return '-';
    final names = leaders.map((entry) => _displayEmotion(entry.key)).toList();
    return _joinThai(names);
  }

  static String _dominantSentence(EmotionPeriodData period) {
    if (!period.hasResponses) return '${period.label}: ยังไม่มีข้อมูล';
    final leaders = _leadingEmotions(period);
    if (leaders.isEmpty) return '${period.label}: ยังไม่ระบุอารมณ์';
    final names = _joinThai(
      leaders.map((entry) => _displayEmotion(entry.key)).toList(),
    );
    final count = leaders.first.value;
    return leaders.length == 1
        ? '${period.label}: พบ$namesมากที่สุด $count คน'
        : '${period.label}: พบ$namesสูงสุดเท่ากัน อย่างละ $count คน';
  }

  static String _followUpSignal(EmotionReportData data) {
    final after = _period(data, 'after_class', 'หลังเรียน');
    if (!after.hasResponses) return 'ควรรอข้อมูลหลังเรียนก่อนนำผลไปวางแผนคาบถัดไป';
    const watched = [
      'รู้สึกกลัว',
      'รู้สึกวิตกกังวล',
      'รู้สึกเครียด',
      'รู้สึกเบื่อหน่าย',
    ];
    final found = <String>[];
    for (final emotion in watched) {
      final count = after.counts[emotion] ?? 0;
      if (count > 0) found.add('${_displayEmotion(emotion)} $count คน');
    }
    return found.isEmpty
        ? 'หลังเรียนไม่พบความกลัว ความวิตกกังวล ความเครียด หรือความเบื่อหน่าย'
        : 'หลังเรียนยังพบ ${_joinThai(found)} ควรใช้คำแนะนำของ AI '
            'ประกอบการวางแผนคาบถัดไป';
  }

  static List<MapEntry<String, int>> _leadingEmotions(
    EmotionPeriodData period,
  ) {
    final entries = period.counts.entries
        .where(
          (entry) =>
              entry.value > 0 &&
              entry.key != 'ไม่ระบุอารมณ์' &&
              entry.key != 'ไม่ระบุ',
        )
        .toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        return count != 0 ? count : a.key.compareTo(b.key);
      });
    if (entries.isEmpty) return const [];
    final highest = entries.first.value;
    return entries.where((entry) => entry.value == highest).toList();
  }

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

  static PdfColor _emotionColor(String emotion) {
    const colors = <String, String>{
      'รู้สึกสนใจ': '#2EB67D',
      'รู้สึกตื่นเต้น': '#22B8CF',
      'รู้สึกสนุกสนาน': '#6C52E5',
      'รู้สึกวิตกกังวล': '#4E8BE8',
      'รู้สึกเครียด': '#E65C5C',
      'รู้สึกเบื่อหน่าย': '#A7A9B7',
      'รู้สึกกลัว': '#F28C45',
    };
    return _hex(colors[emotion] ?? '#8A7CE0');
  }

  static String _joinThai(List<String> values) {
    if (values.isEmpty) return '';
    if (values.length == 1) return values.first;
    if (values.length == 2) return '${values.first} และ ${values.last}';
    return '${values.take(values.length - 1).join(', ')} และ ${values.last}';
  }

  static String _excerpt(String value, int limit) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.runes.length <= limit) return clean;
    return '${String.fromCharCodes(clean.runes.take(limit))}...';
  }

  static pw.Widget _sectionTitle(String text) => pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10.8,
          color: _ink,
          fontWeight: pw.FontWeight.bold,
        ),
      );

  static pw.Widget _smallLabel(String text) => pw.Text(
        text,
        style: pw.TextStyle(fontSize: 7.2, color: _muted),
      );

  static pw.TextStyle _cardTitle() => pw.TextStyle(
        fontSize: 9,
        color: _ink,
        fontWeight: pw.FontWeight.bold,
      );

  static pw.Widget _tableCell(
    String text, {
    bool header = false,
    bool bold = false,
    bool center = false,
  }) =>
      pw.Container(
        constraints: const pw.BoxConstraints(minHeight: 21),
        alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: header ? 7.5 : 7.3,
            color: header ? PdfColors.white : (bold ? _darkPurple : _ink),
            fontWeight:
                header || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  static pw.Widget _footer(EmotionReportData data) => pw.Column(
        children: [
          pw.Divider(color: _line, height: 1),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'สร้างโดยระบบ EmotiTeach | '
                  '${data.generatedAt.toLocal().toString().split('.').first}',
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

  static PdfColor _hex(String hex) {
    final value = hex.replaceFirst('#', '');
    return PdfColor.fromInt(0xFF000000 | int.parse(value, radix: 16));
  }
}
