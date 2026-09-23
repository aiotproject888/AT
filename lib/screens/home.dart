import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../services/subject_service.dart';
import '../widgets/subjects_card.dart';
import '../services/session_service.dart';
import 'chat.dart';
import '../constants/app_colors.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override

  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {

  int currentIndex = 0;

  // ============================================================

  // Subjects

  // ============================================================

  List<Subject> subjects = [];

  final SubjectService _subjectService = SubjectService();

  final SessionService _sessionService = SessionService();

  String? _activeSubjectCode;

  bool _isLoadingSubjects = true;

  String? _loadError;

  String _searchQuery = '';

  String _sortMode = 'ล่าสุดก่อน';

  bool _isDeleteMode = false;

  final Set<String> _selectedSubjects = {};

  // ============================================================

  // Search

  // ============================================================

  List<Subject> get _filteredSubjects {

    final query = _searchQuery.trim().toLowerCase();

    final result = subjects.where((subject) {

      if (query.isEmpty) {

        return true;

      }

      return subject.subjectName.toLowerCase().contains(query) ||

          subject.subjectCode.toLowerCase().contains(query);

    }).toList();

    switch (_sortMode) {

      case 'ล่าสุดก่อน':

        return result.reversed.toList();

      case 'เก่าสุดก่อน':

        return result;

      case 'ชื่อวิชา A-Z':

        result.sort(

          (a, b) => a.subjectName.toLowerCase().compareTo(

            b.subjectName.toLowerCase(),

          ),

        );

        break;

      case 'ชื่อวิชา Z-A':

        result.sort(

          (a, b) => b.subjectName.toLowerCase().compareTo(

            a.subjectName.toLowerCase(),

          ),

        );

        break;

    }

    return result;

  }

  // ============================================================

  // Init

  // ============================================================

  @override

  void initState() {

    super.initState();

    _loadSubjects();

    _loadCurrentSession();

  }

  // ============================================================

  // Load Subjects

  // ============================================================

  Future<void> _loadSubjects() async {

    setState(() {

      _isLoadingSubjects = true;

      _loadError = null;

    });

    try {

      final data = await _subjectService.getSubjects();

      if (!mounted) return;

      setState(() {

        subjects = data;

        _isLoadingSubjects = false;

      });

    } catch (error) {

      debugPrint('เกิดข้อผิดพลาดในการโหลดรายวิชา: $error');

      if (!mounted) return;

      setState(() {

        _isLoadingSubjects = false;

        _loadError = 'ไม่สามารถโหลดรายวิชาได้';

      });

    }

  }

  // ============================================================

  // Build

  // ============================================================

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: currentIndex == 0 && !_isDeleteMode
          ? Padding(
              padding: const EdgeInsets.only(right: 18, bottom: 10),
              child: FloatingActionButton(
                mini: true,
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                elevation: 5,
                highlightElevation: 3,
                hoverElevation: 3,
                splashColor: AppColors.accent.withOpacity(0.16),
                onPressed: _showAddSubjectDialog,
                child: const Icon(Icons.add, size: 34),
              ),
            )
          : null,
      bottomNavigationBar: _HomeBottomNavigation(
        currentIndex: currentIndex,
        onTap: _onNavigationTap,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.headerGradientStart,
              AppColors.headerGradientMid,
              AppColors.background,
              AppColors.background,
            ],
            stops: [0.0, 0.14, 0.30, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildSubjectBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================

  // Header

  // ============================================================

Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'รายวิชาของฉัน',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    height: 1.08,
                  ),
                ),
              ),
              _SquareIconButton(
                icon: _isDeleteMode
                    ? Icons.close_rounded
                    : Icons.more_horiz_rounded,
                onPressed: () {
                  setState(() {
                    _isDeleteMode = !_isDeleteMode;
                    _selectedSubjects.clear();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'ยินดีตอนรับ',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.searchBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.navigationShadow,
                        offset: Offset(0, 3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                    ),
                    cursorColor: AppColors.accent,
                    decoration: const InputDecoration(
                      hintText: 'ค้นหารายวิชา',
                      hintStyle: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.mutedText,
                        size: 21,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SmallActionButton(
                icon: Icons.tune_rounded,
                onPressed: _showSortDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================

  // Subject Body

  // ============================================================

  Widget _buildSubjectBody() {

    // ==========================================================

    // Loading

    // ==========================================================

    if (_isLoadingSubjects) {

      return const Center(

        child: CircularProgressIndicator(

          strokeWidth: 2,

          color: AppColors.accent,

        ),

      );

    }

    // ==========================================================

    // Error

    // ==========================================================

    if (_loadError != null) {

      return Center(

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Text(

              _loadError!,

              style: const TextStyle(

                color: AppColors.secondaryText,

                fontSize: 15,

              ),

            ),

            const SizedBox(height: 12),

            TextButton.icon(

              onPressed: _loadSubjects,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('ลองใหม่'),

              style: TextButton.styleFrom(foregroundColor: AppColors.accent),

            ),

          ],

        ),

      );

    }

    final visibleSubjects = _filteredSubjects;

    // ==========================================================

    // ไม่มีรายวิชา

    // ==========================================================

    if (subjects.isEmpty) {

      return const _EmptySubjects();

    }

    // ==========================================================

    // Search ไม่พบ

    // ==========================================================

    if (visibleSubjects.isEmpty) {

      return const _NoSearchResults();

    }

    // ==========================================================

    // รายการรายวิชา

    // ==========================================================

    return Stack(

      children: [

        RefreshIndicator(

          color: AppColors.accent,

          onRefresh: () async {

            await Future.wait([_loadSubjects(), _loadCurrentSession()]);

          },

          child: ListView.builder(

            physics: const AlwaysScrollableScrollPhysics(),

            padding: EdgeInsets.fromLTRB(

              22,

              12,

              22,

              _isDeleteMode && _selectedSubjects.isNotEmpty ? 170 : 110,

            ),

            itemCount: visibleSubjects.length,

            itemBuilder: (context, index) {

              final subject = visibleSubjects[index];

              return Padding(

                padding: const EdgeInsets.only(bottom: 14),

                child: Row(

                  children: [

                    if (_isDeleteMode)

                      Padding(

                        padding: const EdgeInsets.only(right: 8),

                        child: Checkbox(

                          value: _selectedSubjects.contains(

                            subject.subjectCode,

                          ),

                          onChanged: (value) {

                            setState(() {

                              if (value == true) {

                                _selectedSubjects.add(subject.subjectCode);

                              } else {

                                _selectedSubjects.remove(subject.subjectCode);

                              }

                            });

                          },

                          activeColor: AppColors.accent,

                          checkColor: AppColors.onAccent,

                          side: const BorderSide(

                            color: AppColors.secondaryText,

                          ),

                        ),

                      ),

                    Expanded(

                      child: SubjectCard(

                        subject: subject,

                        isActive: _activeSubjectCode == subject.subjectCode,

                        onReturn: _refreshHomeData,

                      ),

                    ),

                  ],

                ),

              );

            },

          ),

        ),

        if (_isDeleteMode && _selectedSubjects.isNotEmpty)

          Positioned(

            left: 30,

            right: 30,

            bottom: 25,

            child: SizedBox(

              height: 46,

              child: ElevatedButton.icon(

                onPressed: _deleteSelectedSubjects,

                icon: const Icon(

                  Icons.delete_outline_rounded,

                  color: AppColors.onAccent,

                ),

                label: Text(

                  'ลบวิชาที่เลือก (${_selectedSubjects.length})',

                  style: const TextStyle(color: AppColors.onAccent, fontSize: 15),

                ),

                style: ElevatedButton.styleFrom(

                  backgroundColor: AppColors.dangerButton,

                  elevation: 0,

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(10),

                  ),

                ),

              ),

            ),

          ),

      ],

    );

  }

  Future<void> _refreshHomeData() async {

    await Future.wait([_loadSubjects(), _loadCurrentSession()]);

  }

  Future<void> _deleteSelectedSubjects() async {

    if (_selectedSubjects.isEmpty) return;

    final count = _selectedSubjects.length;

    final confirmed = await showDialog<bool>(

      context: context,

      builder: (context) {

        return AlertDialog(

          backgroundColor: AppColors.dialogBackground,

          title: const Text(

            'ยืนยันการลบรายวิชา',

            style: TextStyle(color: AppColors.primaryText),

          ),

          content: Text(

            'ต้องการลบ $count รายวิชาที่เลือกหรือไม่?\n\nข้อมูลห้องเรียนและข้อมูลอารมณ์ของรายวิชาเหล่านี้จะถูกลบด้วย',

            style: const TextStyle(color: AppColors.secondaryText),

          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context, false);

              },

              child: const Text(

                'ยกเลิก',

                style: TextStyle(color: AppColors.secondaryText),

              ),

            ),

            TextButton(

              onPressed: () {

                Navigator.pop(context, true);

              },

              child: const Text(

                'ลบ',

                style: TextStyle(color: AppColors.danger),

              ),

            ),

          ],

        );

      },

    );

    if (confirmed != true) return;

    final selectedCodes = List<String>.from(_selectedSubjects);

    try {

      for (final subjectCode in selectedCodes) {

        await _subjectService.deleteSubject(subjectCode);

      }

      if (!mounted) return;

      setState(() {

        _selectedSubjects.clear();

        _isDeleteMode = false;

      });

      await _refreshHomeData();

      if (!mounted) return;

      ScaffoldMessenger.of(

        context,

      ).showSnackBar(SnackBar(content: Text('ลบ $count รายวิชาเรียบร้อยแล้ว')));

    } catch (error) {

      debugPrint('เกิดข้อผิดพลาดในการลบรายวิชา: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(

        context,

      ).showSnackBar(const SnackBar(content: Text('ไม่สามารถลบรายวิชาได้')));

    }

  }

  // ============================================================

  // Current Session

  // ============================================================

  Future<void> _loadCurrentSession() async {

    try {

      final session = await _sessionService.getCurrentSession();

      debugPrint('CURRENT SESSION: $session');

      if (!mounted) return;

      if (session == null) {

        setState(() {

          _activeSubjectCode = null;

        });

        return;

      }

      final status = session['status']?.toString();

      final subjectCode = session['subjectCode']?.toString();

      if (status == 'active' && subjectCode != null) {

        setState(() {

          _activeSubjectCode = subjectCode.trim();

        });

      } else {

        setState(() {

          _activeSubjectCode = null;

        });

      }

    } catch (e) {

      debugPrint('โหลดสถานะห้องไม่สำเร็จ: $e');

      if (!mounted) return;

      setState(() {

        _activeSubjectCode = null;

      });

    }

  }

  // ============================================================

  // SORT DIALOG

  // ============================================================

  void _showSortDialog() {

    showModalBottomSheet<void>(

      context: context,

      backgroundColor: AppColors.dialogBackground,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      builder: (context) {

        return SafeArea(

          child: Padding(

            padding: const EdgeInsets.fromLTRB(22, 20, 22, 25),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const Text(

                  'เรียงลำดับ',

                  style: TextStyle(

                    color: AppColors.primaryText,

                    fontSize: 19,

                    fontWeight: FontWeight.w800,

                  ),

                ),

                const SizedBox(height: 12),

                _SortOption(

                  icon: Icons.schedule_rounded,

                  title: 'ล่าสุดก่อน',

                  selected: _sortMode == 'ล่าสุดก่อน',

                  onTap: () {

                    _changeSort('ล่าสุดก่อน');

                    Navigator.pop(context);

                  },

                ),

                _SortOption(

                  icon: Icons.history_rounded,

                  title: 'เก่าสุดก่อน',

                  selected: _sortMode == 'เก่าสุดก่อน',

                  onTap: () {

                    _changeSort('เก่าสุดก่อน');

                    Navigator.pop(context);

                  },

                ),

                _SortOption(

                  icon: Icons.sort_by_alpha_rounded,

                  title: 'ชื่อวิชา A-Z',

                  selected: _sortMode == 'ชื่อวิชา A-Z',

                  onTap: () {

                    _changeSort('ชื่อวิชา A-Z');

                    Navigator.pop(context);

                  },

                ),

                _SortOption(

                  icon: Icons.sort_by_alpha_rounded,

                  title: 'ชื่อวิชา Z-A',

                  selected: _sortMode == 'ชื่อวิชา Z-A',

                  onTap: () {

                    _changeSort('ชื่อวิชา Z-A');

                    Navigator.pop(context);

                  },

                ),

              ],

            ),

          ),

        );

      },

    );

  }

  void _changeSort(String mode) {

    setState(() {

      _sortMode = mode;

    });

  }

  // ============================================================

  // Navigation

  // ============================================================

  Future<void> _onNavigationTap(int index) async {

    // ==========================================================

    // วิชา

    // ==========================================================

    if (index == 0) {

      // HomeScreen คือหน้าวิชาอยู่แล้ว

      // ไม่ต้อง Navigator.push ซ้ำ

      return;

    }

    // ==========================================================

    // แชทบอท

    // ==========================================================

    if (index == 1) {

      await Navigator.push(

        context,

        MaterialPageRoute<void>(builder: (context) => const ChatScreen()),

      );

      // ========================================================

      // เมื่อกลับจาก ChatScreen

      // โหลดข้อมูลล่าสุดอีกครั้ง

      // ========================================================

      if (!mounted) return;

      await Future.wait([_loadSubjects(), _loadCurrentSession()]);

      return;

    }

  }

  // ============================================================

  // Add Subject Dialog

  // ============================================================

  void _showAddSubjectDialog() {

    showDialog<void>(

      context: context,

      barrierDismissible: true,

      barrierColor: AppColors.modalBarrier,

      builder: (context) {

        return AddSubjectDialog(

          onAdd: (subject) {

            if (!mounted) return;

            setState(() {

              subjects.insert(0, subject);

            });

          },

        );

      },

    );

  }

}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SquareIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Icon(icon, color: AppColors.secondaryText, size: 20),
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SmallActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: const Icon(
            Icons.sort_rounded,
            color: AppColors.secondaryText,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {

  final IconData icon;

  final String title;

  final bool selected;

  final VoidCallback onTap;

  const _SortOption({

    required this.icon,

    required this.title,

    required this.selected,

    required this.onTap,

  });

  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 6),

      child: Material(

        color: selected ? AppColors.accentSurface : AppColors.transparent,

        borderRadius: BorderRadius.circular(14),

        child: ListTile(

          contentPadding: const EdgeInsets.symmetric(horizontal: 12),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(14),

          ),

          leading: Icon(

            icon,

            color: selected ? AppColors.accent : AppColors.secondaryText,

          ),

          title: Text(

            title,

            style: TextStyle(

              color: selected ? AppColors.accent : AppColors.primaryText,

              fontSize: 13,

              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,

            ),

          ),

          trailing: Icon(

            selected

                ? Icons.check_circle_rounded

                : Icons.chevron_right_rounded,

            color: selected ? AppColors.accent : AppColors.mutedText,

          ),

          onTap: onTap,

        ),

      ),

    );

  }

}

