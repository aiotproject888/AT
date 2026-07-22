import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/emotion_service.dart';
import '../services/session_service.dart';

class SubjectDashboard extends StatefulWidget {
  final Subject subject;

  const SubjectDashboard({super.key, required this.subject});

  @override
  State<SubjectDashboard> createState() => _SubjectDashboardState();
}

class _SubjectDashboardState extends State<SubjectDashboard> {
  final EmotionService _emotionService = EmotionService();

  final SessionService _sessionService = SessionService();

  int studentCount = 0;
  int positivePercentage = 0;

  String? _sessionId;

  bool _isClassActive = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _loadEmotionData();
  }

  static const Color backgroundColor = Color(0xff0F0D1A);
  static const Color cardColor = Color(0xff19162A);
  static const Color chartColor = Color(0xff211D35);
  static const Color purple = Color(0xff7C5CFC);
  static const Color blue = Color(0xff4F8CFF);
  static const Color pink = Color(0xffD66BFF);

  Future<void> _loadEmotionData() async {
    final students = await _emotionService.getStudentCount();

    final positive = await _emotionService.getPositivePercentage();

    setState(() {
      studentCount = students;
      positivePercentage = positive;
    });
  }

  Future<void> _startClassroom() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessionId = await _sessionService.startSession(
        subjectCode: widget.subject.subjectCode,
      );

      setState(() {
        _sessionId = sessionId;
        _isClassActive = true;
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปิดห้องเรียนเรียบร้อยแล้ว')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่สามารถเปิดห้องเรียนได้: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // =========================
      // App Bar
      // =========================
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
        ),

        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.white70,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // Body
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xff21194A), Color(0xff141126), backgroundColor],
          ),
        ),

        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Header
              _subjectCard(),

              const SizedBox(height: 20),

              // Dashboard Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ภาพรวมอารมณ์ของนักศึกษา",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 4),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // =========================
              // Emotion Dashboard
              // =========================
              SizedBox(
                height: 580,

                child: PageView(
                  children: [
                    _emotionCard("ก่อนเรียน"),
                    _emotionCard("หลังเรียน"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // AI Recommendation
              _aiRecommendation(),
            ],
          ),
        ),
      ),
    );
  }

  // Subject Card

  Widget _subjectCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff30256B), Color(0xff1B1830)],
        ),

        border: Border.all(color: Colors.white.withOpacity(0.08)),

        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.12),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),

                child: const Icon(
                  Icons.school_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ข้อมูลรายวิชา",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),

                    SizedBox(height: 3),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Subject Name
          Text(
            widget.subject.subjectName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          // Information
          Row(
            children: [
              _infoItem(Icons.tag, widget.subject.subjectCode),

              const SizedBox(width: 20),

              _infoItem(Icons.school_outlined, "ปี ${widget.subject.year}"),

              const SizedBox(width: 20),

              _infoItem(
                Icons.calendar_month_outlined,
                "เทอม ${widget.subject.semester}",
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Info Item
  // =====================================================

  Widget _infoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),

          const SizedBox(width: 6),

          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Emotion Card
  // =====================================================

  Widget _emotionCard(String title) {
    return Container(
      margin: const EdgeInsets.only(right: 5),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: Colors.white.withOpacity(0.06)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================
          // Header
          // =========================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),

                decoration: BoxDecoration(
                  color: purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Icon(
                  Icons.mood_outlined,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Summary
          Row(
            children: [
              _summaryItem(
                "Students",
                studentCount.toString(),
                Icons.people_outline,
              ),

              const SizedBox(width: 10),

              _summaryItem(
                "Positive",
                "$positivePercentage%",
                Icons.sentiment_satisfied_alt_outlined,
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Doughnut Chart
          Expanded(
            child: Container(
              width: double.infinity,

              decoration: BoxDecoration(
                color: chartColor,
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(Icons.donut_large, color: Colors.white38, size: 50),

                    SizedBox(height: 10),

                    Text(
                      "Doughnut Chart",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // =========================
          // Bar Chart
          // =========================
          Expanded(
            child: Container(
              width: double.infinity,

              decoration: BoxDecoration(
                color: chartColor,
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(Icons.bar_chart, color: Colors.white38, size: 50),

                    SizedBox(height: 10),

                    Text(
                      "Emotion Distribution",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Summary Item
  // =====================================================

  Widget _summaryItem(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: chartColor,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Row(
          children: [
            Icon(icon, color: purple, size: 22),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // AI Recommendation
  // =====================================================

  Widget _aiRecommendation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [purple.withOpacity(0.25), pink.withOpacity(0.12), cardColor],
        ),

        border: Border.all(color: purple.withOpacity(0.25)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),

                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    "AI Recommendation",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 3),

                  Text(
                    "Smart teaching insights",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Text(
            "วิเคราะห์ข้อมูลอารมณ์ของนักศึกษา เพื่อช่วยแนะนำเทคนิคและแนวทางในการจัดการเรียนการสอนที่เหมาะสม",
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,

            child: ElevatedButton.icon(
              onPressed: () {},

              icon: const Icon(Icons.auto_awesome, size: 20),

              label: const Text(
                "Analyze Emotion Data",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // build...

  // Colors
}
