import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String _backendUrl =
      'https://groq-backend-yzr8.onrender.com';

  Future<String> sendMessage({
    required String message,
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? emotionData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'history': history ?? [],
          'emotionData': emotionData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['reply'] ?? 'ไม่สามารถรับคำตอบได้';
      } else {
        throw Exception(
          'Backend Error: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
    }
  }
}