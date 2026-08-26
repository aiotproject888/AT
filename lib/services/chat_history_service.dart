import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // UID ของผู้ใช้ปัจจุบัน
  String get uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('ยังไม่มีผู้ใช้ที่เข้าสู่ระบบ');
    }

    return user.uid;
  }

  //  ไปยังแชทที่คุยของผู้ใช้
  // users/{uid}/conversations

  CollectionReference<Map<String, dynamic>> get _conversationsRef {
    return _firestore.collection('users').doc(uid).collection('conversations');
  }

  // สร้างบทสนทนาใหม่
  Future<String> createConversation({
    required String type,
    String? subjectCode,
    String? sessionId,
    String? title,
  }) async {
    // ตรวจสอบประเภทว่าเข้าจากเมนูหรือห้องเรียน
    if (type != 'general' && type != 'classroom') {
      throw Exception('type ต้องเป็น general หรือ classroom เท่านั้น');
    }

    // ถ้าเป็น classroom ต้องมีข้อมูลห้องเรียน
    if (type == 'classroom') {
      if (subjectCode == null || subjectCode.isEmpty) {
        throw Exception('Chatbot แบบ classroom ต้องมี subjectCode');
      }

      if (sessionId == null || sessionId.isEmpty) {
        throw Exception('Chatbot แบบ classroom ต้องมี sessionId');
      }
    }

    // สร้าง document ID อัตโนมัติ
    final conversationRef = _conversationsRef.doc();

    await conversationRef.set({
      'type': type,

      'subjectCode': subjectCode,
      'sessionId': sessionId,

      // ถ้าไม่ได้ส่งชื่อมา ใช้ชื่อเริ่มต้น
      'title': title ?? 'การสนทนาใหม่',

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return conversationRef.id;
  }

  // ส่วนบันทึกข้อความ
  Future<void> saveMessage({
    required String conversationId,
    required String role,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }

    if (role != 'user' && role != 'assistant') {
      throw Exception('role ต้องเป็น user หรือ assistant เท่านั้น');
    }

    // สร้าง message ใหม่
    final messageRef = _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'role': role,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // อัปเดตเวลาของ conversation
    await _conversationsRef.doc(conversationId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // อัปเดตชื่อบทสนทนา
  Future<void> updateConversationTitle({
    required String conversationId,
    required String title,
  }) async {
    await _conversationsRef.doc(conversationId).update({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ดึงรายการบทสนทนาทั้งหมด
  // เรียงจากล่าสุด -> เก่าสุด

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getConversations() async {
    final snapshot = await _conversationsRef
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs;
  }

  // ดึงข้อความทั้งหมดในบทสนทนา
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getMessages(
    String conversationId,
  ) async {
    final snapshot = await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .get();

    return snapshot.docs;
  }

  // Stream ข้อความ ใช้กรณีอยากให้หน้า Chat อัปเดตแบบ realtime
  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(
    String conversationId,
  ) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  // Stream บทสนทนา ใช้กรณีอยากให้หน้า Chat History อัปเดตแบบ realtime
  Stream<QuerySnapshot<Map<String, dynamic>>> conversationsStream() {
    return _conversationsRef.orderBy('updatedAt', descending: true).snapshots();
  }
}
