import 'package:flutter/material.dart';
import '../models/subjects.dart';

class SubjectDashboard extends StatelessWidget {
  final Subject subject;

  const SubjectDashboard({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1E1B2E),

      appBar: AppBar(
        backgroundColor: const Color(0xff1A1233),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.calendar_month,
              color: Colors.white,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ข้อมูลรายวิชา
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Color(0xff2A2348),
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  const Text(
                    "ข้อมูลรายวิชา",
                    style: TextStyle(color: Colors.white54),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    subject.subjectName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "รหัสวิชา : ${subject.subjectCode}",
                    style: const TextStyle(color: Colors.white70),
                  ),

                  Text(
                    "ชั้นปี : ${subject.year}",
                    style: const TextStyle(color: Colors.white70),
                  ),

                  Text(
                    "ภาคเรียน : ${subject.semester}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 560,
              child: PageView(
                children: [
                  _emotionCard("ก่อนเรียน"),
                  _emotionCard("หลังเรียน"),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Color(0xff3B345A),
                borderRadius: BorderRadius.circular(20),
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Recommendation",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 15),

                  Text(
                    "เมื่อมีการเชื่อมต่อ AI ระบบจะแสดงคำแนะนำในการจัดการเรียนการสอนจากผลการประเมินอารมณ์ของนักศึกษา",
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emotionCard(String title) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xff2B2939),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xff363344),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text(
                "Doughnut Chart",
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xff363344),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text(
                "Bar Chart",
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
