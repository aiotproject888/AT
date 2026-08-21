import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/chat'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'];
    }

    throw Exception('ไม่สามารถเชื่อมต่อ AI ได้');
  }
}