class _HomeBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _HomeBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavigationData(Icons.grid_view_outlined, Icons.grid_view_rounded, 'วิชา'),
    _NavigationData(
      Icons.chat_bubble_outline,
      Icons.chat_bubble_rounded,
      'แชทบอท',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      decoration: const BoxDecoration(
        color: AppColors.navigation,
        border: Border(
          top: BorderSide(color: AppColors.navigationBorder),
        ),
      ),
      child: Row(
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final selected = currentIndex == index;

          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 58,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accentSurface
                      : AppColors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      size: 23,
                      color: selected
                          ? AppColors.accent
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected
                            ? AppColors.accent
                            : AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ================================================================

// Navigation Data

// ================================================================

class _NavigationData {

  final IconData icon;

  final IconData activeIcon;

  final String label;

  const _NavigationData(this.icon, this.activeIcon, this.label);

}

// ================================================================

// Empty Subjects

// ================================================================

class _EmptySubjects extends StatelessWidget {

  const _EmptySubjects();

  @override

  Widget build(BuildContext context) {

    return Center(

      child: Container(

        margin: const EdgeInsets.symmetric(horizontal: 30),

        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),

        decoration: BoxDecoration(

          color: AppColors.surface,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(color: AppColors.surfaceBorder),

          boxShadow: const [

            BoxShadow(

              color: AppColors.navigationShadow,

              offset: Offset(0, 6),

              blurRadius: 18,

            ),

          ],

        ),

        child: const Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Text(

              'ยังไม่มีรายวิชา',

              style: TextStyle(

                color: AppColors.primaryText,

                fontSize: 20,

                fontWeight: FontWeight.w600,

                letterSpacing: -0.3,

              ),

            ),

            SizedBox(height: 5),

            Text(

              'กดปุ่ม + เพื่อเพิ่มรายวิชา',

              style: TextStyle(

                color: AppColors.secondaryText,

                fontSize: 13,

              ),

            ),

          ],

        ),

      ),

    );

  }

}

