import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';


class SubjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createSubject(Subject subject) async {
    final doc = await _firestore
        .collection('subjects')
        .doc(subject.subjectCode)
        .get();

    if (doc.exists) {
      throw Exception('รหัสวิชานี้มีอยู่แล้ว');
    }

    await _firestore.collection('subjects').doc(subject.subjectCode).set({
      'subjectName': subject.subjectName,
      'year': subject.year,
      'semester': subject.semester,
      'subjectCode': subject.subjectCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


//ดึงข้อมูลวิชา

Future<List<Subject>> getSubjects() async {
  final snapshot = await _firestore.collection('subjects').get();

  return snapshot.docs.map((doc) {
    final data = doc.data();

    return Subject(
      subjectName: data['subjectName'] ?? '',
      year: data['year'] ?? '',
      semester: data['semester'] ?? '',
      subjectCode: data['subjectCode'] ?? doc.id,
    );
  }).toList();
}
 Future<List<Map<String, dynamic>>> getEmotionData(
    String subjectCode,
  ) async {
    final snapshot = await _firestore
        .collection('emotion_records')
        .where('subjectCode', isEqualTo: subjectCode)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  
}