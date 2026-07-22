import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final DatabaseReference _currentSessionRef = FirebaseDatabase.instance.ref(
    'current_session',
  );

  // เริ่ม Session
  Future<String> startSession({required String subjectCode}) async {
    // สร้าง Session ใน Firestore
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

    await _currentSessionRef.update({'status': 'inactive'});
  }
}
