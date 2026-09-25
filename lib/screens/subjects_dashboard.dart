import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../screens/files.dart';
import '../services/emotion_service.dart';
import '../services/session_service.dart';
import '../services/subject_service.dart';
import '../widgets/emotion_card.dart';
import '../services/dashboard_pdf_connector.dart';
import 'chat.dart';
import '../constants/app_colors.dart';

enum _SubjectManagementAction { edit, delete }

// ============================================================
// Subject Dashboard
// ============================================================

class SubjectDashboard extends StatefulWidget {
  final Subject subject;

  final ValueChanged<Subject>? onSubjectUpdated;
  final VoidCallback? onSubjectDeleted;

  const SubjectDashboard({
    super.key,
    required this.subject,
    this.onSubjectUpdated,
    this.onSubjectDeleted,
  });

  @override
  State<SubjectDashboard> createState() => _SubjectDashboardState();
}

class _SubjectDashboardState extends State<SubjectDashboard> {
  // ==========================================================
  // Services
  // ==========================================================

  final EmotionService _emotionService = EmotionService();
  final SessionService _sessionService = SessionService();
  final SubjectService _subjectService = SubjectService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController semesterController = TextEditingController();

  String errorMessage = '';

  // ==========================================================
  // Realtime Emotion
  // ==========================================================

  StreamSubscription<DatabaseEvent>? _emotionSubscription;
  Timer? _autoCloseTimer;

  late Subject _subject;

  int beforeStudentCount = 0;
  int beforePositivePercentage = 0;

  int duringStudentCount = 0;
  int duringPositivePercentage = 0;

  int afterStudentCount = 0;
  int afterPositivePercentage = 0;

  Map<String, int> beforeEmotionDistribution = {};
  Map<String, int> duringEmotionDistribution = {};
  Map<String, int> afterEmotionDistribution = {};

  final PageController _emotionPageController = PageController();

  int _currentEmotionPage = 0;

  // ==========================================================
  // Session
  // ==========================================================

  String? _sessionId;
  bool _isClassActive = false;
  bool _isLoading = false;

  // ==========================================================
  // History
  // ==========================================================

  DateTime? _selectedDate;

  List<Map<String, dynamic>> _selectedSessions = [];

  String? _selectedSessionId;

  bool _isLoadingHistory = false;

  bool _isLoadingOverlay = false;
  String _loadingText = 'กำลังโหลดข้อมูล...';

  // ==========================================================
  // Emotion Score
  //
  // +1 = อารมณ์ด้านบวกมากกว่า
  //  0 = เท่ากัน / ไม่มีข้อมูล
  // -1 = อารมณ์ด้านลบมากกว่า
  // ==========================================================

  double _calculateEmotionScore(Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return 0;
    }

    int positive = 0;
    int negative = 0;
    int total = 0;

    distribution.forEach((emotion, count) {
      total += count;

      if (emotion == 'รู้สึกสนใจ' ||
          emotion == 'รู้สึกตื่นเต้น' ||
          emotion == 'รู้สึกสนุกสนาน') {
        positive += count;
      } else if (emotion == 'รู้สึกวิตกกังวล' ||
          emotion == 'รู้สึกเครียด' ||
          emotion == 'รู้สึกเบื่อหน่าย' ||
          emotion == 'รู้สึกกลัว') {
        negative += count;
      }
    });

    if (total == 0) {
      return 0;
    }

