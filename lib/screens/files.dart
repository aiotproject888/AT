import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:microsoft_viewer/microsoft_viewer.dart';

import 'chat.dart';
import '../services/emotion_service.dart';
import '../services/session_service.dart';
import '../constants/app_colors.dart';

class MaterialScreen extends StatefulWidget {
  final String subjectName;
  final String subjectCode;

  const MaterialScreen({
    super.key,
    required this.subjectName,
    required this.subjectCode,
  });

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  // ============================================================
  // BACKEND
  // ============================================================

  static const String _backendBaseUrl =
      'https://groq-backend-yzr8.onrender.com';

  // ============================================================
  // STATE
  // ============================================================

  static const int _maxFileSize = 50 * 1024 * 1024; // 50 MB
  int _selectedCategory = 0;

  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  bool _isUploading = false;
  bool _isLoadingFiles = true;

  bool _isLoadingOverlay = false;
  String _loadingText = 'กำลังโหลดข้อมูล...';

  double _uploadProgress = 0;

  String _uploadFileName = '';

  String _sortMode = 'ล่าสุดก่อน';

  final List<String> _categories = ['ทั้งหมด', 'เอกสาร', 'สไลด์', 'อื่นๆ'];

  List<_MaterialFile> _files = [];

  // ============================================================
  // CHATBOT / EMOTION / SESSION
  // ============================================================

  final EmotionService _emotionService = EmotionService();
  final SessionService _sessionService = SessionService();

  String? _sessionId;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadFiles();
    _loadActiveSession();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD FILES FROM FIRESTORE
  // ============================================================

  Future<void> _loadFiles() async {
    if (mounted) {
      setState(() {
        _isLoadingFiles = true;
      });
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lesson_materials')
          .where('subjectCode', isEqualTo: widget.subjectCode)
          .get();

      final files = snapshot.docs
          .map((doc) => _MaterialFile.fromFirestore(doc))
          .toList();

      _sortFiles(files);

      if (!mounted) return;

      setState(() {
        _files = files;
        _isLoadingFiles = false;
      });

      debugPrint('Loaded ${files.length} files');

      debugPrint('Subject Code: ${widget.subjectCode}');
    } catch (error) {
      debugPrint('Load Files Error: $error');

      if (!mounted) return;

      setState(() {
        _isLoadingFiles = false;
      });

      _showError('โหลดไฟล์ไม่สำเร็จ\n$error');
    }
  }

  // ============================================================
  // SORT
  // ============================================================

  void _sortFiles(List<_MaterialFile> files) {
    switch (_sortMode) {
      case 'ล่าสุดก่อน':
        files.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
        break;

      case 'เก่าสุดก่อน':
        files.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
        break;

      case 'ชื่อไฟล์ A-Z':
        files.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;

      case 'ขนาดไฟล์':
        files.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
    }
  }

  // ============================================================
  // FILTERED FILES
  // ============================================================

  List<_MaterialFile> get _filteredFiles {
    final result = _files.where((file) {
      final matchesCategory =
          _selectedCategory == 0 ||
          file.category == _categories[_selectedCategory];

      final matchesSearch =
          _searchText.isEmpty ||
          file.name.toLowerCase().contains(_searchText.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    return result;
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

  void _onDashboardNavigationTap(int index) {
    switch (index) {
      case 0:
        Navigator.pop(context);
        return;

      case 1:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => MaterialScreen(
              subjectName: widget.subjectName,
              subjectCode: widget.subjectCode,
            ),
          ),
        );
        return;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => ChatScreen(
              subjectCode: widget.subjectCode,
              sessionId: _sessionId,
            ),
          ),
        );
        return;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 18),
                          _buildStorageOverview(),
                          const SizedBox(height: 18),
                          _buildSearchBar(),
                          const SizedBox(height: 14),
                          _buildCategoryTabs(),
                          const SizedBox(height: 18),
                          _UploadButton(onPressed: _showUploadDialog),
                          const SizedBox(height: 10),

                          // ============================================================
                          // FILE / AI LIMIT INFO
                          // ============================================================
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                255,
                                170,
                                169,
                                175,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color.fromARGB(
                                  255,
                                  7,
                                  7,
                                  7,
                                ).withValues(alpha: 0.20),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: AppColors.accent,
                                  size: 19,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'แนะนำไฟล์ไม่เกิน 50,000 ตัวอักษร เพื่อให้ AI อ่านเนื้อหาได้ครบถ้วน',
                                        style: TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'ขนาดไฟล์สูงสุด 50 MB ต่อ ไฟล์',
                                        style: TextStyle(
                                          color: AppColors.mutedText,
                                          fontSize: 11,
                                        ),
                                      ),

