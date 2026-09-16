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

    // ------------------------------------------------------------
    // อ่านจำนวน responses ของแต่ละช่วง
    // ------------------------------------------------------------

    final beforeData = data['beforeClass'];
    final duringData = data['duringClass'];
    final afterData = data['afterClass'];

    final bool hasBefore = beforeData != null;
    final bool hasDuring = duringData != null;
    final bool hasAfter = afterData != null;

    int getTotalResponses(dynamic section) {
      if (section is Map) {
        final value = section['totalResponses'];

        if (value is num) {
          return value.toInt();
        }

        return int.tryParse(value?.toString() ?? '0') ?? 0;
      }

      return 0;
    }

    final int beforeResponses = getTotalResponses(beforeData);
    final int duringResponses = getTotalResponses(duringData);
    final int afterResponses = getTotalResponses(afterData);

    // ------------------------------------------------------------
    // รองรับข้อมูลแบบเก่า
    // กรณี emotionData ยังเป็นข้อมูลช่วงเดียว
    // ------------------------------------------------------------

    if (!hasBefore && !hasDuring && !hasAfter) {
      final String type =
          data['type']?.toString() ?? 'before_class';

      final int totalResponses =
          (data['totalResponses'] as num?)?.toInt() ?? 0;

      String classType;

      switch (type) {
        case 'before_class':
          classType = 'ก่อนเรียน';
          break;

        case 'during_class':
          classType = 'ระหว่างเรียน';
          break;

        case 'after_class':
          classType = 'หลังเรียน';
          break;

        default:
          classType = type;
      }

      return _buildEmotionCard(
        context,
        [
          _EmotionItem(
            title: classType,
            responses: totalResponses,
          ),
        ],
      );
    }

    // ------------------------------------------------------------
    // ข้อมูลแบบใหม่
    // แสดงเฉพาะช่วงที่มีการแนบข้อมูล
    // ------------------------------------------------------------

    final List<_EmotionItem> items = [];

    if (hasBefore) {
      items.add(
        _EmotionItem(
          title: 'ก่อนเรียน',
          responses: beforeResponses,
        ),
      );
    }

    if (hasDuring) {
      items.add(
        _EmotionItem(
          title: 'ระหว่างเรียน',
          responses: duringResponses,
        ),
      );
    }

    if (hasAfter) {
      items.add(
        _EmotionItem(
          title: 'หลังเรียน',
          responses: afterResponses,
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildEmotionCard(context, items);
  }

  Widget _buildEmotionCard(
    BuildContext context,
    List<_EmotionItem> items,
  ) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

                const SizedBox(height: 6),

                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '${item.title} · ${item.responses} responses',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
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

class _EmotionItem {
  final String title;
  final int responses;

  const _EmotionItem({
    required this.title,
    required this.responses,
  });
}