// ================================================================

// No Search Results

// ================================================================

class _NoSearchResults extends StatelessWidget {

  const _NoSearchResults();

  @override

  Widget build(BuildContext context) {

    return Center(

      child: Container(

        margin: const EdgeInsets.symmetric(horizontal: 30),

        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),

        decoration: BoxDecoration(

          color: AppColors.surface,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(color: AppColors.surfaceBorder),

        ),

        child: const Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Icon(

              Icons.search_off_rounded,

              color: AppColors.mutedText,

              size: 34,

            ),

            SizedBox(height: 10),

            Text(

              'ไม่พบรายวิชาที่ค้นหา',

              style: TextStyle(

                color: AppColors.primaryText,

                fontSize: 15,

                fontWeight: FontWeight.w500,

              ),

            ),

          ],

        ),

      ),

    );

  }

}

// ================================================================

// Add Subject Dialog

// ================================================================

class AddSubjectDialog extends StatefulWidget {

  final ValueChanged<Subject> onAdd;

  const AddSubjectDialog({super.key, required this.onAdd});

  @override

  State<AddSubjectDialog> createState() => _AddSubjectDialogState();

}

class _AddSubjectDialogState extends State<AddSubjectDialog> {

  final nameController = TextEditingController();

  final yearController = TextEditingController();