                                      //const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),
                          _buildFileHeader(),
                          const SizedBox(height: 10),
                          _buildFileList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _DashboardBottomNavigation(
        currentIndex: 1,
        onTap: _onDashboardNavigationTap,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        _SquareIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'สื่อการสอน',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subjectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        //const SizedBox(width: 10),
      ],
    );
  }

  // ============================================================
  // STORAGE OVERVIEW
  // ============================================================

  Widget _buildStorageOverview() {
    final totalBytes = _files.fold<int>(0, (sum, file) => sum + file.fileSize);

    final totalSize = _formatFileSize(totalBytes);

    final fileTypes = _files
        .map((file) => file.extension)
        .where((extension) => extension.isNotEmpty)
        .toSet()
        .length;

    DateTime? latestDate;

    if (_files.isNotEmpty) {
      latestDate = _files
          .map((file) => file.uploadedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    final latestText = latestDate == null ? '-' : _formatDate(latestDate);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _OverviewItem(
                  icon: Icons.folder_rounded,
                  title: 'ไฟล์ทั้งหมด',
                  value: '${_files.length}',
                  subtitle: 'ไฟล์',
                ),
              ),
              Container(width: 1, height: 42, color: AppColors.surfaceBorder),
              Expanded(
                child: _OverviewItem(
                  icon: Icons.category_rounded,
                  title: 'ประเภทไฟล์',
                  value: '$fileTypes',
                  subtitle: 'ประเภท',
                ),
              ),
              Container(width: 1, height: 42, color: AppColors.surfaceBorder),
              Expanded(
                child: _OverviewItem(
                  icon: Icons.storage_rounded,
                  title: 'พื้นที่ใช้งาน',
                  value: totalSize,
                  subtitle: 'ทั้งหมด',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.update_rounded,
                size: 15,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 7),
              const Text(
                'อัปเดตล่าสุด',
                style: TextStyle(color: AppColors.mutedText, fontSize: 11),
              ),
              const Spacer(),
              Text(
                latestText,
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.innerSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 13,
              ),
              cursorColor: AppColors.accent,
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.mutedText,
                  size: 21,
                ),
                hintText: 'ค้นหาไฟล์...',
                hintStyle: TextStyle(color: AppColors.faintText, fontSize: 13),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _SmallActionButton(
          icon: Icons.sort_rounded,
          onPressed: _showSortDialog,
        ),
      ],
    );
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 39,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.25)
                    : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.65)
                      : AppColors.surfaceBorder,
                ),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: selected
                        ? AppColors.accent
                        : AppColors.secondaryText,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // FILE HEADER
  // ============================================================

  Widget _buildFileHeader() {
    return Row(
      children: [
        const Text(
          'ไฟล์ทั้งหมด',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${_filteredFiles.length}',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        Text(
          _sortMode,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 10),
        ),
      ],
    );
  }

  // ============================================================
  // FILE LIST
  // ============================================================

  Widget _buildFileList() {
    if (_isLoadingFiles) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 45),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_filteredFiles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        for (int i = 0; i < _filteredFiles.length; i++) ...[
          _buildFileCard(_filteredFiles[i]),
          if (i != _filteredFiles.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ============================================================
  // FILE CARD
  // ============================================================

  Widget _buildFileCard(_MaterialFile file) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _viewFile(file);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            _FileIcon(icon: file.icon, extension: file.extension),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        file.extension,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _dot(),
                      Text(
                        file.size,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 9.5,
                        ),
                      ),
                      _dot(),
                      Flexible(
                        child: Text(
                          file.date,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _StatusChip(status: file.status),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Column(
              children: [
                _FileActionButton(
                  icon: Icons.download_rounded,
                  onPressed: () {
                    _downloadFile(file);
                  },
                ),
                const SizedBox(height: 5),
                _FileActionButton(
                  icon: Icons.more_vert_rounded,
                  onPressed: () {
                    _showFileMenu(file);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        '•',
        style: TextStyle(color: AppColors.faintText, fontSize: 8),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final bool isSearch = _searchText.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.folder_open_rounded,
            size: 42,
            color: AppColors.mutedText,
          ),
          const SizedBox(height: 12),
          Text(
            isSearch ? 'ไม่พบไฟล์ที่ค้นหา' : 'ยังไม่มีสื่อการสอน',
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isSearch
                ? 'ลองค้นหาด้วยชื่อไฟล์อื่น'
                : 'กดปุ่ม "อัปโหลดไฟล์" เพื่อเพิ่มสื่อการสอน',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPLOAD DIALOG
  // ============================================================

  void _showUploadDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.dialogBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dragHandle,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'เพิ่มสื่อการสอน',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'เลือกวิธีเพิ่มไฟล์ที่ต้องการ',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 20),
                _UploadOption(
                  icon: Icons.upload_file_rounded,
                  title: 'อัปโหลดไฟล์',
                  subtitle: 'PDF, PPTX, DOCX',
                  onTap: () {
                    Navigator.pop(context);

                    Future.delayed(
                      const Duration(milliseconds: 200),
                      _pickAndUploadFile,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PICK FILE
  // ============================================================

  Future<void> _pickAndUploadFile() async {
    if (_isUploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'pptx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;

      final bytes = pickedFile.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception('ไม่สามารถอ่านข้อมูลไฟล์ได้');
      }

      // ตรวจสอบขนาดไฟล์
      if (bytes.length > _maxFileSize) {
        final fileSize = _formatFileSize(bytes.length);

        if (mounted) {
          _showError(
            'ไฟล์มีขนาด $fileSize\n'
            'ขนาดไฟล์สูงสุดที่รองรับคือ 50 MB ต่อไฟล์',
          );
        }

        return;
      }

      await _uploadFile(fileName: pickedFile.name, bytes: bytes);
    } catch (error) {
      debugPrint('Pick File Error: $error');

      if (mounted) {
        _showError('ไม่สามารถเลือกไฟล์ได้\n$error');
      }
    }
  }

  // ============================================================
  // UPLOAD + PROCESS FILE
  // ============================================================

  Future<void> _uploadFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadFileName = fileName;
    });

    _showLoading('กำลังเตรียมไฟล์...');

    try {
      // ========================================================
      // 1. FILE INFORMATION
      // ========================================================

      final extension = _getExtension(fileName);

      final contentType = _getContentType(fileName);

      final fileType = _getFileType(extension);

      final category = _getCategory(extension);

      final uploadedAt = DateTime.now();

      // ========================================================
      // 2. REQUEST PRESIGNED URL
      // ========================================================

      _updateLoading('กำลังเตรียมไฟล์สำหรับอัปโหลด...');

      final urlResponse = await http.post(
        Uri.parse('$_backendBaseUrl/api/materials/upload-url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fileName': fileName,
          'fileSize': bytes.length,
          'contentType': contentType,
        }),
      );

      if (urlResponse.statusCode != 200) {
        throw Exception(
          'ไม่สามารถสร้าง Upload URL ได้ '
          '(${urlResponse.statusCode})',
        );
      }

      debugPrint(
        'Upload URL Response: '
        '${urlResponse.body}',
      );

      final Map<String, dynamic> data = jsonDecode(urlResponse.body);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'ไม่สามารถสร้าง Upload URL ได้');
      }

      final uploadUrl = data['uploadUrl']?.toString();

      final storageKey = data['storageKey']?.toString();

      if (uploadUrl == null || uploadUrl.isEmpty) {
        throw Exception('Backend ไม่ได้ส่ง uploadUrl กลับมา');
      }

      if (storageKey == null || storageKey.isEmpty) {
        throw Exception('Backend ไม่ได้ส่ง storageKey กลับมา');
      }

      // ========================================================
      // 3. UPLOAD TO BACKBLAZE B2
      // ========================================================

      _updateLoading('กำลังอัปโหลดไฟล์...');

      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      );

      if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
        throw Exception(
          'อัปโหลดไม่สำเร็จ '
          '(${uploadResponse.statusCode})\n'
          '${uploadResponse.body}',
        );
      }

      if (!mounted) return;

      setState(() {
        _uploadProgress = 0.5;
      });

      debugPrint('B2 Upload Success');

      // ========================================================
      // 4. PROCESS / EXTRACT TEXT
      // ========================================================

      _updateLoading('กำลังอ่านเนื้อหาในไฟล์...');

      String extractedText = '';

      String aiStatus = 'อัปโหลดแล้ว';

      setState(() {
        _uploadProgress = 0.6;
      });

      try {
        debugPrint('Starting material processing...');

        final processResponse = await http.post(
          Uri.parse('$_backendBaseUrl/api/materials/process'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'storageKey': storageKey,
            'fileName': fileName,
            'fileSize': bytes.length,
            'contentType': contentType,
          }),
        );

        debugPrint(
          'Process Response: '
          '${processResponse.statusCode}',
        );

        debugPrint(
          'Process Body: '
          '${processResponse.body}',
        );

        if (processResponse.statusCode == 200) {
          final processData =
              jsonDecode(processResponse.body) as Map<String, dynamic>;

          if (processData['success'] == true) {
            final extractedTextData = processData['extractedText'];

            // Backend ปัจจุบันส่ง:
            //
            // extractedText: {
            //   text: "...",
            //   type: "pdf"
            // }

            if (extractedTextData is Map) {
              extractedText = extractedTextData['text']?.toString() ?? '';
            } else if (extractedTextData is String) {
              // รองรับกรณี Backend
              // ส่ง String กลับมา
              extractedText = extractedTextData;
            }

            if (extractedText.trim().isNotEmpty) {
              aiStatus = 'อ่านเนื้อหาแล้ว';
            }

            debugPrint(
              'Extracted text length: '
              '${extractedText.length}',
            );
          } else {
            debugPrint(
              'Process failed: '
              '${processData['message']}',
            );
          }
        } else {
          debugPrint(
            'Process HTTP Error: '
            '${processResponse.statusCode}',
          );
        }
      } catch (processError) {
        // ถ้า Extract มีปัญหา
        // ไฟล์ B2 ยังถือว่า Upload สำเร็จ
        // จึงไม่ให้ทั้ง Upload ล้ม
        debugPrint('Process Error: $processError');
      }

      if (!mounted) return;

      setState(() {
        _uploadProgress = 0.85;
      });

      // ========================================================
      // 5. SAVE METADATA TO FIRESTORE
      // ========================================================

      _updateLoading('กำลังบันทึกข้อมูล...');

      final Map<String, dynamic> firestoreData = {
        'subjectCode': widget.subjectCode,

        'fileName': fileName,

        'fileType': fileType,

        'extension': extension,

        'category': category,

        'fileSize': bytes.length,

        'contentType': contentType,

        'storageKey': storageKey,

        'uploadedAt': FieldValue.serverTimestamp(),

        // ======================================================
        // AI STATUS
        // ======================================================
        'aiStatus': aiStatus,

        // ======================================================
        // EXTRACTED TEXT INFORMATION
        // ======================================================
        'extractedTextLength': extractedText.length,

        // ======================================================
        // ชั่วคราวสำหรับการทดสอบ
        //
        // เมื่อทำ Chunk/RAG แล้ว
        // เราจะไม่เก็บ text ทั้งหมดใน document นี้
        // ======================================================
        'extractedText': extractedText,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('lesson_materials')
          .add(firestoreData);

      debugPrint(
        'Firestore document created: '
        '${docRef.id}',
      );

      // ========================================================
      // 6. ADD TO LOCAL LIST
      // ========================================================

      _updateLoading('กำลังอัปเดตรายการไฟล์...');

      final materialFile = _MaterialFile(
        id: docRef.id,
        name: fileName,
        type: fileType,
        extension: extension.toUpperCase(),
        size: _formatFileSize(bytes.length),
        date: _formatDate(uploadedAt),
        category: category,
        status: aiStatus,
        icon: _getFileIcon(extension),
        fileSize: bytes.length,
        contentType: contentType,
        storageKey: storageKey,
        uploadedAt: uploadedAt,
      );

      if (!mounted) return;

      setState(() {
        _files.insert(0, materialFile);

        _uploadProgress = 1;
      });

      _sortFiles(_files);

      // ========================================================
      // 7. SUCCESS MESSAGE
      // ========================================================

      if (aiStatus == 'อ่านเนื้อหาแล้ว') {
        _showSuccess('อัปโหลด "$fileName" และอ่านเนื้อหาสำเร็จ');
      } else {
        _showSuccess('อัปโหลด "$fileName" สำเร็จ');
      }
    } catch (error) {
      debugPrint('Upload Error: $error');

      if (mounted) {
        _showError('อัปโหลดไฟล์ไม่สำเร็จ\n$error');
      }
    } finally {
      _hideLoading();

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadFileName = '';
          _uploadProgress = 0;
        });
      }
    }
  }

  // ============================================================
  // FILE TYPE
  // ============================================================

  String _getExtension(String fileName) {
    final index = fileName.lastIndexOf('.');

    if (index == -1) {
      return '';
    }

    return fileName.substring(index + 1).toLowerCase();
  }

  String _getFileType(String extension) {
    switch (extension) {
      case 'pdf':
      case 'docx':
        return 'เอกสาร';

      case 'pptx':
        return 'สไลด์';

      default:
        return 'อื่นๆ';
    }
  }

  String _getCategory(String extension) {
    return _getFileType(extension);
  }

  // ============================================================
  // CONTENT TYPE
  // ============================================================

  String _getContentType(String fileName) {
    final extension = _getExtension(fileName);

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      default:
        return 'application/octet-stream';
    }
  }

  // ============================================================
  // FILE ICON
  // ============================================================

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;

      case 'pptx':
        return Icons.slideshow_rounded;

      case 'docx':
        return Icons.description_rounded;

      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  // ============================================================
  // FILE SIZE
  // ============================================================

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime date) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ============================================================
  // SUCCESS / ERROR
  // ============================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.green,
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showComingSoon(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 1)),
    );
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
                  title: 'ชื่อไฟล์ A-Z',
                  selected: _sortMode == 'ชื่อไฟล์ A-Z',
                  onTap: () {
                    _changeSort('ชื่อไฟล์ A-Z');
                    Navigator.pop(context);
                  },
                ),
                _SortOption(
                  icon: Icons.data_usage_rounded,
                  title: 'ขนาดไฟล์',
                  selected: _sortMode == 'ขนาดไฟล์',
                  onTap: () {
                    _changeSort('ขนาดไฟล์');
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
      _sortFiles(_files);
    });
  }

  // ============================================================
  // FILE MENU
  // ============================================================

  void _showFileMenu(_MaterialFile file) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.dialogBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _FileIcon(
                      icon: file.icon,
                      extension: file.extension,
                      size: 46,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        file.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(color: AppColors.surfaceBorder),
                ListTile(
                  leading: const Icon(
                    Icons.visibility_rounded,
                    color: AppColors.secondaryText,
                  ),
                  title: const Text(
                    'ดูรายละเอียด',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showFileDetails(file);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.download_rounded,
                    color: AppColors.secondaryText,
                  ),
                  title: const Text(
                    'ดาวน์โหลด',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadFile(file);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    'ลบไฟล์',
                    style: TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(file);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FILE DETAILS
  // ============================================================

  void _showFileDetails(_MaterialFile file) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'รายละเอียดไฟล์',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(title: 'ชื่อไฟล์', value: file.name),
              _DetailRow(title: 'ประเภท', value: file.extension),
              _DetailRow(title: 'ขนาด', value: file.size),
              _DetailRow(title: 'หมวดหมู่', value: file.category),
              _DetailRow(title: 'สถานะ AI', value: file.status),
              _DetailRow(title: 'วันที่เพิ่ม', value: file.date),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'ปิด',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _confirmDelete(_MaterialFile file) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'ลบไฟล์?',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'ต้องการลบ "${file.name}" หรือไม่',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteFile(file);
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
  }

  Future<void> _deleteFile(_MaterialFile file) async {
    if (_isLoadingOverlay) return;

    _showLoading('กำลังเตรียมลบไฟล์...');

    try {
      const String backendBaseUrl = 'https://groq-backend-yzr8.onrender.com';

      // ========================================================
      // 1. ลบไฟล์จริงจาก Backblaze B2
      // ========================================================

      _updateLoading('กำลังลบไฟล์จากระบบจัดเก็บ...');

      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/materials/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'storageKey': file.storageKey}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'ไม่สามารถลบไฟล์จากระบบจัดเก็บได้ '
          '(${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'ไม่สามารถลบไฟล์ได้');
      }

      // ========================================================
      // 2. ลบข้อมูลจาก Firestore
      // ========================================================

      _updateLoading('กำลังลบข้อมูลไฟล์...');

      await FirebaseFirestore.instance
          .collection('lesson_materials')
          .doc(file.id)
          .delete();

      // ========================================================
      // 3. ลบออกจากรายการบนหน้าจอ
      // ========================================================

      if (!mounted) return;

      setState(() {
        _files.removeWhere((item) => item.id == file.id);
      });

      _hideLoading();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบไฟล์สำเร็จ')));
    } catch (error) {
      debugPrint('Delete File Error: $error');

      _hideLoading();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่สามารถลบไฟล์ได้\n$error')));
    }
  }

  // ============================================================
  // DOWNLOAD
  // ============================================================

  void _downloadFile(_MaterialFile file) {
    _showComingSoon('ระบบดาวน์โหลดไฟล์จะเชื่อมต่อในขั้นตอนถัดไป');
  }

  // เปิดดูไฟล์ที่อัปโหลดไว้ในห้องเรียน
  Future<void> _viewFile(_MaterialFile file) async {
    final extension = file.extension.toLowerCase();

    // รองรับเฉพาะ PDF / DOCX / PPTX
    if (extension != 'pdf' && extension != 'docx' && extension != 'pptx') {
      _showComingSoon('ไม่สามารถเปิดไฟล์ประเภทนี้ได้');
      return;
    }

    if (file.storageKey.isEmpty) {
      _showError('ไม่พบข้อมูลไฟล์');
      return;
    }

    _showLoading('กำลังเปิดไฟล์...');

    try {
      // ขอ Download URL จาก Backend
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/api/materials/download-url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'storageKey': file.storageKey}),
      );

      if (response.statusCode != 200) {
        throw Exception('ไม่สามารถเปิดไฟล์ได้');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'ไม่สามารถเปิดไฟล์ได้');
      }

      final downloadUrl = data['downloadUrl']?.toString();

      if (downloadUrl == null || downloadUrl.isEmpty) {
        throw Exception('ไม่พบ URL ของไฟล์');
      }

      // ดาวน์โหลดไฟล์ต้นฉบับจาก Storage
      final fileResponse = await http.get(Uri.parse(downloadUrl));

      if (fileResponse.statusCode != 200) {
        throw Exception('ไม่สามารถโหลดไฟล์ได้ (${fileResponse.statusCode})');
      }

      final bytes = fileResponse.bodyBytes;

      if (bytes.isEmpty) {
        throw Exception('ไฟล์ที่โหลดมาไม่มีข้อมูล');
      }

      if (!mounted) return;

      _hideLoading();

      // ============================================================
      // PDF
      // ============================================================

      if (extension == 'pdf') {
        // ตรวจสอบว่าเป็น PDF จริง
        if (bytes.length < 5 ||
            bytes[0] != 0x25 || // %
            bytes[1] != 0x50 || // P
            bytes[2] != 0x44 || // D
            bytes[3] != 0x46 || // F
            bytes[4] != 0x2D) {
          // -
          throw Exception('ไฟล์ที่ได้รับไม่ใช่ไฟล์ PDF');
        }

        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => _PdfViewerScreen(fileName: file.name, bytes: bytes),
          ),
        );

        return;
      }

      // ============================================================
      // DOCX / PPTX
      // ============================================================

      if (extension == 'docx' || extension == 'pptx') {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                _OfficeViewerScreen(fileName: file.name, bytes: bytes),
          ),
        );

        return;
      }
    } catch (error) {
      _hideLoading();

      if (mounted) {
        _showError('ไม่สามารถเปิดไฟล์ได้\n$error');
      }
    }
  }

  // ============================================================
  // ACTIVE SESSION
  // ============================================================

  Future<void> _loadActiveSession() async {
    try {
      final session = await _sessionService.getActiveSession(
        widget.subjectCode,
      );

      if (!mounted) return;

      setState(() {
        _sessionId = session?['sessionId']?.toString();
      });

      debugPrint('MaterialScreen active session: $_sessionId');
    } catch (error) {
      debugPrint('ไม่สามารถโหลด Session สำหรับ Chatbot ได้: $error');
    }
  }

  Future<void> _openChatbot() async {
    Map<String, dynamic>? emotionData;

    // ใช้ Session ล่าสุดของวิชานี้เหมือน Dashboard
    String? sessionId = _sessionId;

    // ถ้า session ยังไม่ได้โหลด หรือสถานะอาจเปลี่ยนไป
    // ให้โหลดใหม่ก่อนเปิด Chatbot
    try {
      final session = await _sessionService.getActiveSession(
        widget.subjectCode,
      );

      sessionId = session?['sessionId']?.toString();

      if (mounted) {
        setState(() {
          _sessionId = sessionId;
        });
      }
    } catch (error) {
      debugPrint('ไม่สามารถโหลด Session สำหรับ Chatbot ได้: $error');
    }

    const String type = 'before_class';

    try {
      // MaterialScreen ไม่มีตัวเลือกวันที่แบบ Dashboard
      // จึงใช้วันที่ปัจจุบันเหมือนค่าเริ่มต้นของ Dashboard
      final selectedDate = DateTime.now();

      emotionData = await _emotionService.getEmotionSummaryForAI(
        subjectCode: widget.subjectCode,
        date: selectedDate,
        type: type,
      );

      debugPrint('========== CHAT CONTEXT ==========');
      debugPrint('subjectCode: ${widget.subjectCode}');
      debugPrint('sessionId: $sessionId');
      debugPrint('type: $type');
      debugPrint('emotionData: $emotionData');
      debugPrint('==================================');
    } catch (error) {
      debugPrint('ไม่สามารถโหลดข้อมูล Emotion สำหรับ Chatbot: $error');
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return ChatScreen(
            emotionData: emotionData,
            subjectCode: widget.subjectCode,
            sessionId: sessionId,
          );
        },
      ),
    );
  }
}

