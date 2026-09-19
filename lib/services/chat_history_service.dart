import 'package:cloud_firestore/cloud_firestore.dart';

class ChatHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // ALL CONVERSATIONS
  //
  // conversations/{conversationId}
  //
  // ใช้ร่วมกันทั้ง:
  // - General Chat
  // - Classroom Chat
  // ============================================================
  CollectionReference<Map<String, dynamic>> get _conversationsRef {
    return _firestore.collection('conversations');
  }

  // ============================================================
  // CREATE CONVERSATION
  // ============================================================
  Future<String> createConversation({
    required String type,
    String? subjectCode,
    String? sessionId,
    String? title,
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
      'title': title ?? 'การสนทนาใหม่',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return conversationRef.id;
  }

  // ============================================================
  // SAVE MESSAGE
  // ============================================================
  Future<void> saveMessage({
    required String conversationId,
    required String role,
    required String text,
    required String type,
    String? subjectCode,
  }) async {
    // ไม่บันทึกข้อความว่าง
    if (text.trim().isEmpty) {
      return;
    }

    // ตรวจสอบ role
    if (role != 'user' && role != 'assistant') {
      throw Exception('role ต้องเป็น user หรือ assistant เท่านั้น');
    }

    // ตรวจสอบ type
    if (type != 'general' && type != 'classroom') {
      throw Exception('type ต้องเป็น general หรือ classroom เท่านั้น');
    }

    // Classroom ต้องมี subjectCode
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
    });

    // อัปเดตเวลาของ conversation
    await _conversationsRef.doc(conversationId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // UPDATE CONVERSATION TITLE
  // ============================================================
  Future<void> updateConversationTitle({
    required String conversationId,
    required String title,
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

    await _conversationsRef.doc(conversationId).update({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // GET CONVERSATIONS
  //
  // type:
  // - general
  // - classroom
  //
  // classroom สามารถกรองด้วย subjectCode ได้
  // ============================================================
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getConversations({
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

      query = query.where(
        'subjectCode',
        isEqualTo: subjectCode,
      );
    }

    final snapshot = await query
        .orderBy('updatedAt', descending: true)
        .get();

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

  // ============================================================
  // MESSAGES STREAM
  // ============================================================
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

      query = query.where(
        'subjectCode',
        isEqualTo: subjectCode,
      );
    }

    return query
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
}