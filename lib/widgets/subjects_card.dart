import 'package:flutter/material.dart';
import '../models/subjects.dart';
import '../screens/subjects_dashboard.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;

  const SubjectCard({
    super.key,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectDashboard(
              subject: subject,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xff2B2939),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white24,
          ),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "กำลังสอน",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// การ์ดสรุปอารมณ์
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xff363344),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "😊",
                          style: TextStyle(fontSize: 45),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "สนใจ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "40% มากที่สุด",
                          style: TextStyle(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: .27,
                        ),
                        SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: .20,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: .13,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// แถวล่าง
            Row(
              children: [
                const Icon(
                  Icons.groups_outlined,
                  color: Colors.white54,
                ),
                const SizedBox(width: 8),
                const Text(
                  "0/0 คนตอบวันนี้",
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectDashboard(
                          subject: subject,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "ดูรายละเอียด",
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                    ),
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