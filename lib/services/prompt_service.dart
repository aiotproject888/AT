class PromptService {

  static String buildPrompt({
    required Map emotionData,
    required String question,
  }) {

    return """
คุณคือผู้ช่วยครูชื่อ EmotiTeach AI

ข้อมูลอารมณ์ของห้องเรียน

$emotionData

คำถามของครู

$question

ตอบเป็นภาษาไทย

อธิบายอย่างสุภาพ กระชับ และให้คำแนะนำที่สามารถนำไปใช้ได้จริง

ไม่ต้องตอบเป็น JSON
""";

  }
}