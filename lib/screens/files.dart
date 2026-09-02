import 'package:flutter/material.dart';

class _MaterialColors {
  static const background = Color(0xFF0E0D18);
  static const accent = Color(0xFF6C52E5);
  static const cyan = Color(0xFF22D3EE);
  static const green = Color(0xFF1BAF7A);

  static const surface = Color(0x0AFFFFFF);
  static const surfaceBorder = Color(0x12FFFFFF);
  static const innerSurface = Color(0x08FFFFFF);

  static const primaryText = Color(0xFFFFFFFF);
  static const secondaryText = Color(0x99FFFFFF);
  static const mutedText = Color(0x73FFFFFF);
  static const faintText = Color(0x4DFFFFFF);

  static const danger = Color(0xFFFF7777);
}

class MaterialScreen extends StatefulWidget {
  
  final String subjectName;

  const MaterialScreen({
    super.key,
    required this.subjectName,
  });

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  int _selectedCategory = 0;

  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  final List<String> _categories = [
    'ทั้งหมด',
    'เอกสาร',
    'สไลด์',
    'วิดีโอ',
    'ไฟล์เสียง',
    'อื่นๆ',
  ];

  final List<_MaterialFile> _files = [
    _MaterialFile(
      name: 'บทที่ 1 บทนำ.pdf',
      type: 'เอกสาร',
      extension: 'PDF',
      size: '2.4 MB',
      date: '2 ก.ย. 2026',
      category: 'เอกสาร',
      status: 'พร้อมใช้กับ AI',
      icon: Icons.picture_as_pdf_rounded,
    ),
    _MaterialFile(
      name: 'บทที่ 2 Introduction to AI.pptx',
      type: 'สไลด์',
      extension: 'PPTX',
      size: '8.7 MB',
      date: '1 ก.ย. 2026',
      category: 'สไลด์',
      status: 'อ่านเนื้อหาแล้ว',
      icon: Icons.slideshow_rounded,
    ),
    _MaterialFile(
      name: 'Machine Learning เบื้องต้น.pdf',
      type: 'เอกสาร',
      extension: 'PDF',
      size: '4.1 MB',
      date: '30 ส.ค. 2026',
      category: 'เอกสาร',
      status: 'พร้อมใช้กับ AI',
      icon: Icons.picture_as_pdf_rounded,
    ),
    _MaterialFile(
      name: 'Lecture Week 4.mp4',
      type: 'วิดีโอ',
      extension: 'MP4',
      size: '124 MB',
      date: '28 ส.ค. 2026',
      category: 'วิดีโอ',
      status: 'กำลังวิเคราะห์เนื้อหา',
      icon: Icons.video_file_rounded,
    ),
    _MaterialFile(
      name: 'สรุปบทเรียน.mp3',
      type: 'ไฟล์เสียง',
      extension: 'MP3',
      size: '18.3 MB',
      date: '27 ส.ค. 2026',
      category: 'ไฟล์เสียง',
      status: 'อัปโหลดแล้ว',
      icon: Icons.audio_file_rounded,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_MaterialFile> get _filteredFiles {
    return _files.where((file) {
      final matchesCategory =
          _selectedCategory == 0 ||
          file.category == _categories[_selectedCategory];

      final matchesSearch =
          _searchText.isEmpty ||
          file.name.toLowerCase().contains(_searchText.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MaterialColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.55, -1.05),
            radius: 1.15,
            colors: [
              Color(0xFF29344D),
              Color(0xFF19142E),
              _MaterialColors.background,
            ],
            stops: [0, 0.35, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
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
                      _buildFileHeader(),
                      const SizedBox(height: 10),
                      _buildFileList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
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
                  color: _MaterialColors.primaryText,
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
                  color: _MaterialColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _UploadButton(
          onPressed: _showUploadDialog,
        ),
      ],
    );
  }

  // ============================================================
  // STORAGE / OVERVIEW
  // ============================================================

  Widget _buildStorageOverview() {
    final totalSize = '157.5 MB';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _MaterialColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _MaterialColors.surfaceBorder,
        ),
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
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              Expanded(
                child: _OverviewItem(
                  icon: Icons.category_rounded,
                  title: 'ประเภทไฟล์',
                  value: '5',
                  subtitle: 'ประเภท',
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(alpha: 0.08),
              ),
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
                color: _MaterialColors.mutedText,
              ),
              const SizedBox(width: 7),
              const Text(
                'อัปเดตล่าสุด',
                style: TextStyle(
                  color: _MaterialColors.mutedText,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '2 ก.ย. 2026',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
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
              color: _MaterialColors.innerSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _MaterialColors.surfaceBorder,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              cursorColor: _MaterialColors.accent,
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _MaterialColors.mutedText,
                  size: 21,
                ),
                hintText: 'ค้นหาไฟล์...',
                hintStyle: TextStyle(
                  color: _MaterialColors.faintText,
                  fontSize: 13,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        _SmallActionButton(
          icon: Icons.tune_rounded,
          onPressed: _showFilterDialog,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? _MaterialColors.accent.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.035),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? _MaterialColors.accent.withValues(alpha: 0.65)
                      : _MaterialColors.surfaceBorder,
                ),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : _MaterialColors.secondaryText,
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
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
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${_filteredFiles.length}',
            style: const TextStyle(
              color: _MaterialColors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'เรียงตามล่าสุด',
          style: const TextStyle(
            color: _MaterialColors.mutedText,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILE LIST
  // ============================================================

  Widget _buildFileList() {
    if (_filteredFiles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        for (int i = 0; i < _filteredFiles.length; i++) ...[
          _buildFileCard(_filteredFiles[i]),
          if (i != _filteredFiles.length - 1)
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildFileCard(_MaterialFile file) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _MaterialColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _MaterialColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          _FileIcon(
            icon: file.icon,
            extension: file.extension,
          ),
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
                    color: Colors.white,
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
                        color: _MaterialColors.mutedText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _dot(),
                    Text(
                      file.size,
                      style: const TextStyle(
                        color: _MaterialColors.mutedText,
                        fontSize: 9.5,
                      ),
                    ),
                    _dot(),
                    Flexible(
                      child: Text(
                        file.date,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _MaterialColors.mutedText,
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
    );
  }

  Widget _dot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        '•',
        style: TextStyle(
          color: _MaterialColors.faintText,
          fontSize: 8,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: _MaterialColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _MaterialColors.surfaceBorder,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 42,
            color: _MaterialColors.mutedText,
          ),
          SizedBox(height: 12),
          Text(
            'ไม่พบไฟล์',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'ลองค้นหาด้วยชื่อไฟล์อื่น',
            style: TextStyle(
              color: _MaterialColors.mutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      height: 96,
      padding: const EdgeInsets.fromLTRB(7, 8, 7, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF171522),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavigationItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: false,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book_rounded,
              label: 'สื่อการสอน',
              selected: true,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_rounded,
              label: 'แชทบอท',
              selected: false,
              onTap: _openChatbot,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _showUploadDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1729),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              22,
              18,
              22,
              25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'เพิ่มสื่อการสอน',
                    style: TextStyle(
                      color: Colors.white,
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
                    style: TextStyle(
                      color: _MaterialColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _UploadOption(
                  icon: Icons.upload_file_rounded,
                  title: 'อัปโหลดไฟล์',
                  subtitle: 'PDF, PPTX, DOCX, MP4, MP3 และอื่น ๆ',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon('ระบบเลือกไฟล์');
                  },
                ),
                const SizedBox(height: 10),
                _UploadOption(
                  icon: Icons.link_rounded,
                  title: 'เพิ่มจากลิงก์',
                  subtitle: 'เพิ่ม URL ของสื่อการสอน',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon('เพิ่มจากลิงก์');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1729),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              22,
              20,
              22,
              25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ตัวกรอง',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                ...List.generate(
                  _categories.length,
                  (index) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _categories[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Radio<int>(
                        value: index,
                        groupValue: _selectedCategory,
                        activeColor: _MaterialColors.accent,
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _selectedCategory = value;
                          });

                          Navigator.pop(context);
                        },
                      ),
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

  void _showSortDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1729),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              22,
              20,
              22,
              25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เรียงลำดับ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _SortOption(
                  icon: Icons.schedule_rounded,
                  title: 'ล่าสุดก่อน',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _SortOption(
                  icon: Icons.history_rounded,
                  title: 'เก่าสุดก่อน',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _SortOption(
                  icon: Icons.sort_by_alpha_rounded,
                  title: 'ชื่อไฟล์ A-Z',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _SortOption(
                  icon: Icons.data_usage_rounded,
                  title: 'ขนาดไฟล์',
                  onTap: () {
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

  void _showFileMenu(_MaterialFile file) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1729),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              22,
              20,
              22,
              20,
            ),
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
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(
                  color: Color(0x12FFFFFF),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'ดูรายละเอียด',
                    style: TextStyle(
                      color: Colors.white,
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
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'ดาวน์โหลด',
                    style: TextStyle(
                      color: Colors.white,
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
                    color: _MaterialColors.danger,
                  ),
                  title: const Text(
                    'ลบไฟล์',
                    style: TextStyle(
                      color: _MaterialColors.danger,
                      fontSize: 13,
                    ),
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

  void _showFileDetails(_MaterialFile file) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1729),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'รายละเอียดไฟล์',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                title: 'ชื่อไฟล์',
                value: file.name,
              ),
              _DetailRow(
                title: 'ประเภท',
                value: file.extension,
              ),
              _DetailRow(
                title: 'ขนาด',
                value: file.size,
              ),
              _DetailRow(
                title: 'หมวดหมู่',
                value: file.category,
              ),
              _DetailRow(
                title: 'สถานะ AI',
                value: file.status,
              ),
              _DetailRow(
                title: 'วันที่เพิ่ม',
                value: file.date,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'ปิด',
                style: TextStyle(
                  color: _MaterialColors.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(_MaterialFile file) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1729),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'ลบไฟล์?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'ต้องการลบ "${file.name}" หรือไม่',
            style: const TextStyle(
              color: _MaterialColors.secondaryText,
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
                style: TextStyle(
                  color: _MaterialColors.secondaryText,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _files.remove(file);
                });

                Navigator.pop(context);

                _showComingSoon('ลบไฟล์แล้ว');
              },
              child: const Text(
                'ลบ',
                style: TextStyle(
                  color: _MaterialColors.danger,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _downloadFile(_MaterialFile file) {
    _showComingSoon('ระบบดาวน์โหลดไฟล์');
  }

  void _openChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const _PlaceholderChatScreen(),
      ),
    );
  }

  void _showComingSoon(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// ================================================================
// MATERIAL FILE MODEL
// ================================================================

class _MaterialFile {
  final String name;
  final String type;
  final String extension;
  final String size;
  final String date;
  final String category;
  final String status;
  final IconData icon;

  const _MaterialFile({
    required this.name,
    required this.type,
    required this.extension,
    required this.size,
    required this.date,
    required this.category,
    required this.status,
    required this.icon,
  });
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
        Icon(
          icon,
          size: 19,
          color: _MaterialColors.accent,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$title · $subtitle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _MaterialColors.mutedText,
            fontSize: 8.5,
          ),
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
        color: _MaterialColors.accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _MaterialColors.accent.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: _MaterialColors.accent,
            size: size * 0.42,
          ),
          const SizedBox(height: 1),
          Text(
            extension,
            style: const TextStyle(
              color: Colors.white70,
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

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool ready = status == 'พร้อมใช้กับ AI';
    final bool reading = status == 'กำลังวิเคราะห์เนื้อหา';

    final Color color = ready
        ? _MaterialColors.green
        : reading
            ? _MaterialColors.cyan
            : _MaterialColors.mutedText;

    final IconData icon = ready
        ? Icons.check_circle_rounded
        : reading
            ? Icons.sync_rounded
            : Icons.cloud_done_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
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

  const _UploadButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _MaterialColors.accent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 5),
              Text(
                'อัปโหลดไฟล์',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
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

  const _SmallActionButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _MaterialColors.surfaceBorder,
            ),
          ),
          child: Icon(
            icon,
            color: _MaterialColors.secondaryText,
            size: 20,
          ),
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

  const _FileActionButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            color: _MaterialColors.secondaryText,
            size: 16,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// NAVIGATION ITEM
// ================================================================

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 66,
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.055)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: selected
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 24,
                  color: selected
                      ? Colors.white
                      : _MaterialColors.secondaryText,
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : _MaterialColors.mutedText,
                    fontSize: 10.5,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      color: Colors.white.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _MaterialColors.surfaceBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _MaterialColors.accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _MaterialColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _MaterialColors.mutedText,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _MaterialColors.mutedText,
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
  final VoidCallback onTap;

  const _SortOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: _MaterialColors.secondaryText,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: _MaterialColors.mutedText,
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

  const _DetailRow({
    required this.title,
    required this.value,
  });

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
              style: const TextStyle(
                color: _MaterialColors.mutedText,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
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

  const _SquareIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _MaterialColors.surfaceBorder,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 17,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// PLACEHOLDER CHAT SCREEN
// ================================================================
//
// ตรงนี้มีไว้เพื่อให้ไฟล์นี้ compile ได้โดยไม่ต้องรู้โครงสร้าง
// ChatScreen ปัจจุบันของโปรเจกต์
//
// เมื่อนำเข้า chat.dart แล้ว สามารถเปลี่ยนเป็น ChatScreen ได้
// ================================================================

class _PlaceholderChatScreen extends StatelessWidget {
  const _PlaceholderChatScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MaterialColors.background,
      appBar: AppBar(
        backgroundColor: _MaterialColors.background,
        foregroundColor: Colors.white,
        title: const Text('แชทบอท'),
      ),
      body: const Center(
        child: Text(
          'ChatScreen',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}