class _PdfViewerScreen extends StatelessWidget {
  final String fileName;
  final Uint8List bytes;

  const _PdfViewerScreen({required this.fileName, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: SfPdfViewer.memory(bytes),
    );
  }
}

class _OfficeViewerScreen extends StatelessWidget {
  final String fileName;
  final Uint8List bytes;

  const _OfficeViewerScreen({required this.fileName, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: MicrosoftViewer(bytes, true),
    );
  }
}

// ================================================================
// MATERIAL FILE MODEL
// ================================================================

class _MaterialFile {
  final String id;
  final String name;
  final String type;
  final String extension;
  final String size;
  final String date;
  final String category;
  final String status;
  final IconData icon;

  final int fileSize;
  final String contentType;
  final String storageKey;
  final DateTime uploadedAt;

  const _MaterialFile({
    required this.id,
    required this.name,
    required this.type,
    required this.extension,
    required this.size,
    required this.date,
    required this.category,
    required this.status,
    required this.icon,
    required this.fileSize,
    required this.contentType,
    required this.storageKey,
    required this.uploadedAt,
  });

  // ============================================================
  // FIRESTORE FACTORY
  // ============================================================

  factory _MaterialFile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final uploadedAtData = data['uploadedAt'];

    DateTime uploadedAt;

