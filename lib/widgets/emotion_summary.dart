import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class EmotionSummary extends StatelessWidget {
  final ChatMessage message;

  const EmotionSummary({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final List emotions = message.emotions ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(emotions.length, (index) {
        final emotion = emotions[index];

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emotion["emoji"] ?? "",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 6),
              Text(
                emotion["label"] ?? "",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                emotion["value"] ?? "",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}