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
import 'chat.dart';

// ============================================================
// Dashboard Colors
// ============================================================

class _DashboardColors {
  static const background = Color(0xFF0E0D18);

  static const accent = Color(0xFF6C52E5);
  static const cyan = Color(0xFF22D3EE);
  static const green = Color(0xFF1BAF7A);

  static const surface = Color(0x0AFFFFFF);
  static const surfaceBorder = Color(0x12FFFFFF);
  static const innerSurface = Color(0x08FFFFFF);

  static const buttonSurface = Color(0x0DFFFFFF);
  static const buttonBorder = Color(0x1AFFFFFF);

  static const accentSurface = Color(0x266C52E5);
  static const greenSurface = Color(0x261BAF7A);

  static const primaryText = Color(0xFFFFFFFF);
  static const secondaryText = Color(0x99FFFFFF);
  static const mutedText = Color(0x73FFFFFF);
  static const faintText = Color(0x4DFFFFFF);

  static const danger = Color(0xFFFF7777);
  static const dangerButton = Color(0xFFD94848);

  static const navigation = Color(0xFF191820);
  static const navigationBorder = Color(0x26FFFFFF);
  static const searchBorder = Color(0x40FFFFFF);
}

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

  // ==========================================================
  // Subject
  // ==========================================================

  late Subject _subject;

  // ==========================================================
  // Emotion Data
  // ==========================================================

  int beforeStudentCount = 0;
  int beforePositivePercentage = 0;

  int afterStudentCount = 0;
  int afterPositivePercentage = 0;

  Map<String, int> beforeEmotionDistribution = {};
  Map<String, int> afterEmotionDistribution = {};

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

  bool _isLoadingHistory = false;

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

    distribution.forEach((emotion, count) {
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

    final total = positive + negative;

    if (total == 0) {
      return 0;
    }

    final positiveRatio = positive / total;
    final negativeRatio = negative / total;

    if (positiveRatio > negativeRatio) {
      return 1;
    }

    if (negativeRatio > positiveRatio) {
      return -1;
    }

    return 0;
  }

  // ==========================================================
  // Score Getters
  // ==========================================================

  double? get _beforeScore {
    if (beforeStudentCount == 0) {
      return null;
    }

    return _calculateEmotionScore(beforeEmotionDistribution);
  }

  double? get _afterScore {
    if (afterStudentCount == 0) {
      return null;
    }

    return _calculateEmotionScore(afterEmotionDistribution);
  }

  // ==========================================================
  // Engagement
  // ==========================================================

  int get _totalStudents {
    if (beforeStudentCount > afterStudentCount) {
      return beforeStudentCount;
    }

    return afterStudentCount;
  }

  int get _completedStudents {
    if (beforeStudentCount < afterStudentCount) {
      return beforeStudentCount;
    }

    return afterStudentCount;
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

    _loadEmotionData(date: DateTime.now());

    _startEmotionRealtimeListener();
  }

  // ==========================================================
  // Dispose
  // ==========================================================

  @override
  void dispose() {
    _emotionSubscription?.cancel();

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

  Future<void> _loadEmotionData({DateTime? date}) async {
    final selectedDate = date ?? DateTime.now();

    try {
      // --------------------------------------------------------
      // Records
      // --------------------------------------------------------

      final beforeRecords = await _emotionService.getEmotionRecordsByDate(
        subjectCode: _subject.subjectCode,
        date: selectedDate,
        type: 'before_class',
      );

      final afterRecords = await _emotionService.getEmotionRecordsByDate(
        subjectCode: _subject.subjectCode,
        date: selectedDate,
        type: 'after_class',
      );

      // --------------------------------------------------------
      // Distribution
      // --------------------------------------------------------

      final beforeDistribution = await _emotionService
          .getEmotionDistributionByDate(
            subjectCode: _subject.subjectCode,
            date: selectedDate,
            type: 'before_class',
          );

      final afterDistribution = await _emotionService
          .getEmotionDistributionByDate(
            subjectCode: _subject.subjectCode,
            date: selectedDate,
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
        afterStudentCount = afterTotal;

        beforePositivePercentage = beforeTotal == 0
            ? 0
            : ((beforePositive / beforeTotal) * 100).round();

        afterPositivePercentage = afterTotal == 0
            ? 0
            : ((afterPositive / afterTotal) * 100).round();

        beforeEmotionDistribution = beforeDistribution;
        afterEmotionDistribution = afterDistribution;
      });

      debugPrint('ก่อนเรียน: $beforeTotal คน');
      debugPrint('หลังเรียน: $afterTotal คน');
      debugPrint('ก่อนเรียน Positive: $beforePositivePercentage%');
      debugPrint('หลังเรียน Positive: $afterPositivePercentage%');
    } catch (error) {
      debugPrint('โหลด Emotion ไม่สำเร็จ: $error');

      if (!mounted) return;

      setState(() {
        beforeStudentCount = 0;
        afterStudentCount = 0;

        beforePositivePercentage = 0;
        afterPositivePercentage = 0;

        beforeEmotionDistribution = {};
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

          _loadEmotionData(date: _selectedDate ?? DateTime.now());
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
        setState(() {
          _sessionId = session['sessionId']?.toString();
          _isClassActive = true;
        });

        await _loadEmotionData();
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
        _isClassActive = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปิดห้องเรียนเรียบร้อยแล้ว')),
      );

      await _loadEmotionData();
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
        _sessionId = null;
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
  // Select Date
  // ==========================================================

  Future<void> _selectDate() async {
    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _thaiCalendarBottomSheet();
      },
    );

    if (pickedDate == null) return;

    await _loadSessionsByDate(pickedDate);
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

      await _loadEmotionData(date: date);

      if (!mounted) return;

      setState(() {
        _selectedSessions = sessions;
        _isLoadingHistory = false;
      });
    } catch (error) {
      debugPrint('โหลดข้อมูลย้อนหลังไม่สำเร็จ: $error');

      if (!mounted) return;

      setState(() {
        _selectedSessions = [];
        _isLoadingHistory = false;

        beforeStudentCount = 0;
        afterStudentCount = 0;

        beforePositivePercentage = 0;
        afterPositivePercentage = 0;

        beforeEmotionDistribution = {};
        afterEmotionDistribution = {};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีข้อมูลในวันที่เลือก'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ==========================================================
  // Chatbot
  // ==========================================================

  // ==========================================================
  // Chatbot
  // ==========================================================

  Future<void> _openChatbot() async {
    Map<String, dynamic>? emotionData;

    // ใช้ session ปัจจุบันก่อน
    String? sessionId = _sessionId;

    try {
      // ถ้าไม่มี sessionId ใน state ให้ดึงจาก Firestore ใหม่
      if (sessionId == null) {
        final activeSession = await _sessionService.getActiveSession(
          _subject.subjectCode,
        );

        sessionId = activeSession?['sessionId']?.toString();
      }

      final selectedDate = _selectedDate ?? DateTime.now();

      emotionData = await _emotionService.getEmotionSummaryForAI(
        subjectCode: _subject.subjectCode,
        date: selectedDate,
        type: 'before_class',
      );

      debugPrint('========== CHAT CONTEXT ==========');
      debugPrint('subjectCode: ${_subject.subjectCode}');
      debugPrint('sessionId: $sessionId');
      debugPrint('==================================');

      // Classroom Chat ต้องมี sessionId
      if (sessionId == null || sessionId.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบ Session ของห้องเรียนนี้')),
        );

        return;
      }
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

  // ==========================================================
  // Subject Management
  // ==========================================================

  Future<void> _showSubjectManagement() async {
    final action = await showModalBottomSheet<_SubjectManagementAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.50),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 11, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF19162A),
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
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'จัดการรายวิชา',
                  style: TextStyle(
                    color: _DashboardColors.primaryText,
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
                    color: _DashboardColors.faintText,
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
                      foregroundColor: _DashboardColors.secondaryText,
                      side: const BorderSide(
                        color: _DashboardColors.buttonBorder,
                      ),
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
    final color = destructive
        ? _DashboardColors.danger
        : _DashboardColors.accent;

    final background = destructive
        ? const Color(0x1FFF5A5A)
        : _DashboardColors.accentSurface;

    return Material(
      color: _DashboardColors.buttonSurface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(color: _DashboardColors.buttonBorder),
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
                        color: destructive
                            ? color
                            : _DashboardColors.primaryText,
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
                            : _DashboardColors.faintText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: destructive ? color : _DashboardColors.mutedText,
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.50),
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
                    color: Color(0xFF19162A),
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
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'แก้ไขข้อมูลรายวิชา',
                          style: TextStyle(
                            color: _DashboardColors.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'แก้ไขข้อมูลของรายวิชานี้',
                          style: TextStyle(
                            color: _DashboardColors.faintText,
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
                              color: _DashboardColors.danger,
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
                                  foregroundColor:
                                      _DashboardColors.secondaryText,
                                  side: const BorderSide(
                                    color: _DashboardColors.buttonBorder,
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
                                  backgroundColor: _DashboardColors.accent,
                                  foregroundColor: _DashboardColors.primaryText,
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
          style: const TextStyle(
            color: _DashboardColors.secondaryText,
            fontSize: 11,
          ),
        ),

        const SizedBox(height: 6),

        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            cursorColor: _DashboardColors.accent,
            style: const TextStyle(
              color: _DashboardColors.primaryText,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _DashboardColors.buttonSurface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: _DashboardColors.buttonBorder,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: _DashboardColors.buttonBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: _DashboardColors.accent,
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
      barrierColor: Colors.black.withOpacity(0.58),
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF211C32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _DashboardColors.buttonBorder),
          ),
          icon: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x1FFF5A5A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: _DashboardColors.danger,
            ),
          ),
          title: const Text(
            'ลบรายวิชานี้?',
            style: TextStyle(
              color: _DashboardColors.primaryText,
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
              color: _DashboardColors.secondaryText,
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
                foregroundColor: _DashboardColors.secondaryText,
                side: const BorderSide(color: _DashboardColors.buttonBorder),
              ),
              child: const Text('ยกเลิก'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _DashboardColors.dangerButton,
                foregroundColor: Colors.white,
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

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('ลบรายวิชาไม่สำเร็จ: $error'),
    ),
  );
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
      backgroundColor: _DashboardColors.background,

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
              Color(0xFF29344D),
              Color(0xFF19142E),
              _DashboardColors.background,
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

                    const _SectionLabel('ภาพรวมอารมณ์'),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 680,
                      child: PageView(
                        children: [
                          _emotionCard(
                            title: 'ก่อนเรียน',
                            studentCount: beforeStudentCount,
                            positivePercentage: beforePositivePercentage,
                            emotionData: beforeEmotionDistribution,
                          ),

                          _emotionCard(
                            title: 'หลังเรียน',
                            studentCount: afterStudentCount,
                            positivePercentage: afterPositivePercentage,
                            emotionData: afterEmotionDistribution,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    const _SectionLabel('การมีส่วนร่วม'),

                    const SizedBox(height: 9),

                    _buildEngagementCard(),

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
                    color: _DashboardColors.accent,
                    backgroundColor: Colors.transparent,
                  ),
                ),
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
                    color: _DashboardColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${_formatThaiDate(_selectedDate ?? DateTime.now())}$history',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DashboardColors.faintText,
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
              color: _DashboardColors.accentSurface,
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
                    color: _DashboardColors.primaryText,
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
                    color: _DashboardColors.faintText,
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
                    ? _DashboardColors.greenSurface
                    : _DashboardColors.accentSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: _isLoading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: _DashboardColors.primaryText,
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
                                ? _DashboardColors.green
                                : _DashboardColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 5),

                        Text(
                          _isClassActive ? 'กำลังสอน' : 'เปิดห้อง',
                          style: TextStyle(
                            color: _isClassActive
                                ? _DashboardColors.green
                                : _DashboardColors.accent,
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

  Widget _emotionCard({
    required String title,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _DashboardColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Students',
                  studentCount.toString(),
                  Icons.people_outline,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _summaryItem(
                  'Positive',
                  '$positivePercentage%',
                  Icons.sentiment_satisfied_alt_outlined,
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
                color: _DashboardColors.innerSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _DashboardColors.surfaceBorder),
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
                color: _DashboardColors.innerSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _DashboardColors.surfaceBorder),
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
        color: _DashboardColors.innerSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DashboardColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _DashboardColors.accentSurface,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _DashboardColors.accent, size: 18),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _DashboardColors.faintText,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    color: _DashboardColors.primaryText,
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

  // ==========================================================
  // Emotion Trend Chart
  // ==========================================================

  Widget _emotionTrendChart() {
    final beforeScore = _calculateEmotionScore(beforeEmotionDistribution);

    final afterScore = _calculateEmotionScore(afterEmotionDistribution);

    final hasBefore = beforeEmotionDistribution.isNotEmpty;

    final hasAfter = afterEmotionDistribution.isNotEmpty;

    if (!hasBefore) {
      return const Center(
        child: Text(
          'รอการประเมิน',
          style: TextStyle(color: _DashboardColors.faintText, fontSize: 12),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: -1,
        maxY: 1,

        gridData: FlGridData(
          show: true,
          horizontalInterval: 0.5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.06),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.04),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),

        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: 0.5,
              getTitlesWidget: (value, meta) {
                String text;

                switch (value.toStringAsFixed(1)) {
                  case '1.0':
                    text = 'ดีมาก';
                    break;
                  case '0.5':
                    text = 'ดี';
                    break;
                  case '0.0':
                    text = 'เฉยๆ';
                    break;
                  case '-0.5':
                    text = 'แย่';
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
                    color: _DashboardColors.mutedText,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const Text(
                    'ก่อนเรียน',
                    style: TextStyle(
                      color: _DashboardColors.mutedText,
                      fontSize: 9,
                    ),
                  );
                }

                if (value == 1) {
                  return const Text(
                    'หลังเรียน',
                    style: TextStyle(
                      color: _DashboardColors.mutedText,
                      fontSize: 9,
                    ),
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

        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, beforeScore),
              if (hasAfter) FlSpot(1, afterScore),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            color: _DashboardColors.primaryText,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: index == 0
                      ? _DashboardColors.accent
                      : _DashboardColors.green,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _DashboardColors.accent.withOpacity(0.07),
            ),
          ),
        ],

        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.white.withOpacity(0.10)),
            bottom: BorderSide(color: Colors.white.withOpacity(0.10)),
          ),
        ),

        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String label;

                if (spot.y > 0) {
                  label = 'อารมณ์ด้านบวก';
                } else if (spot.y == 0) {
                  label = 'อารมณ์สมดุล';
                } else {
                  label = 'อารมณ์ด้านลบ';
                }

                return LineTooltipItem(
                  '$label\n'
                  'คะแนน ${spot.y.toStringAsFixed(1)}',
                  const TextStyle(
                    color: Colors.white,
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
    final pending = _totalStudents - _completedStudents;

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(16),
      child: Row(
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
                  backgroundColor: _DashboardColors.buttonBorder,
                  color: _DashboardColors.accent,
                ),

                Center(
                  child: Text(
                    '$_engagementPercentage%',
                    style: const TextStyle(
                      color: _DashboardColors.primaryText,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _totalStudents == 0
                      ? 'ยังไม่มีข้อมูลการมีส่วนร่วม'
                      : '$_completedStudents '
                            'จาก $_totalStudents '
                            'คนกดครบ',
                  style: const TextStyle(
                    color: _DashboardColors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _totalStudents == 0
                      ? 'ข้อมูลจะแสดงเมื่อนักเรียนบันทึกอารมณ์'
                      : pending == 0
                      ? 'นักเรียนกดบันทึกครบแล้ว'
                      : '$pending คนยังบันทึกข้อมูลไม่ครบ',
                  style: const TextStyle(
                    color: _DashboardColors.faintText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const _MiniBars(),
        ],
      ),
    );
  }

  // ==========================================================
  // Bottom Actions
  // ==========================================================

  Widget _buildBottomActions() {
    return Row(
      children: [
        // ==================================================
        // PDF
        // ปิดใช้งานชั่วคราว
        // ==================================================
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.insert_drive_file_outlined, size: 17),
              label: const Text('PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _DashboardColors.faintText,
                disabledForegroundColor: _DashboardColors.faintText,
                backgroundColor: _DashboardColors.buttonSurface,
                side: const BorderSide(color: _DashboardColors.buttonBorder),
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
                backgroundColor: _DashboardColors.accent,
                foregroundColor: _DashboardColors.primaryText,
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
              color: Color(0xFF19162A),
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
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: _DashboardColors.accent,
                      ),

                      SizedBox(width: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เลือกวันที่',
                            style: TextStyle(
                              color: _DashboardColors.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            'ดูข้อมูลการเรียนย้อนหลัง',
                            style: TextStyle(
                              color: _DashboardColors.faintText,
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
                      color: _DashboardColors.accentSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _DashboardColors.accent.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          color: _DashboardColors.secondaryText,
                          size: 20,
                        ),

                        const SizedBox(width: 10),

                        Text(
                          _formatThaiDate(selectedDate),
                          style: const TextStyle(
                            color: _DashboardColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: _DashboardColors.accent,
                        surface: Color(0xFF19162A),
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
                            foregroundColor: _DashboardColors.primaryText,
                            side: const BorderSide(
                              color: _DashboardColors.buttonBorder,
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
                            backgroundColor: _DashboardColors.accent,
                            foregroundColor: _DashboardColors.primaryText,
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
      color: _DashboardColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _DashboardColors.surfaceBorder),
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
          color: _DashboardColors.mutedText,
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
              ? _DashboardColors.accentSurface
              : _DashboardColors.buttonSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(
          icon,
          size: 16,
          color: accent
              ? _DashboardColors.accent
              : _DashboardColors.secondaryText,
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
          _bar(15, _DashboardColors.accent),
          _bar(24, _DashboardColors.cyan),
          _bar(20, _DashboardColors.green),
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
        color: _DashboardColors.navigation,
        border: Border(
          top: BorderSide(color: _DashboardColors.navigationBorder),
        ),
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
                    color: const Color(0x40191820),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? _DashboardColors.searchBorder
                          : const Color(0x1A928B8B),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
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
                            ? _DashboardColors.primaryText
                            : _DashboardColors.secondaryText,
                      ),

                      const SizedBox(height: 5),

                      Text(
                        item.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: selected
                              ? _DashboardColors.primaryText
                              : _DashboardColors.secondaryText,
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

// ============================================================
// Dashboard Navigation Data
// ============================================================

class _DashboardNavigationData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _DashboardNavigationData(this.icon, this.activeIcon, this.label);
}
