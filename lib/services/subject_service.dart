import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/subject.dart';

class SubjectService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final DatabaseReference _emotionRef =
      FirebaseDatabase.instance.ref('emotion_data');

  final DatabaseReference _currentSessionRef =
      FirebaseDatabase.instance.ref('current_session');

  // ============================================================
  // เพิ่มรายวิชา
  // ============================================================

  Future<void> createSubject(Subject subject) async {
    final doc = await _firestore
        .collection('subjects')
        .doc(subject.subjectCode)
        .get();

    if (doc.exists) {
      throw Exception('รหัสวิชานี้มีอยู่แล้ว');
    }

    await _firestore
        .collection('subjects')
        .doc(subject.subjectCode)
        .set({
      'subjectName': subject.subjectName,
      'year': subject.year,
      'semester': subject.semester,
      'subjectCode': subject.subjectCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // แก้ไขรายวิชา
  // ============================================================

  Future<void> updateSubject({
    required String oldCode,
    required Subject newSubject,
  }) async {
    final subjects =
        _firestore.collection('subjects');

    // ----------------------------------------------------------
    // ถ้าเปลี่ยนรหัสวิชา
    // ----------------------------------------------------------

    if (oldCode != newSubject.subjectCode) {
      // ตรวจสอบว่ารหัสใหม่มีอยู่แล้วหรือไม่
      final newDoc = await subjects
          .doc(newSubject.subjectCode)
          .get();

      if (newDoc.exists) {
        throw Exception('รหัสวิชานี้มีอยู่แล้ว');
      }

      // 1. เปลี่ยนข้อมูลรายวิชา
      await subjects
          .doc(newSubject.subjectCode)
          .set({
        'subjectName': newSubject.subjectName,
        'year': newSubject.year,
        'semester': newSubject.semester,
        'subjectCode': newSubject.subjectCode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. เปลี่ยน Session
      final sessions = await _firestore
          .collection('class_sessions')
          .where(
            'subjectCode',
            isEqualTo: oldCode,
          )
          .get();

      for (final session in sessions.docs) {
        await session.reference.update({
          'subjectCode':
              newSubject.subjectCode,
        });
      }

      // 3. เปลี่ยน Emotion
      await _moveEmotionData(
        oldCode,
        newSubject.subjectCode,
      );

      // 4. เปลี่ยน Current Session
      await _updateCurrentSession(
        oldCode,
        newSubject.subjectCode,
      );

      // 5. ลบรายวิชาเดิม
      await subjects
          .doc(oldCode)
          .delete();
    }

    // ----------------------------------------------------------
    // ถ้าไม่ได้เปลี่ยนรหัสวิชา
    // ----------------------------------------------------------

    else {
      await subjects
          .doc(oldCode)
          .update({
        'subjectName': newSubject.subjectName,
        'year': newSubject.year,
        'semester': newSubject.semester,
      });
    }
  }

  // ============================================================
  // ย้าย Emotion จากรหัสเก่า → รหัสใหม่
  // ============================================================

  Future<void> _moveEmotionData(
    String oldCode,
    String newCode,
  ) async {
    final oldSnapshot =
        await _emotionRef
            .child(oldCode)
            .get();

    if (!oldSnapshot.exists ||
        oldSnapshot.value == null) {
      return;
    }

    final data =
        Map<String, dynamic>.from(
      oldSnapshot.value as Map,
    );

    // เปลี่ยน subjectCode ที่อยู่ในแต่ละ record
    for (final typeData
        in data.entries) {
      if (typeData.value is! Map) {
        continue;
      }

      final records =
          Map<String, dynamic>.from(
        typeData.value as Map,
      );

      for (final record
          in records.entries) {
        if (record.value is! Map) {
          continue;
        }

        final recordData =
            Map<String, dynamic>.from(
          record.value as Map,
        );

        recordData['subjectCode'] =
            newCode;

        records[record.key] =
            recordData;
      }

      data[typeData.key] = records;
    }

    // บันทึกข้อมูลไว้ใต้รหัสใหม่
    await _emotionRef
        .child(newCode)
        .set(data);

    // ลบข้อมูลรหัสเก่า
    await _emotionRef
        .child(oldCode)
        .remove();
  }

  // ============================================================
  // เปลี่ยน Current Session
  // ============================================================

  Future<void> _updateCurrentSession(
    String oldCode,
    String newCode,
  ) async {
    final snapshot =
        await _currentSessionRef.get();

    if (!snapshot.exists ||
        snapshot.value == null) {
      return;
    }

    final data =
        Map<String, dynamic>.from(
      snapshot.value as Map,
    );

    if (data['subjectCode'] == oldCode) {
      await _currentSessionRef.update({
        'subjectCode': newCode,
      });
    }
  }

  // ============================================================
  // ลบรายวิชา
  // ============================================================

  Future<void> deleteSubject(
    String subjectCode,
  ) async {
    await _firestore
        .collection('subjects')
        .doc(subjectCode)
        .delete();
  }

  // ============================================================
  // ดึงข้อมูลวิชา
  // ============================================================

  Future<List<Subject>> getSubjects() async {
    final snapshot =
        await _firestore
            .collection('subjects')
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Subject(
        subjectName:
            data['subjectName'] ?? '',
        year:
            data['year'] ?? '',
        semester:
            data['semester'] ?? '',
        subjectCode:
            data['subjectCode'] ??
                doc.id,
      );
    }).toList();
  }

  // ============================================================
  // ดึง Emotion Data
  // ============================================================

  Future<List<Map<String, dynamic>>>
      getEmotionData(
    String subjectCode,
  ) async {
    final snapshot =
        await _firestore
            .collection('emotion_records')
            .where(
              'subjectCode',
              isEqualTo: subjectCode,
            )
            .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }
}