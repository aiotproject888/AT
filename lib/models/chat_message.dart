class ChatMessage {
  final bool isAI;
  final String text;
  final DateTime time;

  final String? fileName;
  final String? fileType;

  final Map<String, dynamic>? emotionData;

  // ไฟล์การสอนที่แนบกับข้อความ
  final List<Map<String, dynamic>>? lessonMaterials;

  final String? type;
  final List<dynamic>? emotions;
  final List<dynamic>? suggestions;

  ChatMessage({
    required this.isAI,
    required this.text,
    required this.time,
    this.fileName,
    this.fileType,
    this.emotionData,
    this.lessonMaterials,
    this.type,
    this.emotions,
    this.suggestions,
  });
}