  final semesterController = TextEditingController();

  final codeController = TextEditingController();

  final SubjectService _subjectService = SubjectService();

  bool _isSaving = false;

  @override

  void dispose() {

    nameController.dispose();

    yearController.dispose();

    semesterController.dispose();

    codeController.dispose();

    super.dispose();

  }

  @override

  Widget build(BuildContext context) {

    return Dialog(

      alignment: Alignment.bottomCenter,

      insetPadding: const EdgeInsets.symmetric(horizontal: 14),

      backgroundColor: AppColors.transparent,

      elevation: 0,

      child: Container(

        width: double.infinity,

        constraints: const BoxConstraints(maxWidth: 420, minHeight: 461),

        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),

        decoration: BoxDecoration(

          color: AppColors.dialogBackground,

          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),

          border: Border.all(color: AppColors.dialogBorder),

        ),

        child: SingleChildScrollView(

          child: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const Text(

                'เพิ่มรายวิชาใหม่',

                style: TextStyle(

                  color: AppColors.primaryText,

                  fontSize: 20,

                  fontWeight: FontWeight.w600,

                ),

              ),

              const SizedBox(height: 3),

              const Text(

                'กรอกข้อมูลวิชาที่ต้องการเพิ่ม',

                style: TextStyle(color: AppColors.secondaryText, fontSize: 15),

              ),

              const SizedBox(height: 18),

              const _FieldLabel('ชื่อวิชา*'),

              const SizedBox(height: 6),

              _SubjectTextField(controller: nameController),

              const SizedBox(height: 12),

              Row(

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        const _FieldLabel('ปีการศึกษา*'),

                        const SizedBox(height: 6),

                        _SubjectTextField(controller: yearController),

                      ],

                    ),

                  ),

