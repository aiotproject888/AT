import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../widgets/emotion_summary.dart';
import '../widgets/suggestion_card.dart';
import '../constants/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Color primaryColor;

  const MessageBubble({
    super.key,
    required this.message,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAI = message.isAI;

    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAI ? AppColors.surface : primaryColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // ข้อความ
            // ==================================================
            Text(
              message.text,
              style: TextStyle(
                color: isAI ? AppColors.primaryText : AppColors.onAccent,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            // ==================================================
            // Emotion Attachment
            // ==================================================
            if (message.emotionData != null) ...[
              const SizedBox(height: 10),
              EmotionSummary(
                message: message,
              ),
            ],

            // ==================================================
            // Lesson Materials
            // ==================================================
            if (message.lessonMaterials != null &&
                message.lessonMaterials!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...message.lessonMaterials!.map(
                (material) {
                  final String fileName =
                      material['fileName']?.toString() ?? 'ไฟล์การสอน';
                  final String fileType =
                      material['fileType']?.toString() ?? '';
                  final bool isPdf =
                      fileType.toLowerCase().contains('pdf') ||
                      fileName.toLowerCase().endsWith('.pdf');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isAI
                            ? AppColors.innerSurface
                            : AppColors.onAccentSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAI
                              ? AppColors.surfaceBorder
                              : AppColors.onAccentBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          // ไอคอนไฟล์
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.dangerSoftSurface,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              isPdf
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.description_rounded,
                              color: AppColors.danger,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 10),

                          // ชื่อไฟล์
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isAI
                                        ? AppColors.primaryText
                                        : AppColors.onAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isPdf
                                      ? 'PDF'
                                      : (fileType.isNotEmpty
                                            ? fileType
                                            : 'ไฟล์การสอน'),
                                  style: TextStyle(
                                    color: isAI
                                        ? AppColors.mutedText
                                        : AppColors.onAccentMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            // ==================================================
            // Chat Uploaded File
            //
            // ไฟล์ที่กดแนบจากหน้า Chat โดยตรง
            // ==================================================
            if (message.fileName != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isAI
                      ? AppColors.innerSurface
                      : AppColors.onAccentSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAI
                        ? AppColors.surfaceBorder
                        : AppColors.onAccentBorder,
                  ),
                ),
                child: Row(
                  children: [
                    // ไอคอนไฟล์
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoftSurface,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        (message.fileType ?? '').toLowerCase() == 'pdf'
                            ? Icons.picture_as_pdf_rounded
                            : Icons.insert_drive_file_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ชื่อไฟล์
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.fileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isAI
                                  ? AppColors.primaryText
                                  : AppColors.onAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            (message.fileType ?? '').toLowerCase() == 'pdf'
                                ? 'PDF'
                                : (message.fileType ?? 'ไฟล์'),
                            style: TextStyle(
                              color: isAI
                                  ? AppColors.mutedText
                                  : AppColors.onAccentMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==================================================
            // Suggestion
            // ==================================================
            if (message.suggestions != null) ...[
              const SizedBox(height: 10),
              SuggestionCard(
                message: message,
              ),
            ],

            // ==================================================
            // เวลา
            // ==================================================
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "${message.time.hour.toString().padLeft(2, '0')}:"
                "${message.time.minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  color: isAI
                      ? AppColors.lightMutedText
                      : AppColors.onAccentMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}