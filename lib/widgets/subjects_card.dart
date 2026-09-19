import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/subject.dart';
import '../screens/subjects_dashboard.dart';
import '../widgets/emotion_card.dart';

class _SubjectCardColors {
  // Card
  static const card = AppColors.surface;
  static const cardBorder = AppColors.surfaceBorder;

  // กล่องสรุปอารมณ์
  static const summary = AppColors.lightSurface;

  // Text
  static const primaryText = AppColors.primaryText;
  static const secondaryText = AppColors.lightSecondaryText;

  // Brand
  static const accent = AppColors.accent;

  // Status
  static const statusBackground = AppColors.greenSurface;
  static const statusText = AppColors.greenText;
}

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final bool isActive;
  final Future<void> Function()? onReturn;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.isActive,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _SubjectCardColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _SubjectCardColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: AppColors.navigationShadow,
              offset: Offset(0, 7),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนบนของ Card
            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubjectDashboard(subject: subject),
                  ),
                );

                if (context.mounted) {
                  await onReturn?.call();
                }
              },
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              splashColor: _SubjectCardColors.accent.withOpacity(0.12),
              highlightColor: _SubjectCardColors.accent.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 17, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.subjectName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _SubjectCardColors.primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${subject.subjectCode} • ปีการศึกษา ${subject.year} • ภาคเรียนที่ ${subject.semester}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _SubjectCardColors.secondaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // สถานะ
                        if (isActive)
                          Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _SubjectCardColors.statusBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '🟢 กำลังสอน',
                              style: TextStyle(
                                color: _SubjectCardColors.statusText,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                height: 1,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ส่วนแสดงอารมณ์
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 88),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _SubjectCardColors.summary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.lightSurfaceBorder,
                        ),
                      ),
                      child: EmotionSummaryWidget(
                        subjectCode: subject.subjectCode,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 12, 10),
              child: Row(
                children: [
                  const SizedBox(width: 5),
                  const Spacer(),
                  InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubjectDashboard(subject: subject),
                        ),
                      );

                      if (context.mounted) {
                        await onReturn?.call();
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ดูรายละเอียด',
                            style: TextStyle(
                              color: _SubjectCardColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward,
                            color: _SubjectCardColors.accent,
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}