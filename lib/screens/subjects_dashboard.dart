import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

import '../models/subject.dart';
import '../services/emotion_service.dart';
import '../widgets/emotion_card.dart';
import '../services/session_service.dart';
import '../screens/chat.dart';

class SubjectDashboard extends StatefulWidget {
  final Subject subject;

  const SubjectDashboard({super.key, required this.subject});

  @override
  State<SubjectDashboard> createState() => _SubjectDashboardState();
}

class _SubjectDashboardState extends State<SubjectDashboard> {
  ////
  double _getEmotionScore(String emotion) {
    switch (emotion) {
      case 'รู้สึกสนุกสนาน':
        return 1;

      case 'รู้สึกตื่นเต้น':
        return 1;

      case 'รู้สึกสนใจ':
        return 1;

      case 'รู้สึกเฉยๆ':
        return 0;

      case 'รู้สึกวิตกกังวล':
        return -1;

      case 'รู้สึกเบื่อหน่าย':
        return -1;

      case 'รู้สึกเครียด':
        return -1;

      case 'รู้สึกกลัว':
        return -1;

      default:
        return 0;
    }
  }

  double _calculateEmotionScore(Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return 0;
    }

    int positive = 0;
    int negative = 0;

    distribution.forEach((emotion, count) {
      // อารมณ์ด้านบวก
      if (emotion == 'รู้สึกสนใจ' ||
          emotion == 'รู้สึกตื่นเต้น' ||
          emotion == 'รู้สึกสนุกสนาน') {
        positive += count;
      }
      // อารมณ์ด้านลบ
      else if (emotion == 'รู้สึกวิตกกังวล' ||
          emotion == 'รู้สึกเครียด' ||
          emotion == 'รู้สึกเบื่อหน่าย' ||
          emotion == 'รู้สึกกลัว') {
        negative += count;
      }
    });

    final total = positive + negative;

    if (total == 0) {
      return 0;
    }

    final positiveRatio = positive / total;
    final negativeRatio = negative / total;

    // หลักการ A
    if (positiveRatio > negativeRatio) {
      return 1;
    }

    if (negativeRatio > positiveRatio) {
      return -1;
    }

    return 0;
  }

  ////
  StreamSubscription<DatabaseEvent>? _emotionSubscription;

  final EmotionService _emotionService = EmotionService();

  final SessionService _sessionService = SessionService();

  int beforeStudentCount = 0;
  int beforePositivePercentage = 0;

  int afterStudentCount = 0;
  int afterPositivePercentage = 0;

  Map<String, dynamic> beforeEmotionData = {};
  Map<String, dynamic> afterEmotionData = {};
  Map<String, int> beforeEmotionDistribution = {};
  Map<String, int> afterEmotionDistribution = {};

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
    _startEmotionRealtimeListener();
    _loadEmotionData(date: DateTime.now());
  }

  @override