    if (uploadedAtData is Timestamp) {
      uploadedAt = uploadedAtData.toDate();
    } else {
      uploadedAt = DateTime.now();
    }

    final rawFileSize = data['fileSize'];

    final int fileSize = rawFileSize is num ? rawFileSize.toInt() : 0;

    final extension = data['extension']?.toString().toLowerCase() ?? '';

    final fileType =
        data['fileType']?.toString() ?? _getFileTypeFromExtension(extension);

    final category = data['category']?.toString() ?? fileType;

    return _MaterialFile(
      id: doc.id,
      name: data['fileName']?.toString() ?? 'ไม่ทราบชื่อไฟล์',
      type: fileType,
      extension: extension.toUpperCase(),
      size: _formatFileSizeFromBytes(fileSize),
      date: _formatDateFromDateTime(uploadedAt),
      category: category,
      status: data['aiStatus']?.toString() ?? 'อัปโหลดแล้ว',
      icon: _getFileIconFromExtension(extension),
      fileSize: fileSize,
      contentType: data['contentType']?.toString() ?? '',
      storageKey: data['storageKey']?.toString() ?? '',
      uploadedAt: uploadedAt,
    );
  }
}

// ================================================================
// MATERIAL FILE HELPERS
// ================================================================

String _getFileTypeFromExtension(String extension) {
  switch (extension.toLowerCase()) {
    case 'pdf':
    case 'doc':
    case 'docx':
    case 'txt':
      return 'เอกสาร';

    case 'ppt':
    case 'pptx':
      return 'สไลด์';

    default:
      return 'อื่นๆ';
  }
}

