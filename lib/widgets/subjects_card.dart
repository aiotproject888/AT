import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../screens/subjects_dashboard.dart';
import '../widgets/emotion_card.dart';

class _SubjectCardColors {
  static const card = Color(0xBF23222F);
  static const cardBorder = Color(0x40FFFFFF);
  static const summary = Color(0xFF292733);
  static const primaryText = Color(0xFFFFFFFF);
  static const secondaryText = Color(0x99FFFFFF);
  static const faintText = Color(0x59FFFFFF);
  static const accent = Color(0xFF6C52E5);
  static const statusBackground = Color(0x3324B47E);
  static const statusText = Color(0xFF54C99A);
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(19),
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _SubjectCardColors.card,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: _SubjectCardColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ส่วนบนของ Card
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
                top: Radius.circular(19),
              ),
              splashColor: _SubjectCardColors.accent.withOpacity(0.12),
              highlightColor: Colors.white.withOpacity(0.025),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
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
                                  fontWeight: FontWeight.w500,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${subject.subjectCode}  ${subject.year}  เทอม ${subject.semester}',
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

                        /// สถานะ
                        if (isActive)
                          Container(
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _SubjectCardColors.statusBackground,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              '🟢 กำลังสอน',
                              style: TextStyle(
                                color: _SubjectCardColors.statusText,
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                height: 1,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// ส่วนแสดงอารมณ์
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 82),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _SubjectCardColors.summary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: EmotionSummaryWidget(subjectCode: subject.subjectCode,),
                    ),
                  ],
                ),
              ),
            ),

            /// Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ดูรายละเอียด',
                            style: TextStyle(
                              color: _SubjectCardColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
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