void dispose() {
  _emotionSubscription?.cancel();

  super.dispose();
}

  static const Color backgroundColor = Color(0xff0F0D1A);
  static const Color cardColor = Color(0xff19162A);
  static const Color chartColor = Color(0xff211D35);
  static const Color purple = Color(0xff7C5CFC);
  static const Color blue = Color(0xff4F8CFF);
  static const Color pink = Color(0xffD66BFF);

  Future<void> _loadEmotionData({DateTime? date}) async {
    final selectedDate = date ?? DateTime.now();

    try {
      final beforeRecords = await _emotionService.getEmotionRecordsByDate(
        subjectCode: widget.subject.subjectCode,
        date: selectedDate,
        type: 'before_class',
      );

      final afterRecords = await _emotionService.getEmotionRecordsByDate(
        subjectCode: widget.subject.subjectCode,
        date: selectedDate,
        type: 'after_class',
      );

      final beforeDistribution = await _emotionService
          .getEmotionDistributionByDate(
            subjectCode: widget.subject.subjectCode,
            date: selectedDate,
            type: 'before_class',
          );

      final afterDistribution = await _emotionService
          .getEmotionDistributionByDate(
            subjectCode: widget.subject.subjectCode,
            date: selectedDate,
            type: 'after_class',
          );

      // คำนวณก่อนเรียน

      int beforeStudentTotal = 0;
      int beforePositive = 0;

      for (final record in beforeRecords) {
        final count = (record['counter'] ?? 1) as num;

        beforeStudentTotal += count.toInt();

        final emotion = record['emotion'];

        if (emotion == 'รู้สึกสนใจ' ||
            emotion == 'รู้สึกตื่นเต้น' ||
            emotion == 'รู้สึกสนุกสนาน' ||
            emotion == 'รู้สึกเฉยๆ') {
          beforePositive += count.toInt();
        }
      }

      // =====================================================
      // คำนวณหลังเรียน
      // =====================================================

      int afterStudentTotal = 0;
      int afterPositive = 0;

      for (final record in afterRecords) {
        final count = (record['counter'] ?? 1) as num;

        afterStudentTotal += count.toInt();

        final emotion = record['emotion'];

        if (emotion == 'รู้สึกสนใจ' ||
            emotion == 'รู้สึกตื่นเต้น' ||
            emotion == 'รู้สึกสนุกสนาน' ||
            emotion == 'รู้สึกเฉยๆ') {
          afterPositive += count.toInt();
        }
      }

      // =====================================================
      // อัปเดตหน้าจอ
      // =====================================================

      if (!mounted) return;

      setState(() {
        beforeStudentCount = beforeRecords.length;
        afterStudentCount = afterRecords.length;

        beforePositivePercentage = beforeRecords.isEmpty
            ? 0
            : ((beforePositive / beforeRecords.length) * 100).round();

        afterPositivePercentage = afterRecords.isEmpty
            ? 0
            : ((afterPositive / afterRecords.length) * 100).round();

        beforeEmotionDistribution = beforeDistribution;
        afterEmotionDistribution = afterDistribution;
      });

      debugPrint('ก่อนเรียน: $beforeStudentTotal คน');

      debugPrint('หลังเรียน: $afterStudentTotal คน');
    } catch (e) {
      debugPrint('โหลด Emotion ไม่สำเร็จ: $e');

      if (!mounted) return;

      setState(() {
        beforeStudentCount = 0;
        afterStudentCount = 0;
        beforePositivePercentage = 0;
        afterPositivePercentage = 0;
      });
    }
  }

  void _startEmotionRealtimeListener() {
    _emotionSubscription = FirebaseDatabase.instance
        .ref('emotionData')
        .onValue
        .listen((event) {
          debugPrint('มีการเปลี่ยนแปลงข้อมูล Emotion');

          // เรียกฟังก์ชันเดิมของคุณใหม่
          _loadEmotionData();
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
      // โหลด Session ของวันที่เลือก
      final sessions = await _sessionService.getSessionsByDate(
        subjectCode: widget.subject.subjectCode,
        date: date,
      );

      // โหลด Emotion ของวันที่เลือก
      await _loadEmotionData(date: date);

      if (!mounted) return;

      setState(() {
        _selectedSessions = sessions;
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint('โหลดข้อมูลย้อนหลังไม่สำเร็จ: $e');

      if (!mounted) return;

      setState(() {
        _selectedSessions = [];
        _isLoadingHistory = false;

        beforeStudentCount = 0;
        afterStudentCount = 0;

        beforePositivePercentage = 0;
        afterPositivePercentage = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีข้อมูล'),
          duration: Duration(seconds: 2),
        ),
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

              // Emotion Dashboard
              SizedBox(
                height: 680,

                child: PageView(
                  children: [
                    _emotionCard(
                      "ก่อนเรียน",
                      beforeStudentCount,
                      beforePositivePercentage,
                    ),

                    _emotionCard(
                      "หลังเรียน",
                      afterStudentCount,
                      afterPositivePercentage,
                    ),
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

  Widget _emotionCard(String title, int studentCount, int positivePercentage) {
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

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: chartColor,
                borderRadius: BorderRadius.circular(18),
              ),

              child: EmotionDonutChart(
                emotionData: title == 'ก่อนเรียน'
                    ? beforeEmotionDistribution
                    : afterEmotionDistribution,
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

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: chartColor,
                borderRadius: BorderRadius.circular(18),
              ),

              child: _emotionTrendChart(),
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

  // AI
  Widget _aiRecommendation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const SizedBox(width: 14),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [SizedBox(height: 3)],
              ),
            ],
          ),

          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 170,
              height: 52,

              child: ElevatedButton.icon(
                onPressed: openChatbot,

                icon: const Icon(Icons.auto_awesome, size: 20),

                label: const Text(
                  "ไปยังแชทบอท",
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

  Future<void> openChatbot() async {
    Map<String, dynamic>? emotionData;

    String? sessionId;
    String? type;

    try {
      // กรณีเลือกวันที่ย้อนหลัง
      final selectedDate = _selectedDate ?? DateTime.now();

      // อ่าน Current Session
      final currentSession = await _sessionService.getCurrentSession();

      if (currentSession != null) {
        // ดึง type
        type = currentSession['type']?.toString();

        // ดึง sessionId
        sessionId = currentSession['sessionId']?.toString();
      }

      // ถ้าไม่มี type ให้ใช้ before_class เป็นค่าเริ่มต้น
      type ??= 'before_class';

      // ดึงข้อมูล Emotion
      emotionData = await _emotionService.getEmotionSummaryForAI(
        subjectCode: widget.subject.subjectCode,
        date: selectedDate,
        type: type,
      );

      debugPrint('========== EMOTION DATA FOR AI ==========');
      debugPrint(emotionData.toString());

      debugPrint('========== CHAT CONTEXT ==========');
      debugPrint('subjectCode: ${widget.subject.subjectCode}');
      debugPrint('sessionId: $sessionId');
      debugPrint('type: $type');
      debugPrint('==================================');
    } catch (e) {
      debugPrint('ไม่สามารถโหลดข้อมูล Emotion สำหรับ Chatbot: $e');
    }

    if (!mounted) return;

    // เข้า Chatbot ได้เสมอ
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          emotionData: emotionData,
          subjectCode: widget.subject.subjectCode,
          sessionId: sessionId,
        ),
      ),
    );
  }

  Widget _emotionTrendChart() {
    // คะแนนที่คำนวณจริง
    final beforeScore = _calculateEmotionScore(beforeEmotionDistribution);

    final afterScore = _calculateEmotionScore(afterEmotionDistribution);

    final hasBefore = beforeEmotionDistribution.isNotEmpty;
    final hasAfter = afterEmotionDistribution.isNotEmpty;

    // ถ้ายังไม่มีข้อมูลก่อนเรียน
    if (!hasBefore) {
      return const Center(
        child: Text(
          'ยังไม่มีข้อมูล',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: -1,
        maxY: 1,

        // =========================
        // Grid
        // =========================
        gridData: FlGridData(
          show: true,

          horizontalInterval: 0.5,

          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.12),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },

          verticalInterval: 1,

          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.10),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),

        // =========================
        // แกน X / Y
        // =========================
        titlesData: FlTitlesData(
          // -------------------------
          // แกน Y
          // -------------------------
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 65,

              interval: 0.5,

              getTitlesWidget: (value, meta) {
                String text;

                switch (value.toStringAsFixed(1)) {
                  case '1.0':
                    text = 'ดีมาก';

                  case '0.5':
                    text = 'ดี';

                  case '0.0':
                    text = 'เฉยๆ';

                  case '-0.5':
                    text = 'แย่';

                  case '-1.0':
                    text = 'แย่มาก';

                  default:
                    return const SizedBox();
                }

                return Text(
                  text,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                );
              },
            ),
          ),

          // -------------------------
          // แกน X
          // -------------------------
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,

              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const Text(
                    'ก่อนเรียน',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  );
                }

                if (value == 1) {
                  return const Text(
                    'หลังเรียน',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  );
                }

                return const SizedBox();
              },
            ),
          ),

          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),

        // =========================
        // เส้นกราฟ
        // =========================
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, beforeScore),

              // มีเส้นไปหลังเรียนเฉพาะเมื่อมีข้อมูล
              if (hasAfter) FlSpot(1, afterScore),
            ],

            isCurved: true,

            curveSmoothness: 0.25,

            color: Colors.white,

            barWidth: 3,

            isStrokeCapRound: true,

            dotData: FlDotData(
              show: true,

              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: index == 0 ? purple : Colors.green,
                  strokeWidth: 3,
                  strokeColor: Colors.white,
                );
              },
            ),

            belowBarData: BarAreaData(
              show: true,
              color: purple.withOpacity(0.08),
            ),
          ),
        ],

        // =========================
        // เส้นกรอบ
        // =========================
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.white.withOpacity(0.18)),
            bottom: BorderSide(color: Colors.white.withOpacity(0.18)),
          ),
        ),

        // =========================
        // จุดสัมผัสกราฟ
        // =========================
        lineTouchData: LineTouchData(
          enabled: true,

          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String label;

                if (spot.y == 1) {
                  label = 'ดีขึ้นมาก';
                } else if (spot.y == 0) {
                  label = 'ไม่เปลี่ยนแปลง';
                } else {
                  label = 'แย่ลง';
                }

                return LineTooltipItem(
                  label,
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
