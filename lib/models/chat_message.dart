class ChatMessage {
  final bool isAI;
  final String text;
  final DateTime time;
  final String? fileName;

  final String? type;
  final List<dynamic>? emotions;
  final List<dynamic>? suggestions;

  ChatMessage({
    required this.isAI,
    required this.text,
    required this.time,
    this.fileName,
    this.type,
    this.emotions,
    this.suggestions,
  });
}