import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';

class SubjectService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> createSubject(Subject subject) async {
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
}