                  const SizedBox(width: 9),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        const _FieldLabel('ภาคเรียน*'),

                        const SizedBox(height: 6),

                        _SubjectTextField(controller: semesterController),

                      ],

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 12),

              const _FieldLabel('รหัสวิชา*'),

              const SizedBox(height: 6),

              _SubjectTextField(controller: codeController),

              const SizedBox(height: 24),

              SizedBox(

                width: double.infinity,

                height: 46,

                child: ElevatedButton.icon(

                  onPressed: _isSaving ? null : _addSubject,

                  icon: _isSaving

                      ? const SizedBox(

                          width: 18,

                          height: 18,

                          child: CircularProgressIndicator(

                            strokeWidth: 2,

                            color: AppColors.green,

                          ),

                        )

                      : const Icon(Icons.add, color: AppColors.onAccent, size: 25),

                  label: Text(

                    _isSaving ? 'กำลังบันทึก...' : 'เพิ่มรายวิชา',

                    style: const TextStyle(

                      color: AppColors.onAccent,

                      fontSize: 16,

                      fontWeight: FontWeight.w400,

                    ),

                  ),

                  style: ElevatedButton.styleFrom(

                    elevation: 0,

                    backgroundColor: AppColors.green,

                    foregroundColor: AppColors.onAccent,

                    disabledBackgroundColor: AppColors.disabledAccent,

                    disabledForegroundColor: AppColors.onAccent,

                    shape: RoundedRectangleBorder(

                      borderRadius: BorderRadius.circular(12),

                    ),

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

  // ============================================================

  // Add Subject

  // ============================================================

  Future<void> _addSubject() async {

    final subjectName = nameController.text.trim();

    final year = yearController.text.trim();

    final semester = semesterController.text.trim();

    final subjectCode = codeController.text.trim();

    // ==========================================================

    // Validation

    // ==========================================================

    if (subjectName.isEmpty ||

        year.isEmpty ||

        semester.isEmpty ||

        subjectCode.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง')),

      );

      return;

    }

    // ==========================================================

    // สร้าง Subject

    // ==========================================================

    final subject = Subject(

      subjectName: subjectName,

      year: year,

      semester: semester,

      subjectCode: subjectCode,

    );

    setState(() {

      _isSaving = true;

    });

    // ==========================================================

    // บันทึกผ่าน SubjectService

    // ==========================================================

    try {

      await _subjectService.createSubject(subject);

      if (!mounted) return;

      widget.onAdd(subject);

      Navigator.pop(context);

    } catch (error) {

      debugPrint('เกิดข้อผิดพลาดในการบันทึกวิชา: $error');

      if (!mounted) return;

      setState(() {

        _isSaving = false;

      });

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('ไม่สามารถบันทึกรายวิชาได้')),

      );

    }

  }

}

