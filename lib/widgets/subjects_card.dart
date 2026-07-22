import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../screens/subjects_dashboard.dart';
import '../widgets/emotion_card.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;

  const SubjectCard({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SubjectDashboard(subject: subject)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),

          gradient: LinearGradient(
            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            colors: [
              Colors.white.withOpacity(.09),

              Colors.white.withOpacity(.03),
            ],
          ),

          border: Border.all(color: Colors.white10),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// แถวบน
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.subjectName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${subject.subjectCode} ปี${subject.year} เทอม${subject.semester}",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// ส่วนแสดงอารมณ์
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xff363344),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const EmotionSummaryWidget(),
            ),
            const SizedBox(height: 10),

            /// แถวล่าง
            Row(
              children: [
                const SizedBox(width: 8),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectDashboard(subject: subject),
                      ),
                    );
                  },
                  child: const Text(
                    "ดูรายละเอียด",
                    style: TextStyle(color: Colors.deepPurpleAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
