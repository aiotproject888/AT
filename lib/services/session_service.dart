import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final DatabaseReference _currentSessionRef = FirebaseDatabase.instance.ref(
    'current_session',
  );

  static const Duration inactivityLimit = Duration(hours: 3);

  Future<String> startSession({required String subjectCode}) async {
    // ปิด Session ที่ active อยู่ก่อน
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

    // สร้าง Session ใหม่
    final sessionRef = await _firestore.collection('class_sessions').add({
      'subjectCode': subjectCode,
      'status': 'active',
      'startTime': FieldValue.serverTimestamp(),
      'endTime': null,

      // ใช้สำหรับตรวจสอบว่า Session มีการ Activity ล่าสุดเมื่อไร
      'lastActivityTime': FieldValue.serverTimestamp(),
    });



    final sessionId = sessionRef.id;

    // บันทึก Session ปัจจุบันให้ ESP32 อ่าน
    await _currentSessionRef.set({
      'sessionId': sessionId,
      'subjectCode': subjectCode,
      'status': 'active',
      'lastActivityTime': ServerValue.timestamp,
    });

    return sessionId;
  }


  // อัปเดตเวลาการใช้งานล่าสุด
  Future<void> updateLastActivity(String sessionId) async {
    try {
      // อัปเดตใน Firestore
      await _firestore
          .collection('class_sessions')
          .doc(sessionId)
          .update({
        'lastActivityTime': FieldValue.serverTimestamp(),
      });

      // อัปเดตใน RTDB ด้วย
      final currentSnapshot = await _currentSessionRef.get();

      if (currentSnapshot.exists &&
          currentSnapshot.value != null) {
        final data = Map<String, dynamic>.from(
          currentSnapshot.value as Map,
        );

        if (data['sessionId'] == sessionId &&
            data['status'] == 'active') {
          await _currentSessionRef.update({
            'lastActivityTime': ServerValue.timestamp,
          });
        }
      }
    } catch (e) {
      print(
        'อัปเดต Activity ของ Session $sessionId ไม่สำเร็จ: $e',
      );
    }
  }

  // ตรวจสอบ Session ว่าหมดอายุจากการไม่มี Activity หรือไม่
  Future<bool> checkAndAutoCloseSession(
    String sessionId,
  ) async {
    try {
      final doc = await _firestore
          .collection('class_sessions')
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data();

      if (data == null || data['status'] != 'active') {
        return false;
      }

      final lastActivity = data['lastActivityTime'];

      // ถ้ายังไม่มี lastActivityTime
      // ให้ถือว่ายังไม่ต้องปิด
      if (lastActivity is! Timestamp) {
        return false;
      }

      final lastActivityTime = lastActivity.toDate();

      final now = DateTime.now();

      final inactiveDuration =
          now.difference(lastActivityTime);

      // ถ้าไม่มี Activity ครบ 3 ชั่วโมง
      if (inactiveDuration >= inactivityLimit) {
        await endSession(sessionId);

        return true;
      }

      return false;
    } catch (e) {
      print(
        'ตรวจสอบ Auto Close Session $sessionId ไม่สำเร็จ: $e',
      );

      return false;
    }
  }

  // =====================================================
  // เปลี่ยนเป็นหลังเรียน
  // =====================================================

  Future<void> changeToAfterClass(String sessionId) async {
    await _currentSessionRef.update({
      'sessionId': sessionId,
      //'type': 'after_class',
      'status': 'active',
    });
  }

  // =====================================================
  // จบ Session
  // =====================================================

  Future<void> endSession(String sessionId) async {
    await _firestore.collection('class_sessions').doc(sessionId).update({
      'status': 'ended',
      'endTime': FieldValue.serverTimestamp(),
    });

    final currentSnapshot = await _currentSessionRef.get();

    if (currentSnapshot.exists && currentSnapshot.value != null) {
      final data = Map<String, dynamic>.from(currentSnapshot.value as Map);

      if (data['sessionId'] == sessionId) {
        await _currentSessionRef.update({'status': 'inactive'});
      }
    }
  }

  // =====================================================
  // ดึง Session ที่กำลัง Active
  // =====================================================

   // =====================================================
  // ดึง Session ที่กำลัง Active
  // พร้อมตรวจสอบ Auto Close
  // =====================================================

  Future<Map<String, dynamic>?> getActiveSession(
    String subjectCode,
  ) async {
    final snapshot = await _firestore
        .collection('class_sessions')
        .where(
          'subjectCode',
          isEqualTo: subjectCode,
        )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;

    // ตรวจสอบว่าไม่มี Activity เกิน 3 ชั่วโมงหรือไม่
    final autoClosed =
        await checkAndAutoCloseSession(doc.id);

    // ถ้าถูกปิดอัตโนมัติแล้ว
    if (autoClosed) {
      return null;
    }

    return {
      'sessionId': doc.id,
      ...doc.data(),
    };
  }

  // =====================================================
  // ดึง Session ทั้งหมดของวันที่เลือก
  // =====================================================

  Future<List<Map<String, dynamic>>> getSessionsByDate({
    required String subjectCode,
    required DateTime date,
  }) async {
    final snapshot = await _firestore
        .collection('class_sessions')
        .where('subjectCode', isEqualTo: subjectCode)
        .get();

    final sessions = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final startTime = data['startTime'];

      if (startTime == null) {
        continue;
      }

      final sessionDate = (startTime as Timestamp).toDate();

      if (sessionDate.year == date.year &&
          sessionDate.month == date.month &&
          sessionDate.day == date.day) {
        sessions.add({'sessionId': doc.id, ...data});
      }
    }

    return sessions;
  }

  // =====================================================
  // ดึง Current Session จาก Firebase RTDB
  // =====================================================

  Future<Map<String, dynamic>?> getCurrentSession() async {
    final snapshot = await _currentSessionRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }

    return Map<String, dynamic>.from(snapshot.value as Map);
  }
}
