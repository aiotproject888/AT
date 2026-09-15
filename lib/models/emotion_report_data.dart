class TeachingAction {
  final String phase;
  final String action;
  const TeachingAction({required this.phase, required this.action});
}

/// ผลจาก AI จริง ต้องตรงกับข้อมูลที่ส่งไปวิเคราะห์
class ReportAiAdvice {
  final String snapshotKey;
  final String technique;
  final String reason;
  final List<TeachingAction> actions;
  const ReportAiAdvice({
    required this.snapshotKey,
    required this.technique,
    required this.reason,
    this.actions = const [],
  });
}

class EmotionPeriodData {
  final String type;
  final String label;
  final Map<String, int> counts;
  EmotionPeriodData({
    required this.type,
    required this.label,
    required Map<String, int> counts,
  }) : counts = Map.unmodifiable(counts);

  int get total => counts.values.fold(0, (sum, count) => sum + count);
  bool get hasResponses => total > 0;
}

class EmotionReportData {
  final String reportId;
  final String subjectName;
  final String subjectCode;
  final String academicYear;
  final String semester;
  final String dateKey;
  final String instructorName;
  final List<EmotionPeriodData> periods;
  final DateTime generatedAt;
  final ReportAiAdvice? aiAdvice;

  EmotionReportData({
    required this.reportId,
    required this.subjectName,
    required this.subjectCode,
    required this.academicYear,
    required this.semester,
    required this.dateKey,
    required List<EmotionPeriodData> periods,
    required this.generatedAt,
    this.instructorName = '',
    this.aiAdvice,
  }) : periods = List.unmodifiable(periods);

  EmotionReportData withAdvice(ReportAiAdvice advice) => EmotionReportData(
    reportId: reportId, subjectName: subjectName, subjectCode: subjectCode,
    academicYear: academicYear, semester: semester, dateKey: dateKey,
    periods: periods, generatedAt: generatedAt,
    instructorName: instructorName, aiAdvice: advice,
  );
}
