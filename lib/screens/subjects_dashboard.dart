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

  DateTime? _selectedDate;
  List<Map<String, dynamic>> _selectedSessions = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();

    _loadActiveSession();
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

  Future<void> _endClassroom() async {
    if (_sessionId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _sessionService.endSession(_sessionId!);

      setState(() {
        _isClassActive = false;
        _sessionId = null;
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ปิดห้องเรียนเรียบร้อยแล้ว')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่สามารถปิดห้องเรียนได้: $e')));
    }
  }

  Future<void> _loadActiveSession() async {
    try {
      final session = await _sessionService.getActiveSession(
        widget.subject.subjectCode,
      );

      if (!mounted) return;

      if (session != null) {
        setState(() {
          _sessionId = session['sessionId'];

          _isClassActive = true;
        });

        await _loadEmotionData();
      } else {
        setState(() {
          _sessionId = null;
          _isClassActive = false;
        });
      }
    } catch (e) {
      debugPrint('ไม่สามารถโหลด Session ได้: $e');
    }
  }

  //ฟังก์ชันวันที่
  Future<void> _selectDate() async {
    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _thaiCalendarBottomSheet();
      },
    );

    if (pickedDate == null) {
      return;
    }

    await _loadSessionsByDate(pickedDate);
  }

  Future<void> _loadSessionsByDate(DateTime date) async {
    setState(() {
      _isLoadingHistory = true;
      _selectedDate = date;
    });

    try {
      final sessions = await _sessionService.getSessionsByDate(
        subjectCode: widget.subject.subjectCode,
        date: date,
      );

      if (!mounted) return;

      setState(() {
        _selectedSessions = sessions;
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingHistory = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถโหลดข้อมูลย้อนหลังได้: $e')),
      );
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
            onPressed: _selectDate,
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
              // ไอคอนรายวิชา
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

              // ปุ่ม Active Classroom
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : (_isClassActive ? _endClassroom : _startClassroom),

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),

                  width: 58,
                  height: 32,

                  padding: const EdgeInsets.all(4),

                  decoration: BoxDecoration(
                    color: _isClassActive
                        ? Colors.green
                        : Colors.white.withOpacity(0.12),

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(
                      color: _isClassActive
                          ? Colors.greenAccent
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),

                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),

                    alignment: _isClassActive
                        ? Alignment.centerRight
                        : Alignment.centerLeft,

                    child: Container(
                      width: 24,
                      height: 24,

                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),

                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isClassActive
                                  ? Icons.play_arrow
                                  : Icons.power_settings_new,
                              size: 14,
                              color: _isClassActive ? purple : Colors.black54,
                            ),
                    ),
                  ),
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

  // Selected Date Card
  Widget _thaiCalendarBottomSheet() {
    DateTime selectedDate = _selectedDate ?? DateTime.now();

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),

          decoration: const BoxDecoration(
            color: Color(0xff19162A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // =========================
              // Drag Handle
              // =========================
              Container(
                width: 45,
                height: 5,

                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // Header
              // =========================
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,

                    decoration: BoxDecoration(
                      color: purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'เลือกวันที่',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        'ดูข้อมูลการเรียนย้อนหลัง',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // =========================
              // Selected Date
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      purple.withOpacity(0.25),
                      purple.withOpacity(0.08),
                    ],
                  ),

                  borderRadius: BorderRadius.circular(16),

                  border: Border.all(color: purple.withOpacity(0.25)),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),

                    const SizedBox(width: 10),

                    Text(
                      _formatThaiDate(selectedDate),

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // Calendar
              // =========================
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xff7C5CFC),
                    surface: Color(0xff19162A),
                  ),
                ),

                child: CalendarDatePicker(
                  initialDate: selectedDate,

                  firstDate: DateTime(2020),

                  lastDate: DateTime.now(),

                  onDateChanged: (date) {
                    setModalState(() {
                      selectedDate = date;
                    });
                  },
                ),
              ),

              const SizedBox(height: 10),

              // =========================
              // Buttons
              // =========================
              Row(
                children: [
                  // วันนี้
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          selectedDate = DateTime.now();
                        });
                      },

                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,

                        side: BorderSide(color: Colors.white.withOpacity(0.15)),

                        padding: const EdgeInsets.symmetric(vertical: 14),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      child: const Text('ยกเลิก'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // เลือกวันที่
                  Expanded(
                    flex: 2,

                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, selectedDate);
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,

                        foregroundColor: Colors.white,

                        elevation: 0,

                        padding: const EdgeInsets.symmetric(vertical: 14),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      child: const Text(
                        'ดูข้อมูล',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatThaiDate(DateTime date) {
    const months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];

    final thaiYear = date.year + 543;

    return '${date.day} '
        '${months[date.month - 1]} '
        '$thaiYear';
  }
  // build...

  // Colors
}
