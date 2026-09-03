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
    final data = message.emotionData;

    if (data == null) {
      return const SizedBox.shrink();
    }

    final String type =
        data['type']?.toString() ?? 'before_class';

    final String date =
        data['date']?.toString() ?? '';

    final int totalResponses =
        (data['totalResponses'] as num?)?.toInt() ?? 0;

    final String classType =
        type == 'before_class'
            ? 'ก่อนเรียน'
            : type == 'after_class'
                ? 'หลังเรียน'
                : type;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF6C52E5).withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFF9B87FF),
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อมูลอารมณ์',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '$classType'
                  '${date.isNotEmpty ? ' • $date' : ''}'
                  ' • $totalResponses responses',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}