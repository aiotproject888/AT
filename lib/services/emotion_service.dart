import 'package:firebase_database/firebase_database.dart';

class EmotionService {
  final DatabaseReference _emotionRef =
      FirebaseDatabase.instance.ref('emotion_data');

  // =====================================================
  // ดึงข้อมูล Emotion ตามวันที่ + วิชา + Type
  // =====================================================

  Future<List<Map<String, dynamic>>> getEmotionRecordsByDate({
    required String subjectCode,
    required DateTime date,
    required String type,
  }) async {
    final dateString =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final path = '$subjectCode/${type}_$dateString';

    final snapshot = await _emotionRef.child(path).get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final data = Map<String, dynamic>.from(
      snapshot.value as Map,
    );

    return data.entries.map((entry) {
      final record =
          Map<String, dynamic>.from(entry.value);

      return {
        'id': entry.key,

        // ใช้ชื่อ field ให้เป็นมาตรฐานเดียวกันในแอป
        'emotion': record['emotion_name'],

        'emotion_id': record['emotion_id'],
        'emotion_name': record['emotion_name'],
        'subjectCode': record['subjectCode'],
        'timestamp': record['timestamp'],
        'counter': record['counter'] ?? 1,
      };
    }).toList();
  }

  // =====================================================
  // จำนวน Emotion Responses ตามวันที่
  // =====================================================

  Future<int> getStudentCountByDate({
    required String subjectCode,
    required DateTime date,
    required String type,
  }) async {
    final records = await getEmotionRecordsByDate(
      subjectCode: subjectCode,
      date: date,
      type: type,
    );

    return records.length;
  }

  // =====================================================
  // คำนวณ Positive ตามวันที่
  // =====================================================

  Future<int> getPositivePercentageByDate({
    required String subjectCode,
    required DateTime date,
    required String type,
  }) async {
    final records = await getEmotionRecordsByDate(
      subjectCode: subjectCode,
      date: date,
      type: type,
    );

    if (records.isEmpty) {
      return 0;
    }

    int positiveCount = 0;

    for (final record in records) {
      final emotion = record['emotion'];

      if (emotion == 'รู้สึกสนใจ' ||
          emotion == 'รู้สึกตื่นเต้น' ||
          emotion == 'รู้สึกสนุกสนาน' ||
          emotion == 'รู้สึกเฉยๆ') {
        positiveCount++;
      }
    }

    return ((positiveCount / records.length) * 100).round();
  }

  // =====================================================
  // สรุป Emotion สำหรับ Dashboard
  // =====================================================

  Future<Map<String, int>> getEmotionDistributionByDate({
    required String subjectCode,
    required DateTime date,
    required String type,
  }) async {
    final records = await getEmotionRecordsByDate(
      subjectCode: subjectCode,
      date: date,
      type: type,
    );

    final Map<String, int> emotions = {};

    for (final record in records) {
      final emotion = record['emotion'];

      if (emotion == null) {
        continue;
      }

      emotions[emotion] =
          (emotions[emotion] ?? 0) + 1;
    }

    return emotions;
  }

  // =====================================================
  // สรุป Emotion สำหรับส่งให้ AI
  // =====================================================

  Future<Map<String, dynamic>> getEmotionSummaryForAI({
    required String subjectCode,
    required DateTime date,
    required String type,
  }) async {
    final records = await getEmotionRecordsByDate(
      subjectCode: subjectCode,
      date: date,
      type: type,
    );

    final Map<String, int> emotions = {};

    for (final record in records) {
      final emotion = record['emotion'];

      if (emotion == null) {
        continue;
      }

      emotions[emotion] =
          (emotions[emotion] ?? 0) + 1;
    }

    return {
      'subjectCode': subjectCode,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'type': type,
      'totalResponses': records.length,
      'emotions': emotions,
    };
  }
}