    // Emotion Score อยู่ระหว่าง -1 ถึง +1
    //
    // +1 = อารมณ์ด้านบวกทั้งหมด
    //  0 = อารมณ์สมดุล / มีอารมณ์กลางร่วมด้วย
    // -1 = อารมณ์ด้านลบทั้งหมด
    return (positive - negative) / total;
  }

  // ==========================================================
  // Engagement
  // ==========================================================

  int get _totalStudents {
    int total = beforeStudentCount;

    if (duringStudentCount > total) {
      total = duringStudentCount;
    }

    if (afterStudentCount > total) {
      total = afterStudentCount;
    }

    return total;
  }

  int get _completedStudents {
    if (_totalStudents == 0) {
      return 0;
    }

    int completed = beforeStudentCount;

    if (duringStudentCount < completed) {
      completed = duringStudentCount;
    }

    if (afterStudentCount < completed) {
      completed = afterStudentCount;
    }

    return completed;
  }

  int get _engagementPercentage {
    if (_totalStudents == 0) {
      return 0;
    }

    return ((_completedStudents / _totalStudents) * 100).round();
  }

  // ==========================================================
  // Init
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _subject = widget.subject;

    _loadActiveSession();

    _startEmotionRealtimeListener();
  }

  // ==========================================================
  // Dispose
  // ==========================================================

  @override
  void dispose() {
    _emotionSubscription?.cancel();
    _autoCloseTimer?.cancel();

    _emotionPageController.dispose();

    nameController.dispose();
    codeController.dispose();
    yearController.dispose();
    semesterController.dispose();

    super.dispose();
  }

  // ==========================================================
  // Positive Emotion
  // ==========================================================

  bool _isPositiveEmotion(String? emotion) {
    return emotion == 'รู้สึกสนใจ' ||
        emotion == 'รู้สึกตื่นเต้น' ||
        emotion == 'รู้สึกสนุกสนาน';
  }

  // ==========================================================
  // Load Emotion Data
  // ==========================================================

  Future<void> _loadEmotionData({String? sessionId}) async {
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }

    try {
      // --------------------------------------------------------
      // Before Class
      // --------------------------------------------------------

      final beforeRecords = await _emotionService.getEmotionRecordsBySession(
        subjectCode: _subject.subjectCode,
        sessionId: sessionId,
        type: 'before_class',
      );

      // --------------------------------------------------------
      // During Class
      // --------------------------------------------------------

      final duringRecords = await _emotionService.getEmotionRecordsBySession(
        subjectCode: _subject.subjectCode,
        sessionId: sessionId,
        type: 'during_class',
      );

      // --------------------------------------------------------
      // After Class
      // --------------------------------------------------------

      final afterRecords = await _emotionService.getEmotionRecordsBySession(
        subjectCode: _subject.subjectCode,
        sessionId: sessionId,
        type: 'after_class',
      );

      // --------------------------------------------------------
      // Emotion Distribution
      // --------------------------------------------------------

      final beforeDistribution = await _emotionService
          .getEmotionDistributionBySession(
            subjectCode: _subject.subjectCode,
            sessionId: sessionId,
            type: 'before_class',
          );

      final duringDistribution = await _emotionService
          .getEmotionDistributionBySession(
            subjectCode: _subject.subjectCode,
            sessionId: sessionId,
            type: 'during_class',
          );

      final afterDistribution = await _emotionService
          .getEmotionDistributionBySession(
            subjectCode: _subject.subjectCode,
            sessionId: sessionId,
            type: 'after_class',
          );

      // --------------------------------------------------------
      // Before Class
      // --------------------------------------------------------

      int beforeTotal = 0;
      int beforePositive = 0;

      for (final record in beforeRecords) {
        final count = ((record['counter'] ?? 1) as num).toInt();

        beforeTotal += count;

        if (_isPositiveEmotion(record['emotion']?.toString())) {
          beforePositive += count;
        }
      }

      // --------------------------------------------------------
      // During Class
      // --------------------------------------------------------

      int duringTotal = 0;
      int duringPositive = 0;

      for (final record in duringRecords) {
        final count = ((record['counter'] ?? 1) as num).toInt();

        duringTotal += count;

        if (_isPositiveEmotion(record['emotion']?.toString())) {
          duringPositive += count;
        }
      }

      // --------------------------------------------------------
      // After Class
      // --------------------------------------------------------

      int afterTotal = 0;
      int afterPositive = 0;

      for (final record in afterRecords) {
        final count = ((record['counter'] ?? 1) as num).toInt();

        afterTotal += count;

        if (_isPositiveEmotion(record['emotion']?.toString())) {
          afterPositive += count;
        }
      }

      // --------------------------------------------------------
      // Update UI
      // --------------------------------------------------------

      if (!mounted) return;

      setState(() {
        beforeStudentCount = beforeTotal;
        duringStudentCount = duringTotal;
        afterStudentCount = afterTotal;

        beforePositivePercentage = beforeTotal == 0
            ? 0
            : ((beforePositive / beforeTotal) * 100).round();

        duringPositivePercentage = duringTotal == 0
            ? 0
            : ((duringPositive / duringTotal) * 100).round();

        afterPositivePercentage = afterTotal == 0
            ? 0
            : ((afterPositive / afterTotal) * 100).round();

        beforeEmotionDistribution = beforeDistribution;
        duringEmotionDistribution = duringDistribution;
        afterEmotionDistribution = afterDistribution;
      });

      debugPrint('Session: $sessionId');
      debugPrint('ก่อนเรียน: $beforeTotal คน');
      debugPrint('ระหว่างเรียน: $duringTotal คน');
      debugPrint('หลังเรียน: $afterTotal คน');
      debugPrint('ก่อนเรียน Positive: $beforePositivePercentage%');
      debugPrint('ระหว่างเรียน Positive: $duringPositivePercentage%');
      debugPrint('หลังเรียน Positive: $afterPositivePercentage%');
    } catch (error) {
      debugPrint('โหลด Emotion ไม่สำเร็จ: $error');

      if (!mounted) return;

      setState(() {
        beforeStudentCount = 0;
        duringStudentCount = 0;
        afterStudentCount = 0;

        beforePositivePercentage = 0;
        duringPositivePercentage = 0;
        afterPositivePercentage = 0;

        beforeEmotionDistribution = {};
        duringEmotionDistribution = {};
        afterEmotionDistribution = {};
      });
    }
  }

  // ==========================================================
  // Realtime Emotion Listener
  // ==========================================================
  void _startEmotionRealtimeListener() {
    _emotionSubscription = FirebaseDatabase.instance
        .ref('emotion_data/${_subject.subjectCode}')
        .onValue
        .listen((event) {
          debugPrint(
            '🔄 มีการเปลี่ยนแปลง Emotion ของวิชา ${_subject.subjectCode}',
          );

          final sessionId = _sessionId;

          if (sessionId == null || sessionId.isEmpty) {
            return;
          }

          _sessionService.updateLastActivity(sessionId);

          _loadEmotionData(sessionId: sessionId);
        });
  }
  // ==========================================================
  // Load Active Session
  // ==========================================================

  Future<void> _loadActiveSession() async {
    try {
      final session = await _sessionService.getActiveSession(
        _subject.subjectCode,
      );

      if (!mounted) return;

      if (session != null) {
        final sessionId = session['sessionId']?.toString();

        setState(() {
          _sessionId = sessionId;
          _isClassActive = true;
        });

        if (sessionId != null && sessionId.isNotEmpty) {
          await _loadEmotionData(sessionId: sessionId);

          _startAutoCloseChecker();
        }
      } else {
        setState(() {
          _sessionId = null;
          _isClassActive = false;
        });
      }
    } catch (error) {
      debugPrint('ไม่สามารถโหลด Session ได้: $error');
    }
  }

  //////////////////
  void _startAutoCloseChecker() {
    _autoCloseTimer?.cancel();

    _autoCloseTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final sessionId = _sessionId;

      if (sessionId == null || sessionId.isEmpty) {
        return;
      }

      try {
        final closed = await _sessionService.checkAndAutoCloseSession(
          sessionId,
        );

        if (!closed || !mounted) {
          return;
        }

        setState(() {
          _sessionId = null;
          _isClassActive = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ห้องเรียนถูกปิดอัตโนมัติ เนื่องจากไม่มีการส่งข้อมูลเป็นเวลา 3 ชั่วโมง',
            ),
          ),
        );
      } catch (error) {
        debugPrint('ตรวจสอบการปิดห้องเรียนอัตโนมัติไม่สำเร็จ: $error');
      }
    });
  }

  // ==========================================================
  // Start Classroom
  // ==========================================================

  Future<void> _startClassroom() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final sessionId = await _sessionService.startSession(
        subjectCode: _subject.subjectCode,
      );

      if (!mounted) return;

      setState(() {
        _sessionId = sessionId;
        _selectedSessionId = sessionId;
        _isClassActive = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปิดห้องเรียนเรียบร้อยแล้ว')),
      );

      await _loadEmotionData(sessionId: sessionId);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิดห้องเรียนได้: $error')),
      );
    }
  }

  // ==========================================================
  // End Classroom
  // ==========================================================

  Future<void> _endClassroom() async {
    if (_sessionId == null) return;

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _sessionService.endSession(_sessionId!);

      if (!mounted) return;

      setState(() {
        _isClassActive = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ปิดห้องเรียนเรียบร้อยแล้ว')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถปิดห้องเรียนได้: $error')),
      );
    }
  }

  // ==========================================================
  // Toggle Classroom
  // ==========================================================

  Future<void> _toggleClassroom() async {
    if (_isLoading) return;

    if (_isClassActive) {
      await _endClassroom();
    } else {
      await _startClassroom();
    }
  }

  // ==========================================================
  //เลือกวันที่

  Future<void> _selectDate() async {
    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return _thaiCalendarBottomSheet();
      },
    );

    if (pickedDate == null) return;

    // โหลด Session ของวันที่เลือก
    await _loadSessionsByDate(pickedDate);

    // ถ้าไม่มี Session
    if (_selectedSessions.isEmpty) {
      return;
    }

    // ถ้ามีแค่ 1 Session ให้โหลดทันที
    if (_selectedSessions.length == 1) {
      final sessionId = _selectedSessions.first['sessionId']?.toString();

      if (sessionId != null && sessionId.isNotEmpty) {
        setState(() {
          _selectedSessionId = sessionId;
        });

        await _loadEmotionData(sessionId: sessionId);
      }

      return;
    }

    // ถ้ามีหลาย Session ให้ผู้ใช้เลือก
    if (!mounted) return;

    final selectedSession = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            decoration: const BoxDecoration(
              color: AppColors.sheetBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.dragHandle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                const Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.accent),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เลือก Session',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'เลือกข้อมูลการเรียนที่ต้องการดู',
                          style: TextStyle(
                            color: AppColors.faintText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _selectedSessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final session = _selectedSessions[index];

                      final startTime = session['startTime'];
                      final endTime = session['endTime'];

                      String formatTime(dynamic value) {
                        if (value == null) {
                          return '--:--';
                        }

                        try {
                          final time = (value as dynamic).toDate();

                          return '${time.hour.toString().padLeft(2, '0')}:'
                              '${time.minute.toString().padLeft(2, '0')}';
                        } catch (_) {
                          return '--:--';
                        }
                      }

                      final start = formatTime(startTime);
                      final end = formatTime(endTime);

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(context, session);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accentSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  color: AppColors.accent,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Session ${index + 1}',
                                      style: const TextStyle(
                                        color: AppColors.primaryText,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$start - $end น.',
                                      style: const TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.faintText,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedSession == null) return;

    final sessionId = selectedSession['sessionId']?.toString();

    if (sessionId == null || sessionId.isEmpty) return;

    setState(() {
      _selectedSessionId = sessionId;
    });

    await _loadEmotionData(sessionId: sessionId);
  }

  // ==========================================================
  // Load History
  // ==========================================================

  Future<void> _loadSessionsByDate(DateTime date) async {
    setState(() {
      _isLoadingHistory = true;
      _selectedDate = date;
    });

    try {
      final sessions = await _sessionService.getSessionsByDate(
        subjectCode: _subject.subjectCode,
        date: date,
      );

      if (!mounted) return;

      setState(() {
        _selectedSessions = sessions;
        _isLoadingHistory = false;
      });

      if (sessions.isEmpty) {
        setState(() {
          beforeStudentCount = 0;
          duringStudentCount = 0;
          afterStudentCount = 0;

          beforePositivePercentage = 0;
          duringPositivePercentage = 0;
          afterPositivePercentage = 0;

          beforeEmotionDistribution = {};
          duringEmotionDistribution = {};
          afterEmotionDistribution = {};
        });
      }
    } catch (error) {
      debugPrint('โหลดประวัติ Session ไม่สำเร็จ: $error');

      if (!mounted) return;

      setState(() {
        _selectedSessions = [];
        _isLoadingHistory = false;

        beforeStudentCount = 0;
        duringStudentCount = 0;
        afterStudentCount = 0;

        beforePositivePercentage = 0;
        duringPositivePercentage = 0;
        afterPositivePercentage = 0;

        beforeEmotionDistribution = {};
        duringEmotionDistribution = {};
        afterEmotionDistribution = {};
      });
    }
  }

  // ==========================================================
  // Chatbot
  // ==========================================================
  Future<void> _openChatbot() async {
    Map<String, dynamic>? emotionData;

    // ใช้ Session ที่กำลังแสดง/ถูกเลือกบน Dashboard
    // ถ้ายังไม่มีการเลือกย้อนหลัง ให้ใช้ Session ปัจจุบัน
    final sessionId = _selectedSessionId ?? _sessionId;

    try {
      final selectedDate = _selectedDate ?? DateTime.now();

      if (sessionId == null || sessionId.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบ Session ที่ต้องการวิเคราะห์'),
          ),
        );
        return;
      }

      emotionData = await _emotionService.getEmotionSummaryForAI(
        subjectCode: _subject.subjectCode,
        sessionId: sessionId,
        type: 'before_class',
      );

      debugPrint('subjectCode: ${_subject.subjectCode}');
      debugPrint('sessionId: $sessionId');
      debugPrint('selectedDate: $selectedDate');
    } catch (error) {
      debugPrint('ไม่สามารถโหลดข้อมูลสำหรับ Chatbot: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิด Chatbot ได้: $error')),
      );
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ChatScreen(
            emotionData: emotionData,
            subjectCode: _subject.subjectCode,
            sessionId: sessionId,
            autoAttachEmotion: true,
          );
        },
      ),
    );
  }

  // Subject Management
  Future<void> _showSubjectManagement() async {
    final action = await showModalBottomSheet<_SubjectManagementAction>(
      context: context,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.modalBarrier,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 11, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.sheetBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.dragHandle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'จัดการรายวิชา',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${_subject.subjectName} · ${_subject.subjectCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.faintText,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 16),

                _managementActionTile(
                  icon: Icons.edit_outlined,
                  title: 'แก้ไขข้อมูลรายวิชา',
                  subtitle: 'ชื่อวิชา รหัส ปีการศึกษา และภาคเรียน',
                  onTap: () {
                    Navigator.pop(sheetContext, _SubjectManagementAction.edit);
                  },
                ),

                const SizedBox(height: 10),

                _managementActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'ลบรายวิชา',
                  subtitle: 'นำรายวิชานี้ออกจากรายการของฉัน',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      _SubjectManagementAction.delete,
                    );
                  },
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryText,
                      side: const BorderSide(color: AppColors.buttonBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == _SubjectManagementAction.edit) {
      await _showEditSubjectSheet();
      return;
    }

    if (action == _SubjectManagementAction.delete) {
      await _confirmDeleteSubject();
    }
  }

  // ==========================================================
  // Management Action Tile
  // ==========================================================

  Widget _managementActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? AppColors.danger : AppColors.accent;

    final background = destructive
        ? AppColors.dangerSurface
        : AppColors.accentSurface;

    return Material(
      color: AppColors.subtleSurface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.buttonBorder),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: destructive ? color : AppColors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: destructive
                            ? color.withOpacity(0.70)
                            : AppColors.faintText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: destructive ? color : AppColors.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // Edit Subject
  // ==========================================================

  Future<void> _showEditSubjectSheet() async {
    nameController.text = _subject.subjectName;
    codeController.text = _subject.subjectCode;
    yearController.text = _subject.year;
    semesterController.text = _subject.semester;

    errorMessage = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.modalBarrier,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: const BoxDecoration(
                    color: AppColors.sheetBackground,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.dragHandle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'แก้ไขข้อมูลรายวิชา',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'แก้ไขข้อมูลของรายวิชานี้',
                          style: TextStyle(
                            color: AppColors.faintText,
                            fontSize: 11,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _subjectTextField(
                          label: 'ชื่อวิชา',
                          controller: nameController,
                        ),

                        const SizedBox(height: 12),

                        _subjectTextField(
                          label: 'รหัสวิชา',
                          controller: codeController,
                        ),

                        const SizedBox(height: 12),

                        _subjectTextField(
                          label: 'ปีการศึกษา',
                          controller: yearController,
                        ),

                        const SizedBox(height: 12),

                        _subjectTextField(
                          label: 'ภาคเรียน',
                          controller: semesterController,
                        ),

                        if (errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 12),

                          Text(
                            errorMessage,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 11,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.secondaryText,
                                  side: const BorderSide(
                                    color: AppColors.buttonBorder,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('ยกเลิก'),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _saveSubject(
                                    sheetContext,
                                    setSheetState,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.onAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('บันทึกการแก้ไข'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // Save Subject
  // ==========================================================

  Future<void> _saveSubject(
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
    final name = nameController.text.trim();
    final code = codeController.text.trim();
    final year = yearController.text.trim();
    final semester = semesterController.text.trim();

    if (name.isEmpty || code.isEmpty || year.isEmpty || semester.isEmpty) {
      setSheetState(() {
        errorMessage = 'กรุณากรอกข้อมูลให้ครบทุกช่อง';
      });
      return;
    }

    final updatedSubject = Subject(
      subjectName: name,
      subjectCode: code,
      year: year,
      semester: semester,
    );

    try {
      await _subjectService.updateSubject(
        oldCode: _subject.subjectCode,
        newSubject: updatedSubject,
      );

      if (!mounted || !sheetContext.mounted) return;

      setState(() {
        _subject = updatedSubject;
      });

      widget.onSubjectUpdated?.call(updatedSubject);

      Navigator.pop(sheetContext);
    } catch (error) {
      debugPrint('แก้ไขรายวิชาไม่สำเร็จ: $error');

      if (!sheetContext.mounted) return;

      setSheetState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ==========================================================
  // Subject TextField
  // ==========================================================

  Widget _subjectTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
        ),

        const SizedBox(height: 6),

        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            cursorColor: AppColors.accent,
            style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.subtleSurface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppColors.buttonBorder),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppColors.buttonBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: AppColors.accent,
                  width: 1.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // Delete Subject
  // ==========================================================

  Future<void> _confirmDeleteSubject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.modalBarrierStrong,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.buttonBorder),
          ),
          icon: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.dangerSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
            ),
          ),
          title: const Text(
            'ลบรายวิชานี้?',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Text(
            'รายวิชา “${_subject.subjectName}” '
            'จะถูกนำออกจากหน้ารายวิชาของฉัน '
            'และไม่สามารถย้อนกลับจากหน้านี้ได้',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondaryText,
                side: const BorderSide(color: AppColors.buttonBorder),
              ),
              child: const Text('ยกเลิก'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.dangerButton,
                foregroundColor: AppColors.onAccent,
              ),
              child: const Text('ลบรายวิชา'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    // ปิด Session ก่อนลบรายวิชา
    if (_isClassActive && _sessionId != null) {
      try {
        await _sessionService.endSession(_sessionId!);
      } catch (error) {
        debugPrint('ปิด Session ก่อนลบรายวิชาไม่สำเร็จ: $error');
      }
    }

    try {
      await _subjectService.deleteSubject(_subject.subjectCode);

      if (!mounted) return;

      widget.onSubjectDeleted?.call();

      Navigator.pop(context);
    } catch (error) {
      debugPrint('ลบรายวิชาไม่สำเร็จ: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบรายวิชาไม่สำเร็จ: $error')));
    }
  }

  // ==========================================================
  // Bottom Navigation
  // ==========================================================

  void _onDashboardNavigationTap(int index) {
    switch (index) {
      case 0:
        return;

      case 1:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => MaterialScreen(
              subjectName: _subject.subjectName,
              subjectCode: _subject.subjectCode,
            ),
          ),
        );
        return;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => ChatScreen(
              subjectCode: _subject.subjectCode,
              sessionId: _sessionId,
            ),
          ),
        );
        return;
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      bottomNavigationBar: _DashboardBottomNavigation(
        currentIndex: 0,
        onTap: _onDashboardNavigationTap,
      ),

      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.55, -1.05),
            radius: 1.15,
            colors: [
              AppColors.headerGradientStart,
              AppColors.headerGradientMid,
              AppColors.background,
            ],
            stops: [0, 0.35, 1],
          ),
        ),

        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 6),

                    _buildCourseCard(),

                    const SizedBox(height: 17),

                    const _SectionLabel('การมีส่วนร่วม'),

                    const SizedBox(height: 9),

                    _buildEngagementCard(),

                    const SizedBox(height: 15),

                    const _SectionLabel('ภาพรวมอารมณ์'),

                    const SizedBox(height: 10),

                    // ======================================================
                    // Emotion Pages
                    // ======================================================
                    SizedBox(
                      height: 680,
                      child: PageView(
                        controller: _emotionPageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentEmotionPage = index;
                          });
                        },
                        children: [
                          _emotionCard(
                            studentCount: beforeStudentCount,
                            positivePercentage: beforePositivePercentage,
                            emotionData: beforeEmotionDistribution,
                          ),

                          _emotionCard(
                            studentCount: duringStudentCount,
                            positivePercentage: duringPositivePercentage,
                            emotionData: duringEmotionDistribution,
                          ),

                          _emotionCard(
                            studentCount: afterStudentCount,
                            positivePercentage: afterPositivePercentage,
                            emotionData: afterEmotionDistribution,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    _buildBottomActions(),
                  ],
                ),
              ),

              if (_isLoadingHistory)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.accent,
                    backgroundColor: AppColors.transparent,
                  ),
                ),

              _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // Header
  // ==========================================================

  Widget _buildHeader() {
    final history = _selectedSessions.isEmpty
        ? ''
        : ' · ${_selectedSessions.length} คาบ';

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SquareIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'แดชบอร์ด',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${_formatThaiDate(_selectedDate ?? DateTime.now())}$history',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.faintText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: 75,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _SquareIconButton(
                  icon: Icons.calendar_month_outlined,
                  accent: true,
                  onPressed: _selectDate,
                ),

                const SizedBox(width: 7),

                _SquareIconButton(
                  icon: Icons.more_vert_rounded,
                  onPressed: _showSubjectManagement,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Course Card
  // ==========================================================

  Widget _buildCourseCard() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _cardDecoration(14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🧠', style: TextStyle(fontSize: 16)),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _subject.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${_subject.subjectCode} · '
                  'ปีการศึกษา ${_subject.year} · '
                  'ภาคเรียนที่ ${_subject.semester}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.faintText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          InkWell(
            onTap: _toggleClassroom,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _isClassActive
                    ? AppColors.greenSurface
                    : AppColors.accentSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: _isLoading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.primaryText,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _isClassActive
                                ? AppColors.green
                                : AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 5),

                        Text(
                          _isClassActive ? 'กำลังสอน' : 'เปิดห้อง',
                          style: TextStyle(
                            color: _isClassActive
                                ? AppColors.green
                                : AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Emotion Card
  // ==========================================================

  Widget _emotionPeriodButton({required String title, required int index}) {
    final selected = _currentEmotionPage == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _emotionPageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? AppColors.primaryText : AppColors.secondaryText,
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emotionCard({
    required int studentCount,
    required int positivePercentage,
    required Map<String, int> emotionData,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.subtleSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.buttonBorder),
            ),
            child: Row(
              children: [
                _emotionPeriodButton(title: 'ก่อนเรียน', index: 0),

                _emotionPeriodButton(title: 'ระหว่างเรียน', index: 1),

                _emotionPeriodButton(title: 'หลังเรียน', index: 2),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'จำนวนนักศึกษา',
                  studentCount.toString(),
                  Icons.people_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.innerSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: EmotionDonutChart(emotionData: emotionData),
            ),
          ),

          const SizedBox(height: 14),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.innerSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: _emotionTrendChart(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Summary Item
  // ==========================================================

  Widget _summaryItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.innerSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.faintText,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emotionTrendChart() {
    final beforeScore = _calculateEmotionScore(beforeEmotionDistribution);

    final duringScore = _calculateEmotionScore(duringEmotionDistribution);

    final afterScore = _calculateEmotionScore(afterEmotionDistribution);

    final hasBefore = beforeEmotionDistribution.isNotEmpty;
    final hasDuring = duringEmotionDistribution.isNotEmpty;
    final hasAfter = afterEmotionDistribution.isNotEmpty;

    if (!hasBefore) {
      return const Center(
        child: Text(
          'รอการประเมิน',
          style: TextStyle(color: AppColors.lightMutedText, fontSize: 14),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 2,
        minY: -1,
        maxY: 1,

        // ======================================================
        // พื้นหลังแบ่งระดับอารมณ์
        // ======================================================
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            // ดี
            HorizontalRangeAnnotation(
              y1: 0.0,
              y2: 1.0,
              color: AppColors.green.withOpacity(0.12),
            ),

            // กลาง
            HorizontalRangeAnnotation(
              y1: -0.0,
              y2: 0.0,
              color: AppColors.cyan.withOpacity(0.05),
            ),

            // แย่
            HorizontalRangeAnnotation(
              y1: -1.0,
              y2: 0.0,
              color: AppColors.danger.withOpacity(0.10),
            ),
          ],
        ),

        // ======================================================
        // Grid
        // ======================================================
        gridData: FlGridData(
          show: true,
          horizontalInterval: 0.5,
          verticalInterval: 1,

          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.chartGridStrong,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },

          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.chartGridWeak,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),

        // ======================================================
        // Titles
        // ======================================================
        titlesData: FlTitlesData(
          // ----------------------------------------------------
          // ด้านซ้าย
          // ----------------------------------------------------
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: 0.5,

              getTitlesWidget: (value, meta) {
                String text;

                switch (value.toStringAsFixed(1)) {
                  case '1.0':
                    text = 'ดีมาก';
                    break;

                  case '0.0':
                    text = 'เฉยๆ';
                    break;

                  case '-1.0':
                    text = 'แย่มาก';
                    break;

                  default:
                    return const SizedBox();
                }

                return Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),

          // ----------------------------------------------------
          // ด้านล่าง
          // ----------------------------------------------------
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,

              getTitlesWidget: (value, meta) {
                String text;

                if (value == 0) {
                  text = 'ก่อนเรียน';
                } else if (value == 1) {
                  text = 'ระหว่างเรียน';
                } else if (value == 2) {
                  text = 'หลังเรียน';
                } else {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 9,
                    ),
                  ),
                );
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

        // ======================================================
        // เส้นกราฟ
        // ======================================================
        lineBarsData: [
          LineChartBarData(
            spots: [
              if (hasBefore) FlSpot(0, beforeScore),

              if (hasDuring) FlSpot(1, duringScore),

              if (hasAfter) FlSpot(2, afterScore),
            ],

            // ทำเส้นโค้งให้นุ่มเหมือนภาพตัวอย่าง
            isCurved: true,
            curveSmoothness: 0.30,

            color: AppColors.chartLine,

            barWidth: 2.8,

            isStrokeCapRound: true,

            // ==================================================
            // จุดบนกราฟ
            // ==================================================
            dotData: FlDotData(
              show: true,

              getDotPainter: (spot, percent, barData, index) {
                Color dotColor;

                // ยังคงใช้คะแนนเดิม -1 / 0 / 1
                if (spot.y > 0) {
                  dotColor = AppColors.green;
                } else if (spot.y < 0) {
                  dotColor = AppColors.danger;
                } else {
                  dotColor = AppColors.cyan;
                }

                return FlDotCirclePainter(
                  radius: 5.5,
                  color: dotColor,
                  strokeWidth: 2,
                  strokeColor: AppColors.onAccent,
                );
              },
            ),

            // พื้นที่บาง ๆ ใต้เส้น
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accent.withOpacity(0.04),
            ),
          ),
        ],

        // ======================================================
        // Border
        // ======================================================
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: AppColors.chartBorder),
            bottom: BorderSide(color: AppColors.chartBorder),
          ),
        ),

        // ======================================================
        // Tooltip
        // ======================================================
        lineTouchData: LineTouchData(
          enabled: true,

          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String label;

                if (spot.y > 0) {
                  label = 'อารมณ์ด้านบวก';
                } else if (spot.y < 0) {
                  label = 'อารมณ์ด้านลบ';
                } else {
                  label = 'อารมณ์สมดุล';
                }

                return LineTooltipItem(
                  '$label\n'
                  'คะแนน ${spot.y.toStringAsFixed(1)}',
                  const TextStyle(
                    color: AppColors.onAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // Engagement Card
  // ==========================================================

  Widget _buildEngagementCard() {
    final referenceCount = _totalStudents;

    final beforeMissing = referenceCount - beforeStudentCount;
    final duringMissing = referenceCount - duringStudentCount;
    final afterMissing = referenceCount - afterStudentCount;

    final isComplete =
        referenceCount > 0 &&
        beforeMissing == 0 &&
        duringMissing == 0 &&
        afterMissing == 0;

    Widget periodStatus(String title, int missing) {
      final complete = missing == 0;

      return SizedBox(
        height: 18,
        child: Row(
          children: [
            SizedBox(
              width: 78,
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ),
            Text(
              complete ? 'ครบ' : 'ขาด $missing คน',
              style: TextStyle(
                color: complete ? AppColors.greenText : AppColors.danger,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _cardDecoration(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _engagementPercentage / 100,
                  strokeWidth: 5,
                  backgroundColor: AppColors.buttonBorder,
                  color: AppColors.accent,
                ),
                Center(
                  child: Text(
                    '$_engagementPercentage%',
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: referenceCount == 0
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ยังไม่มีข้อมูลการมีส่วนร่วม',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'ข้อมูลจะแสดงเมื่อนักเรียนบันทึกอารมณ์',
                        style: TextStyle(
                          color: AppColors.faintText,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isComplete
                            ? 'บันทึกอารมณ์ครบทั้ง 3 ช่วง'
                            : 'ยังบันทึกอารมณ์ไม่ครบ',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      periodStatus('ก่อนเรียน', beforeMissing),
                      periodStatus('ระหว่างเรียน', duringMissing),
                      periodStatus('หลังเรียน', afterMissing),
                    ],
                  ),
          ),

          const SizedBox(width: 10),

          const _MiniBars(),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING OVERLAY
  // ============================================================

  void _showLoading(String text) {
    if (!mounted) return;

    setState(() {
      _isLoadingOverlay = true;
      _loadingText = text;
    });
  }

  void _updateLoading(String text) {
    if (!mounted) return;

    setState(() {
      _loadingText = text;
    });
  }

  void _hideLoading() {
    if (!mounted) return;

    setState(() {
      _isLoadingOverlay = false;
    });
  }

  Widget _buildLoadingOverlay() {
    if (!_isLoadingOverlay) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: AppColors.loadingOverlay,
          child: Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.dialogBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.dialogBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'กำลังโหลดข้อมูล',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loadingText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'กรุณารอสักครู่...',
                    style: TextStyle(
                      color: AppColors.faintText,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  
Future<bool> _hasSessionEmotionData(String sessionId) async {
  try {
    const types = [
      'before_class',
      'during_class',
      'after_class',
    ];

    final emotionService = EmotionService();

    for (final type in types) {
      final records = await emotionService.getEmotionRecordsBySession(
        subjectCode: _subject.subjectCode,
        sessionId: sessionId,
        type: type,
      );

      if (records.isNotEmpty) {
        return true;
      }
    }

    return false;
  } catch (error) {
    debugPrint('ตรวจสอบข้อมูล Session ไม่สำเร็จ: $error');
    return false;
  }
}
  // ==========================================================
  // Export PDF
  // ==========================================================

  Future<void> _exportPdf() async {
  if (_isLoadingOverlay) return;

  final sessionId = _selectedSessionId ?? _sessionId;

  if (sessionId == null || sessionId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กรุณาเลือก Session ที่ต้องการสร้างรายงาน'),
      ),
    );
    return;
  }

  _showLoading('กำลังตรวจสอบข้อมูลใน Session...');

  try {
    final hasData = await _hasSessionEmotionData(sessionId);

    if (!hasData) {
      _hideLoading();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session นี้ยังไม่มีข้อมูลอารมณ์ จึงไม่สามารถสร้างรายงาน PDF ได้'),
        ),
      );

      return;
    }

    _updateLoading('กำลังสร้างรายงาน PDF...');

    await DashboardPdfConnector.open(
      context: context,
      subjectName: _subject.subjectName,
      subjectCode: _subject.subjectCode,
      academicYear: _subject.year,
      semester: _subject.semester,
      selectedDate: _selectedDate ?? DateTime.now(),
      sessionId: sessionId,
    );

    _hideLoading();
  } catch (error) {
    debugPrint('สร้างรายงาน PDF ไม่สำเร็จ: $error');

    _hideLoading();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ไม่สามารถสร้างรายงาน PDF ได้: $error'),
      ),
    );
  }
}

  // ==========================================================
  // Bottom Actions
  // ==========================================================

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.insert_drive_file_outlined, size: 17),
              label: const Text('PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryText,
                disabledForegroundColor: AppColors.faintText,
                backgroundColor: AppColors.subtleSurface,
                side: const BorderSide(color: AppColors.buttonBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // ==================================================
        // Analyze / Chatbot
        // ==================================================
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _openChatbot,
              icon: const Icon(Icons.layers_outlined, size: 17),
              label: const Text('Analyze'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // Calendar
  // ==========================================================

  Widget _thaiCalendarBottomSheet() {
    DateTime selectedDate = _selectedDate ?? DateTime.now();

    return StatefulBuilder(
      builder: (context, setModalState) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            decoration: const BoxDecoration(
              color: AppColors.sheetBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.dragHandle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.accent,
                      ),

                      SizedBox(width: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เลือกวันที่',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            'ดูข้อมูลการเรียนย้อนหลัง',
                            style: TextStyle(
                              color: AppColors.faintText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          color: AppColors.secondaryText,
                          size: 20,
                        ),

                        const SizedBox(width: 10),

                        Text(
                          _formatThaiDate(selectedDate),
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.accent,
                        onPrimary: AppColors.onAccent,
                        surface: AppColors.sheetBackground,
                        onSurface: AppColors.primaryText,
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

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryText,
                            side: const BorderSide(
                              color: AppColors.buttonBorder,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('ยกเลิก'),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, selectedDate);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.onAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('ดูข้อมูลวันนี้'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // Thai Date
  // ==========================================================

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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year + 543}';
  }

  // ==========================================================
  // Card Decoration
  // ==========================================================

  BoxDecoration _cardDecoration(double radius) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.surfaceBorder),
    );
  }
}

// ============================================================
// Section Label
// ============================================================

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.mutedText,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

// ============================================================
// Square Icon Button
// ============================================================

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool accent;

  const _SquareIconButton({
    required this.icon,
    required this.onPressed,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: accent
              ? AppColors.accentSurface
              : AppColors.subtleSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(
          icon,
          size: 16,
          color: accent ? AppColors.accent : AppColors.secondaryText,
        ),
      ),
    );
  }
}

// ============================================================
// Mini Bars
// ============================================================

class _MiniBars extends StatelessWidget {
  const _MiniBars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 25,
      height: 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _bar(15, AppColors.accent),
          _bar(24, AppColors.cyan),
          _bar(20, AppColors.green),
        ],
      ),
    );
  }

  Widget _bar(double height, Color color) {
    return Container(
      width: 5,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ============================================================
// Dashboard Bottom Navigation
// ============================================================

class _DashboardBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DashboardBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _DashboardNavigationData(
      Icons.dashboard_outlined,
      Icons.dashboard_rounded,
      'Dashboard',
    ),
    _DashboardNavigationData(
      Icons.menu_book_outlined,
      Icons.menu_book_rounded,
      'สื่อการสอน',
    ),
    _DashboardNavigationData(
      Icons.chat_bubble_outline,
      Icons.chat_bubble_rounded,
      'แชทบอท',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(7, 8, 7, 14),
      decoration: const BoxDecoration(
        color: AppColors.navigation,
        border: Border(top: BorderSide(color: AppColors.navigationBorder)),
      ),
      child: Row(
        children: List.generate(_items.length, (index) {
          final item = _items[index];

          final selected = currentIndex == index;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == _items.length - 1 ? 0 : 7,
              ),
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 66,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentSurface
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.accentBorder
                          : AppColors.navigationBorder,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.navigationShadow,
                        offset: Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 24,
                        color: selected
                            ? AppColors.accent
                            : AppColors.secondaryText,
                      ),

                      const SizedBox(height: 5),

                      Text(
                        item.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: selected
                              ? AppColors.accent
                              : AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Dashboard Navigation Data
class _DashboardNavigationData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _DashboardNavigationData(this.icon, this.activeIcon, this.label);
}