// ================================================================

// Field Label

// ================================================================

class _FieldLabel extends StatelessWidget {

  final String text;

  const _FieldLabel(this.text);

  @override

  Widget build(BuildContext context) {

    return Text(

      text,

      style: const TextStyle(color: AppColors.secondaryText, fontSize: 15),

    );

  }

}

// ================================================================

// Subject Text Field

// ================================================================

class _SubjectTextField extends StatelessWidget {

  final TextEditingController controller;

  const _SubjectTextField({required this.controller});

  @override

  Widget build(BuildContext context) {

    return SizedBox(

      height: 44,

      child: TextField(

        controller: controller,

        style: const TextStyle(color: AppColors.primaryText, fontSize: 14),

        cursorColor: AppColors.accent,

        decoration: InputDecoration(

          filled: true,

          fillColor: AppColors.lightSurface,

          contentPadding: const EdgeInsets.symmetric(

            horizontal: 10,

            vertical: 8,

          ),

          enabledBorder: OutlineInputBorder(

            borderRadius: BorderRadius.circular(12),

            borderSide: const BorderSide(color: AppColors.inputBorder),

          ),

          border: OutlineInputBorder(

            borderRadius: BorderRadius.circular(12),

            borderSide: const BorderSide(color: AppColors.inputBorder),

          ),

          focusedBorder: OutlineInputBorder(

            borderRadius: BorderRadius.circular(12),

            borderSide: const BorderSide(color: AppColors.accent, width: 1.4),

          ),

        ),

      ),

    );

  }

}