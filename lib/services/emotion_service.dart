import 'package:firebase_database/firebase_database.dart';

class EmotionService {
  final DatabaseReference _emotionRef =
      FirebaseDatabase.instance.ref('emotion_records');

  // =====================================================
  // ดึงข้อมูล Emotion ทั้งหมด
  // =====================================================

  Future<List<Map<String, dynamic>>> getEmotionRecords() async {
    final snapshot = await _emotionRef.get();

    if (!snapshot.exists) {
      return [];
    }

    final data = Map<String, dynamic>.from(
      snapshot.value as Map,
    );

    return data.entries.map((entry) {
      return {
        'id': entry.key,
        ...Map<String, dynamic>.from(entry.value),
      };
    }).toList();
  }

  // =====================================================
  // ดึงข้อมูล Emotion ตาม Session
  // =====================================================

  Future<List<Map<String, dynamic>>> getEmotionRecordsBySession(
    String sessionId,
  ) async {
    final snapshot = await _emotionRef
        .orderByChild('sessionId')
        .equalTo(sessionId)
        .get();

    if (!snapshot.exists) {
      return [];
    }

    final data = Map<String, dynamic>.from(
      snapshot.value as Map,
    );

    return data.entries.map((entry) {
      return {
        'id': entry.key,
        ...Map<String, dynamic>.from(entry.value),
      };
    }).toList();
  }

  // =====================================================
  // จำนวน Student / Emotion Records
  // =====================================================

  Future<int> getStudentCount() async {
    final records = await getEmotionRecords();

    return records.length;
  }

  // =====================================================
  // คำนวณเปอร์เซ็นต์ Positive
  // =====================================================

  Future<int> getPositivePercentage() async {
    final records = await getEmotionRecords();

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
  // ดึงข้อมูล Emotion ตาม Session และ Type
  // =====================================================

  Future<List<Map<String, dynamic>>> getEmotionRecordsByType({
    required String sessionId,
    required String type,
  }) async {
    final records =
        await getEmotionRecordsBySession(sessionId);

    return records.where((record) {
      return record['type'] == type;
    }).toList();
  }

  // =====================================================
  // จำนวน Emotion Records ตาม Type
  // =====================================================

  Future<int> getResponseCountByType({
    required String sessionId,
    required String type,
  }) async {
    final records =
        await getEmotionRecordsByType(
      sessionId: sessionId,
      type: type,
    );

    return records.length;
  }

  // =====================================================
  // คำนวณเปอร์เซ็นต์ Positive ตาม Type
  // =====================================================

  Future<int> getPositivePercentageByType({
    required String sessionId,
    required String type,
  }) async {
    final records =
        await getEmotionRecordsByType(
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
}