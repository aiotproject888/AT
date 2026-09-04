class EmotionSlice {
  final String name;
  final double percent;
  final String colorHex;

  const EmotionSlice({
    required this.name,
    required this.percent,
    required this.colorHex,
  });
}

class TeachingAction {
  final String phase;
  final String action;

  const TeachingAction({
    required this.phase,
    required this.action,
  });
}

class EmotionReportData {
  final String reportId;
  final String subjectName;
  final String subjectCode;
  final String academicYear;
  final String semester;
  final String instructorName;
  final String sessionDate;
  final String sessionTime;
  final String lessonTopic;

  /// เก็บเฉพาะจำนวนผู้ที่กดตอบจริง ไม่ต้องมีจำนวนนักศึกษาทั้งหมด
  final int beforeRespondents;
  final int afterRespondents;

  /// ระบบมีเพียง 2 ช่วง: ก่อนเรียน และหลังเรียน
  final List<EmotionSlice> beforeEmotionDistribution;
  final List<EmotionSlice> afterEmotionDistribution;
  final double beforePositivePercent;
  final double afterPositivePercent;

  final String dominantEmotion;
  final String alertLevel;
  final String analysisSummary;
  final String recommendedTechnique;
  final String recommendationReason;
  final String recommendationPriority;
  final List<TeachingAction> teachingActions;
  final String generatedAt;

  const EmotionReportData({
    required this.reportId,
    required this.subjectName,
    required this.subjectCode,
    required this.academicYear,
    required this.semester,
    required this.instructorName,
    required this.sessionDate,
    required this.sessionTime,
    required this.lessonTopic,
    required this.beforeRespondents,
    required this.afterRespondents,
    required this.beforeEmotionDistribution,
    required this.afterEmotionDistribution,
    required this.beforePositivePercent,
    required this.afterPositivePercent,
    required this.dominantEmotion,
    required this.alertLevel,
    required this.analysisSummary,
    required this.recommendedTechnique,
    required this.recommendationReason,
    required this.recommendationPriority,
    required this.teachingActions,
    required this.generatedAt,
  });

  factory EmotionReportData.sample() {
    return const EmotionReportData(
      reportId: 'ET-2569-0820-001',
      subjectName: 'เกษตรแม่นยำ',
      subjectCode: '20-406-035-316',
      academicYear: '2569',
      semester: '1',
      instructorName: 'อ.เจี๊ยบ',
      sessionDate: '20 สิงหาคม 2569',
      sessionTime: '09:00-10:30 น.',
      lessonTopic: 'การวิเคราะห์และเลือกแบบจำลอง',
      beforeRespondents: 28,
      afterRespondents: 26,
      beforePositivePercent: 38,
      afterPositivePercent: 76,
      dominantEmotion: 'สนุก',
      alertLevel: 'ปกติ',
      beforeEmotionDistribution: [
        EmotionSlice(name: 'สับสน', percent: 34, colorHex: '#F28C45'),
        EmotionSlice(name: 'กังวล', percent: 28, colorHex: '#4E8BE8'),
        EmotionSlice(name: 'เฉย ๆ', percent: 20, colorHex: '#A7A9B7'),
        EmotionSlice(name: 'สนุก', percent: 18, colorHex: '#6C52E5'),
      ],
      afterEmotionDistribution: [
        EmotionSlice(name: 'สนุก', percent: 46, colorHex: '#6C52E5'),
        EmotionSlice(name: 'มีส่วนร่วม', percent: 30, colorHex: '#2EB67D'),
        EmotionSlice(name: 'สับสน', percent: 15, colorHex: '#F28C45'),
        EmotionSlice(name: 'กังวล', percent: 9, colorHex: '#4E8BE8'),
      ],
      analysisSummary:
          'หลังเรียน อารมณ์เชิงบวกเพิ่มจาก 38% เป็น 76% และความสับสนลดลงอย่างชัดเจน '
          'แสดงว่ากิจกรรมช่วยให้ผู้เรียนเข้าใจบทเรียนและมีส่วนร่วมมากขึ้น',
      recommendedTechnique: 'Exit Ticket + ทบทวนจุดที่ยังสับสน',
      recommendationReason:
          'ควรใช้คำถามสั้นท้ายคาบเพื่อยืนยันความเข้าใจ และนำหัวข้อที่ยังมีผู้เรียนสับสนไปทบทวนในครั้งถัดไป',
      recommendationPriority: 'ปานกลาง',
      teachingActions: [
        TeachingAction(
          phase: 'ก่อนเรียน',
          action: 'ใช้คำถามนำสั้น ๆ เพื่อสำรวจความรู้เดิมและอารมณ์ก่อนเริ่มบทเรียน',
        ),
        TeachingAction(
          phase: 'หลังเรียน',
          action: 'ใช้ Exit Ticket 1 ข้อ เพื่อตรวจสอบความเข้าใจและอารมณ์หลังเรียน',
        ),
        TeachingAction(
          phase: 'ครั้งถัดไป',
          action: 'ทบทวนหัวข้อที่ยังสับสนก่อนเข้าสู่เนื้อหาใหม่',
        ),
      ],
      generatedAt: '20 สิงหาคม 2569 เวลา 14:30 น.',
    );
  }
}