IconData _getFileIconFromExtension(String extension) {
  switch (extension.toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf_rounded;

    case 'ppt':
    case 'pptx':
      return Icons.slideshow_rounded;

    case 'doc':
    case 'docx':
    case 'txt':
      return Icons.description_rounded;

    case 'mp4':
    case 'mov':
    case 'avi':
    case 'mkv':
      return Icons.video_file_rounded;

    case 'mp3':
    case 'wav':
    case 'm4a':
      return Icons.audio_file_rounded;

    default:
      return Icons.insert_drive_file_rounded;
  }
}

String _formatFileSizeFromBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String _formatDateFromDateTime(DateTime date) {
  const months = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  return '${date.day} '
      '${months[date.month - 1]} '
      '${date.year}';
}

// ================================================================
// OVERVIEW ITEM
// ================================================================

class _OverviewItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _OverviewItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 19, color: AppColors.accent),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$title · $subtitle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 8.5),
        ),
      ],
    );
  }
}

// ================================================================
// FILE ICON
// ================================================================

class _FileIcon extends StatelessWidget {
  final IconData icon;
  final String extension;
  final double size;

  const _FileIcon({
    required this.icon,
    required this.extension,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accent, size: size * 0.42),
          const SizedBox(height: 1),
          Text(
            extension,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 6.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// STATUS CHIP
// ================================================================

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool ready = status == 'พร้อมใช้กับ AI';

    final bool reading = status == 'กำลังวิเคราะห์เนื้อหา';

    final bool extracted = status == 'อ่านเนื้อหาแล้ว';

    final Color color = ready
        ? AppColors.green
        : reading
        ? AppColors.cyan
        : extracted
        ? AppColors.green
        : AppColors.mutedText;

    final IconData icon = ready
        ? Icons.check_circle_rounded
        : reading
        ? Icons.sync_rounded
        : extracted
        ? Icons.check_circle_outline_rounded
        : Icons.cloud_done_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// UPLOAD BUTTON
// ================================================================

class _UploadButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _UploadButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: const SizedBox(
          width: double.infinity,
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: AppColors.onAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'อัปโหลดไฟล์',
                style: TextStyle(
                  color: AppColors.onAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SMALL ACTION BUTTON
// ================================================================

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SmallActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Icon(icon, color: AppColors.secondaryText, size: 20),
        ),
      ),
    );
  }
}

// ================================================================
// FILE ACTION BUTTON
// ================================================================

class _FileActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _FileActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: AppColors.secondaryText, size: 16),
        ),
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

// ============================================================
// Dashboard Navigation Data
// ============================================================

class _DashboardNavigationData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _DashboardNavigationData(this.icon, this.activeIcon, this.label);
}

// ================================================================
// UPLOAD OPTION
// ================================================================

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SORT OPTION
// ================================================================

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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: selected ? AppColors.accent : AppColors.secondaryText,
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
      ),
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
        color: selected ? AppColors.accent : AppColors.mutedText,
      ),
      onTap: onTap,
    );
  }
}

// ================================================================
// DETAIL ROW
// ================================================================

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const _DetailRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              title,
              style: const TextStyle(color: AppColors.mutedText, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SQUARE ICON BUTTON
// ================================================================

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SquareIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Icon(icon, color: AppColors.primaryText, size: 17),
        ),
      ),
    );
  }
}
