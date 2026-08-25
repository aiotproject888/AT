import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  final GenerativeModel _model;

  ChatService()
      : _model = GenerativeModel(
          model: 'gemini-3.6-flash',
          apiKey: 'AQ.Ab8RN6L6ILwQOVtGFNxXB7FJa7t3wE7APs6P5zYi2DK5ZT61IA',
        );

  Future<String> sendMessage(String message) async {
    try {
      final response = await _model.generateContent([
        Content.text(message),
      ]);

      return response.text ?? 'Gemini ไม่ได้ส่งข้อความกลับมา';
    } catch (e) {
      return 'เกิดข้อผิดพลาด: $e';
    }
  }
}