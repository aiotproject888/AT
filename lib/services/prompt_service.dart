class PromptService {

  // มีข้อมูล Emotion
  static String buildPrompt({
    required Map<String, dynamic> emotionData,
    required String question,
  }) {
    return '''
คุณเป็นผู้ช่วยด้านการเรียนการสอน

ข้อมูลอารมณ์ของนักเรียน:
$emotionData

คำถามของอาจารย์:
$question

โปรดวิเคราะห์ข้อมูลที่เกี่ยวข้องกับคำถาม
และตอบคำถามให้เหมาะสมกับอาจารย์ผู้สอน
''';
  }


  // Chatbot ทั่วไป
  static String buildNormalPrompt({
    required String question,
  }) {
    return '''
คุณเป็นผู้ช่วยด้านการเรียนการสอน

คำถามของอาจารย์:
$question

โปรดตอบคำถามอย่างเข้าใจง่าย
และให้ข้อมูลที่เป็นประโยชน์ต่อการเรียนการสอน
''';
  }
}