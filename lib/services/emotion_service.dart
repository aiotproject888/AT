import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionService {
  final DatabaseReference _emotionRef = FirebaseDatabase.instance.ref(
    'emotion_data',
  );

  // ดึงข้อมูล Emotion ตามวันที่ + วิชา + Type

  Future<List<Map<String, dynamic>>> getEmotionRecordsBySession({
    required String subjectCode,
    required String sessionId,
    required String type,
  }) async {
    final path = '$subjectCode/$sessionId/$type';

    final snapshot = await _emotionRef.child(path).get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final rawData = snapshot.value;

    if (rawData is! Map) {
      return [];
    }

    final data = Map<String, dynamic>.from(rawData);

    final records = <Map<String, dynamic>>[];

    for (final entry in data.entries) {
      if (entry.value is! Map) {
        continue;
      }

      final record = Map<String, dynamic>.from(entry.value);

      records.add({
        'id': entry.key.toString(),
        'emotion': record['emotion_name'],
        'emotion_id': record['emotion_id'],
        'emotion_name': record['emotion_name'],
        'subjectCode': record['subjectCode'],
        'timestamp': record['timestamp'],
        'counter': record['counter'] ?? 1,
        'sessionId': sessionId,
      });
    }

    return records;
  }

  // =====================================================
  // จำนวน Emotion Responses ตามวันที่
  // =====================================================

  Future<int> getStudentCountByDate({
    required String subjectCode,
    required String sessionId,
    required String type,
  }) async {
    final records = await getEmotionRecordsBySession(
      subjectCode: subjectCode,
      sessionId: sessionId,
      type: type,
    );

    return records.length;
  }

  // =====================================================
  // คำนวณ Positive ตามวันที่
  // =====================================================

  Future<int> getPositivePercentageByDate({
    required String subjectCode,
    required String sessionId,
    required String type,
  }) async {
    final records = await getEmotionRecordsBySession(
      subjectCode: subjectCode,
      sessionId: sessionId,
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
          emotion == 'รู้สึกสนุกสนาน') {
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
    required String sessionId,
    required String type,
  }) async {
    final records = await getEmotionRecordsBySession(
      subjectCode: subjectCode,
      sessionId: sessionId,
      type: type,
    );

    final Map<String, int> emotions = {};

    for (final record in records) {
      final emotion = record['emotion'];

      if (emotion == null) {
        continue;
      }

      emotions[emotion] = (emotions[emotion] ?? 0) + 1;
    }

    return emotions;
  }

  ////
  Future<Map<String, int>> getEmotionDistributionBySession({
    required String subjectCode,
    required String sessionId,
    required String type,
  }) async {
    final records = await getEmotionRecordsBySession(
      subjectCode: subjectCode,
      sessionId: sessionId,
      type: type,
    );

    final Map<String, int> emotions = {};

    for (final record in records) {
      final emotion = record['emotion'];

      if (emotion == null) continue;

      emotions[emotion] = (emotions[emotion] ?? 0) + 1;
    }

    return emotions;
  }

  // =====================================================
  // สรุป Emotion สำหรับส่งให้ AI

  Future<Map<String, dynamic>> getEmotionSummaryForAI({
    required String subjectCode,
    required String sessionId,
    required String type,
  }) async {
    final records = await getEmotionRecordsBySession(
      subjectCode: subjectCode,
      sessionId: sessionId,
      type: type,
    );

    final Map<String, int> emotions = {};

    int totalResponses = 0;

    for (final record in records) {
      final emotion = record['emotion'];

      if (emotion == null) {
        continue;
      }

      final counter = ((record['counter'] ?? 1) as num).toInt();

      emotions[emotion] = (emotions[emotion] ?? 0) + counter;
      totalResponses += counter;
    }

    // ดึงข้อมูล Session เพื่อใช้ระบุวันและเวลาของข้อมูล
    final sessionSnapshot = await FirebaseFirestore.instance
        .collection('class_sessions')
        .doc(sessionId)
        .get();

    DateTime? startTime;
    DateTime? endTime;

    if (sessionSnapshot.exists) {
      final data = sessionSnapshot.data();

      final startTimestamp = data?['startTime'];
      final endTimestamp = data?['endTime'];

      if (startTimestamp is Timestamp) {
        startTime = startTimestamp.toDate();
      }

      if (endTimestamp is Timestamp) {
        endTime = endTimestamp.toDate();
      }
    }

    return {
      'subjectCode': subjectCode,
      'sessionId': sessionId,
      'type': type,

      // วันและเวลาของ Session
      'date': startTime == null
          ? null
          : '${startTime.year}-'
                '${startTime.month.toString().padLeft(2, '0')}-'
                '${startTime.day.toString().padLeft(2, '0')}',

      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),

      'totalResponses': totalResponses,
      'emotions': emotions,
    };
  }
}
