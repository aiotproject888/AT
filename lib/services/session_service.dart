import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final DatabaseReference _currentSessionRef = FirebaseDatabase.instance.ref(
    'current_session',
  );

  // เริ่ม Session
  Future<String> startSession({required String subjectCode}) async {
    final activeSessions = await _firestore
        .collection('class_sessions')
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in activeSessions.docs) {
      await doc.reference.update({
        'status': 'ended',
        'endTime': FieldValue.serverTimestamp(),
      });
    }

    final sessionRef = await _firestore.collection('class_sessions').add({
      'subjectCode': subjectCode,
      'status': 'active',
      'startTime': FieldValue.serverTimestamp(),
      'endTime': null,
    });

    final sessionId = sessionRef.id;

    // บันทึก Session ปัจจุบันให้ ESP32 อ่าน
    await _currentSessionRef.set({
      'sessionId': sessionId,
      'subjectCode': subjectCode,
      'type': 'before_class',
      'status': 'active',
    });

    return sessionId;
  }

  // เปลี่ยนเป็นหลังเรียน
  Future<void> changeToAfterClass(String sessionId) async {
    await _currentSessionRef.update({
      'sessionId': sessionId,
      'type': 'after_class',
      'status': 'active',
    });
  }

  // จบ Session
  Future<void> endSession(String sessionId) async {
    await _firestore.collection('class_sessions').doc(sessionId).update({
      'status': 'ended',
      'endTime': FieldValue.serverTimestamp(),
    });

     final currentSnapshot =
        await _currentSessionRef.get();

    if (currentSnapshot.exists) {
      final data =
          Map<String, dynamic>.from(
        currentSnapshot.value as Map,
      );

      // ถ้าเป็น Session ปัจจุบัน
      // ให้เปลี่ยนสถานะเป็น inactive
      if (data['sessionId'] == sessionId) {
        await _currentSessionRef.update({
          'status': 'inactive',
        });
      }
    }
  }

  Future<Map<String, dynamic>?> getActiveSession(String subjectCode) async {
    final snapshot = await _firestore
        .collection('class_sessions')
        .where('subjectCode', isEqualTo: subjectCode)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;

    return {'sessionId': doc.id, ...doc.data()};
  }



// ดึง Session ของรายวิชาตามวันที่
Future<List<Map<String, dynamic>>> getSessionsByDate({
  required String subjectCode,
  required DateTime date,
}) async {
  final snapshot = await _firestore
      .collection('class_sessions')
      .where(
        'subjectCode',
        isEqualTo: subjectCode,
      )
      .get();

  final sessions = <Map<String, dynamic>>[];

  for (final doc in snapshot.docs) {
    final data = doc.data();

    final startTime = data['startTime'];

    if (startTime == null) {
      continue;
    }

    final sessionDate =
        (startTime as Timestamp).toDate();

    if (sessionDate.year == date.year &&
        sessionDate.month == date.month &&
        sessionDate.day == date.day) {
      sessions.add({
        'sessionId': doc.id,
        ...data,
      });
    }
  }

  return sessions;
}




}
