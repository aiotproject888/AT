import 'package:cloud_firestore/cloud_firestore.dart';

class ChatHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversationsRef {
    return _firestore.collection('conversations');
  }

  // สร้างข้อความใน Firestore
  Future<String> createConversation({
    required String type,
    String? subjectCode,
    String? sessionId,
    
  }) async {
    // ตรวจสอบ type
    if (type != 'general' && type != 'classroom') {
      throw Exception('type ต้องเป็น general หรือ classroom เท่านั้น');
    }

    // Classroom ต้องมี subjectCode
    if (type == 'classroom') {
      if (subjectCode == null || subjectCode.trim().isEmpty) {
        throw Exception('Chatbot แบบ classroom ต้องมี subjectCode');
      }
    }

    final conversationRef = _conversationsRef.doc();

    await conversationRef.set({
      'type': type,
      'subjectCode': subjectCode,
      'sessionId': sessionId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return conversationRef.id;
  }

  //ทำการบันทึกข้อความลงใน Firestore
  Future<void> saveMessage({
    required String conversationId,
    required String role,
    required String text,
    required String type,
    String? subjectCode,
    Map<String, dynamic>? emotionData,
    List<Map<String, dynamic>>? lesson_materials,
    String? fileName,
  }) async {
    // ไม่บันทึกข้อความว่าง
    if (text.trim().isEmpty) {
      return;
    }

    // ตรวจสอบ role
    if (role != 'user' && role != 'assistant') {
      throw Exception('role ต้องเป็น user หรือ assistant เท่านั้น');
    }

    // ตรวจสอบ type ว่าเป็นแชทบอททั่วไป หรือแชทบอทในห้องเรียน
    if (type != 'general' && type != 'classroom') {
      throw Exception('type ต้องเป็น general หรือ classroom เท่านั้น');
    }

    //แชทบอทในห้องเรียนกจะมีรหัสห้องเรียนมาด้วย
    if (type == 'classroom') {
      if (subjectCode == null || subjectCode.trim().isEmpty) {
        throw Exception('Classroom Chat ต้องมี subjectCode');
      }
    }

    // สร้าง message
    final messageRef = _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'role': role,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),

      'emotionData': emotionData,
      'lessonMaterials': lesson_materials ?? [],

    });

    // อัปเดตเวลาของ conversation
    await _conversationsRef.doc(conversationId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ดึงข้อความบทสนทนา
  // classroom สามารถกรองด้วย subjectCode ได้
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getConversations({
    required String type,
    String? subjectCode,
  }) async {
    if (type != 'general' && type != 'classroom') {
      throw Exception('type ต้องเป็น general หรือ classroom เท่านั้น');
    }

    Query<Map<String, dynamic>> query = _conversationsRef.where(
      'type',
      isEqualTo: type,
    );

    // Classroom สามารถกรองตามรหัสห้อง
    if (type == 'classroom') {
      if (subjectCode == null || subjectCode.trim().isEmpty) {
        throw Exception('Classroom Chat ต้องมี subjectCode');
      }

      query = query.where('subjectCode', isEqualTo: subjectCode);
    }

    final snapshot = await query.orderBy('updatedAt', descending: true).get();

    return snapshot.docs;
  }

  // ============================================================
  // GET MESSAGES
  // ============================================================
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getMessages({
    required String conversationId,
    required String type,
    String? subjectCode,
  }) async {
    if (type != 'general' && type != 'classroom') {
      throw Exception('type ต้องเป็น general หรือ classroom เท่านั้น');
    }

    if (type == 'classroom') {
      if (subjectCode == null || subjectCode.trim().isEmpty) {
        throw Exception('Classroom Chat ต้องมี subjectCode');
      }
    }

    final snapshot = await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .get();

    return snapshot.docs;
  }

  ///////////////////////ดึงข้อมูลบทสนทนาก่อนหน้า
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getPreviousConversations({
    required String type,
    String? subjectCode,
    int limit = 3, //ตั้งไว้3 เพื่อดึง ล่าสุด ก่อนหน้าและอีกก่อนหน้า
  }) async {
    if (type != 'general' && type != 'classroom') {
      throw Exception('type ต้องเป็น general หรือ classroom เท่านั้น');
    }

    Query<Map<String, dynamic>> query = _conversationsRef.where(
      'type',
      isEqualTo: type,
    );

    if (type == 'classroom') {
      if (subjectCode == null || subjectCode.trim().isEmpty) {
        throw Exception('Classroom Chat ต้องมี subjectCode');
      }

      query = query.where('subjectCode', isEqualTo: subjectCode);
    }

    final snapshot = await query
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs;
  }

  // MESSAGES STREAM
  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream({
    required String conversationId,
    required String type,
    String? subjectCode,
  }) {
    if (type != 'general' && type != 'classroom') {
      throw Exception('type ต้องเป็น general หรือ classroom เท่านั้น');
    }

    if (type == 'classroom') {
      if (subjectCode == null || subjectCode.trim().isEmpty) {
        throw Exception('Classroom Chat ต้องมี subjectCode');
      }
    }

    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  // ============================================================
  // CONVERSATIONS STREAM
  // ============================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> conversationsStream({
    required String type,
    String? subjectCode,
  }) {
    if (type != 'general' && type != 'classroom') {
      throw Exception('type ต้องเป็น general หรือ classroom เท่านั้น');
    }

    Query<Map<String, dynamic>> query = _conversationsRef.where(
      'type',
      isEqualTo: type,
    );

    if (type == 'classroom') {
      if (subjectCode == null || subjectCode.trim().isEmpty) {
        throw Exception('Classroom Chat ต้องมี subjectCode');
      }

      query = query.where('subjectCode', isEqualTo: subjectCode);
    }

    return query.orderBy('updatedAt', descending: true).snapshots();
  }
}
