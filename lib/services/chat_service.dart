import 'package:firebase_ai/firebase_ai.dart';

class ChatService {
  final GenerativeModel _model =
      FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash',
  );

  Future<String> sendMessage(String prompt) async {
    try {
      final response = await _model.generateContent(
        [
          Content.text(prompt),
        ],
      );

      return response.text ?? "AI ไม่ได้ตอบกลับ";
    } catch (e) {
      throw Exception("Gemini Error: $e");
    }
  }
}