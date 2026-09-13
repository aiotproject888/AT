import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class SuggestionCard extends StatelessWidget {
  final ChatMessage message;

  const SuggestionCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final List suggestions = message.suggestions ?? [];

    return Column(
      children: List.generate(suggestions.length, (index) {
        final item = suggestions[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item["icon"] ?? Icons.lightbulb_outline,
                color: Colors.white,
                size: 18,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["title"] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      item["desc"] ?? "",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}