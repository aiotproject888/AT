import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String _backendUrl = 'https://groq-backend-yzr8.onrender.com';

  Future<String> sendMessage({
    required String message,
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? emotionData,
    String? subjectCode,
    List<Map<String, dynamic>>? lessonMaterials,

    // ใช้สำหรับ Report AI โดยเฉพาะ
    bool reportAnalysis = false,

    String model = 'gpt-oss-120b',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,

          // Chat ปกติยังส่ง history ตามเดิม
          // แต่ Report AI ฝั่ง backend จะไม่ใช้ history
          'history': history ?? [],

          'emotionData': emotionData,

          'subjectCode': subjectCode,

          'lessonMaterials': lessonMaterials ?? [],

          'model': model,

          // สำคัญสำหรับ Report AI
          'reportAnalysis': reportAnalysis,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        return data['reply']?.toString() ?? 'ไม่สามารถรับคำตอบได้';
      }

      throw Exception(
        'Backend Error: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
    }
  }
}