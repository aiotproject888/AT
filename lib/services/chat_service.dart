import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {

  static const String baseUrl = "http://localhost:11434";

  Future<String> sendMessage(String prompt) async {

    final response = await http.post(
      Uri.parse("$baseUrl/api/generate"),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "model": "qwen3:4b",
        "prompt": prompt,
        "stream": false,
        "keep_alive":"1h"
      }),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return data["response"] ?? "AI ไม่ได้ตอบกลับ";

    } else {

      throw Exception(
        "Ollama Error ${response.statusCode}\n${response.body}",
      );

    }

  }

}