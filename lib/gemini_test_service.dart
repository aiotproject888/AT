import 'package:firebase_ai/firebase_ai.dart';

class GeminiTestService {
  final GenerativeModel _model =
      FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.5-flash',
      );

  Future<String> test() async {
    try {
      final response = await _model.generateContent(
        [
          Content.text('ตอบเป็นภาษาไทยว่า สวัสดี'),
        ],
      );

      return response.text ?? 'ไม่มีคำตอบ';
    } catch (e) {
      return 'เกิดข้อผิดพลาด: $e';
    }
  }
}