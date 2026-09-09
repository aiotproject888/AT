import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../services/chat_service.dart';
import '../services/chat_history_service.dart';
import '../models/chat_message.dart';
import '../widgets/message_bubble.dart';
import '../services/emotion_service.dart';

class _ChatColors {
  static const background = Color(0xFF0E0D18);
  static const accent = Color(0xFF6C52E5);
  static const cyan = Color(0xFF22D3EE);

  static const green = Color(0xFF1BAF7A);
  static const greenText = Color(0xFF3DD99A);

  static const surface = Color(0x0FFFFFFF);
  static const subtleSurface = Color(0x0DFFFFFF);
  static const inputSurface = Color(0x0FFFFFFF);

  static const surfaceBorder = Color(0x17FFFFFF);
  static const inputBorder = Color(0x1AFFFFFF);

  static const accentSurface = Color(0x1A6C52E5);
  static const accentBorder = Color(0x476C52E5);

  static const greenSurface = Color(0x261BAF7A);
  static const greenBorder = Color(0x4D1BAF7A);

  static const primaryText = Color(0xFFFFFFFF);
  static const secondaryText = Color(0xD9FFFFFF);
  static const mutedText = Color(0x8CFFFFFF);
  static const faintText = Color(0x66FFFFFF);
  static const veryFaintText = Color(0x4DFFFFFF);
}

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? emotionData;

  final String? subjectCode;

  final String? sessionId;

  final bool autoAttachEmotion;

  const ChatScreen({
    super.key,
    this.emotionData,
    this.subjectCode,
    this.sessionId,
    this.autoAttachEmotion = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ChatService _chatService = ChatService();
  final ChatHistoryService _historyService = ChatHistoryService();
  final EmotionService _emotionService = EmotionService();

  final List<ChatMessage> messages = [];

  bool isSending = false;
  bool _isLoadingHistory = true;

  Map<String, dynamic>? _emotionData;
  bool _isLoadingEmotion = false;

  String? _conversationId;

  List<Map<String, dynamic>> _lessonMaterials = [];
  List<Map<String, dynamic>> _selectedLessonMaterials = [];

  bool _isLoadingMaterials = false;

  Map<String, dynamic>? _chatUploadedFile;

  bool _isReadingFile = false;

  bool _isLoadingAttachment = false;
  String _attachmentLoadingText = 'กำลังโหลดข้อมูล...';

  String _selectedModel = 'gpt-oss-120b';

  void _showAttachmentLoading(String text) {
    if (!mounted) return;
    setState(() {
      _isLoadingAttachment = true;
      _attachmentLoadingText = text;
    });
  }

  void _updateAttachmentLoading(String text) {
    if (!mounted) return;
    setState(() {
      _attachmentLoadingText = text;
    });
  }

  void _hideAttachmentLoading() {
    if (!mounted) return;
    setState(() {
      _isLoadingAttachment = false;
    });
  }

  // ============================================================
  // Initial Message
  // ============================================================

  @override
  void initState() {
    super.initState();

    messages.add(
      ChatMessage(
        isAI: true,
        text:
            "สวัสดีครับ 👋 ยินดีต้อนรับสู่ EmotiTeach AI\nมีอะไรให้ผมช่วยไหมครับ?",
        time: DateTime.now(),
      ),
    );

    if (widget.autoAttachEmotion && widget.emotionData != null) {
      _emotionData = Map<String, dynamic>.from(widget.emotionData!);
    }

    _loadChatHistory();

    if (widget.subjectCode != null && widget.subjectCode!.isNotEmpty) {
      _loadLessonMaterials();
    }
  }

  // ============================================================
  // โหลด Emotion เดิม
  // ============================================================

  Future<void> _loadEmotionData() async {
    if (widget.subjectCode == null || widget.subjectCode!.trim().isEmpty) {
      return;
    }

    if (_isLoadingEmotion) {
      return;
    }

    setState(() {
      _isLoadingEmotion = true;
    });

    try {
      final selectedDate = DateTime.now();

      final emotionData = await _emotionService.getEmotionSummaryForAI(
        subjectCode: widget.subjectCode!,
        date: selectedDate,
        type: 'before_class',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _emotionData = emotionData;
        _isLoadingEmotion = false;
      });

      debugPrint('========== EMOTION ATTACHED ==========');
      debugPrint('$_emotionData');
      debugPrint('======================================');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('แนบข้อมูลอารมณ์เรียบร้อยแล้ว'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      debugPrint('โหลดข้อมูล Emotion ไม่สำเร็จ: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingEmotion = false;
        _emotionData = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถโหลดข้อมูลอารมณ์ได้: $error')),
      );
    }
  }

  // ============================================================
 

  Future<void> _loadSelectedEmotionData({
    required bool beforeSelected,
    required bool afterSelected,
  }) async {
    if (widget.subjectCode == null || widget.subjectCode!.trim().isEmpty) {
      return;
    }

    if (_isLoadingEmotion) {
      return;
    }

    setState(() {
      _isLoadingEmotion = true;
    });

    try {
      final selectedDate = DateTime.now();

      Map<String, dynamic>? beforeData;
      Map<String, dynamic>? afterData;

      // ==========================================================
      // ก่อนเรียน
      // ==========================================================

      if (beforeSelected) {
        beforeData = await _emotionService.getEmotionSummaryForAI(
          subjectCode: widget.subjectCode!,
          date: selectedDate,
          type: 'before_class',
        );
      }

      // ==========================================================
      // หลังเรียน
      // ==========================================================

      if (afterSelected) {
        afterData = await _emotionService.getEmotionSummaryForAI(
          subjectCode: widget.subjectCode!,
          date: selectedDate,
          type: 'after_class',
        );
      }

      if (!mounted) {
        return;
      }

      // ==========================================================
      // สร้างข้อมูลสำหรับส่ง AI
      // ==========================================================

      final Map<String, dynamic> combinedData = {};

      if (beforeData != null) {
        combinedData['beforeClass'] = beforeData;
      }

      if (afterData != null) {
        combinedData['afterClass'] = afterData;
      }

      // ==========================================================
      // รวมจำนวน Responses
      // ==========================================================

      int totalResponses = 0;

      if (beforeData != null) {
        totalResponses +=
            int.tryParse(beforeData['totalResponses']?.toString() ?? '0') ?? 0;
      }

      if (afterData != null) {
        totalResponses +=
            int.tryParse(afterData['totalResponses']?.toString() ?? '0') ?? 0;
      }

      combinedData['totalResponses'] = totalResponses;

      // ==========================================================
      // เก็บข้อมูลว่าผู้ใช้เลือกอะไร
      // ==========================================================

      combinedData['includeBeforeClass'] = beforeSelected;
      combinedData['includeAfterClass'] = afterSelected;

      setState(() {
        _emotionData = combinedData;
        _isLoadingEmotion = false;
      });

      debugPrint('========== EMOTION ATTACHED ==========');
      debugPrint('Before class: $beforeSelected');
      debugPrint('After class: $afterSelected');
      debugPrint('Total responses: $totalResponses');
      debugPrint('Data: $_emotionData');
      debugPrint('======================================');

      String attachedText = 'แนบข้อมูลอารมณ์แล้ว';

      if (beforeSelected && afterSelected) {
        attachedText = 'แนบข้อมูลอารมณ์ก่อนเรียนและหลังเรียนแล้ว';
      } else if (beforeSelected) {
        attachedText = 'แนบข้อมูลอารมณ์ก่อนเรียนแล้ว';
      } else if (afterSelected) {
        attachedText = 'แนบข้อมูลอารมณ์หลังเรียนแล้ว';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attachedText),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      debugPrint('โหลดข้อมูล Emotion ไม่สำเร็จ: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingEmotion = false;
        _emotionData = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถโหลดข้อมูลอารมณ์ได้: $error')),
      );
    }
  }

  // ============================================================
  // Dialog เลือก Emotion
  // ============================================================

  Future<void> _showEmotionSelectionDialog() async {
    bool beforeSelected = false;
    bool afterSelected = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xff1E1B2E),
              title: const Text(
                'แนบข้อมูลอารมณ์',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: beforeSelected,
                    activeColor: _ChatColors.accent,
                    checkColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'ก่อนเรียน',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'ข้อมูลอารมณ์ก่อนเริ่มเรียน',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        beforeSelected = value ?? false;
                      });
                    },
                  ),

                  CheckboxListTile(
                    value: afterSelected,
                    activeColor: _ChatColors.accent,
                    checkColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'หลังเรียน',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'ข้อมูลอารมณ์หลังเรียน',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        afterSelected = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ChatColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (!beforeSelected && !afterSelected)
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);

                          await _loadSelectedEmotionData(
                            beforeSelected: beforeSelected,
                            afterSelected: afterSelected,
                          );
                        },
                  child: const Text('ยืนยัน'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Emotion Status
  // ============================================================

  Widget _buildEmotionStatus() {
    if (_isLoadingEmotion) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0x1A6C52E5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x476C52E5)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6C52E5),
              ),
            ),
            SizedBox(width: 9),
            Text(
              'กำลังโหลดข้อมูลอารมณ์...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_emotionData == null) {
      return const SizedBox.shrink();
    }

    final total = _emotionData!['totalResponses'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x261BAF7A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x4D1BAF7A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bar_chart_rounded,
            color: Color(0xFF3DD99A),
            size: 18,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              'แนบข้อมูลอารมณ์แล้ว · $total responses',
              style: const TextStyle(color: Color(0xFF3DD99A), fontSize: 12),
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                _emotionData = null;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white54,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // เลือกไฟล์จากหน้า Chat
  // ============================================================

  Future<void> _pickChatFile() async {
    if (_isReadingFile || isSending) {
      return;
    }

    // ถ้าเป็น Chat ของห้องเรียน ให้เลือกจากไฟล์ของห้องเรียนก่อน
    if (widget.subjectCode != null && widget.subjectCode!.trim().isNotEmpty) {
      await _showLessonMaterialPicker();
      return;
    }

    // Chat ทั่วไปยังใช้การแนบไฟล์แบบเดิม
    await _pickStandaloneChatFile();
  }

  // ============================================================
  // Dialog เลือกสื่อการสอนของห้องเรียน
  // ============================================================

  Future<void> _showLessonMaterialPicker() async {
    if (widget.subjectCode == null ||
        widget.subjectCode!.trim().isEmpty ||
        isSending ||
        _isReadingFile) {
      return;
    }

    if (_isLoadingMaterials) {
      await _loadLessonMaterials();
    }

    final Set<String> selectedIds = _selectedLessonMaterials
        .map((material) => material['id']?.toString())
        .whereType<String>()
        .toSet();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final materials = _lessonMaterials;

            return AlertDialog(
              backgroundColor: const Color(0xff1E1B2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _ChatColors.accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: _ChatColors.cyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'แนบสื่อการสอน',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 430,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ไฟล์ในห้องเรียน ${widget.subjectCode}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: _isLoadingMaterials
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(25),
                                  child: CircularProgressIndicator(
                                    color: _ChatColors.accent,
                                  ),
                                ),
                              )
                            : materials.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 28,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.folder_open_rounded,
                                        color: Colors.white38,
                                        size: 40,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'ยังไม่มีไฟล์ที่พร้อมให้ AI ใช้งาน',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'อัปโหลดไฟล์ใหม่ได้จากปุ่มด้านล่าง',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: materials.length,
                                separatorBuilder: (_, __) => const Divider(
                                  color: Colors.white10,
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final material = materials[index];
                                  final id = material['id']?.toString() ?? '';
                                  final isSelected = selectedIds.contains(id);
                                  final fileName =
                                      material['fileName']?.toString() ??
                                      'ไม่ทราบชื่อไฟล์';
                                  final fileType =
                                      material['fileType']?.toString() ?? '';

                                  return CheckboxListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    dense: true,
                                    value: isSelected,
                                    activeColor: _ChatColors.accent,
                                    checkColor: Colors.white,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    secondary: Icon(
                                      fileType.toLowerCase() == 'pdf' ||
                                              fileName.toLowerCase().endsWith(
                                                '.pdf',
                                              )
                                          ? Icons.picture_as_pdf_rounded
                                          : Icons.description_rounded,
                                      color: _ChatColors.cyan,
                                      size: 21,
                                    ),
                                    title: Text(
                                      fileName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    subtitle: Text(
                                      fileType.isEmpty
                                          ? 'พร้อมให้ AI วิเคราะห์'
                                          : '$fileType · พร้อมให้ AI วิเคราะห์',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        if (value == true) {
                                          selectedIds.add(id);
                                        } else {
                                          selectedIds.remove(id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _pickAndUploadLessonMaterial();
                  },
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('อัปโหลดไฟล์ใหม่'),
                  style: TextButton.styleFrom(
                    foregroundColor: _ChatColors.cyan,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // อัปโหลดสื่อการสอนใหม่จาก Chat
  // ใช้ Backend + Firestore collection เดียวกับ files.dart
  // ============================================================

  Future<void> _pickAndUploadLessonMaterial() async {
    if (isSending || _isReadingFile) {
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;
      final bytes = pickedFile.bytes;

      if (bytes == null || bytes.isEmpty) {
        _showFileError('ไม่สามารถอ่านข้อมูลไฟล์ได้');
        return;
      }

      if (!mounted) return;

      setState(() {
        _isReadingFile = true;
      });
      _showAttachmentLoading('กำลังเตรียมไฟล์...');

      const String backendBaseUrl = 'https://groq-backend-yzr8.onrender.com';

      final fileName = pickedFile.name;
      final extension = _getLessonMaterialExtension(fileName);
      final contentType = _getLessonMaterialContentType(fileName);
      final fileType = _getLessonMaterialFileType(extension);
      final category = fileType;
      final uploadedAt = DateTime.now();

      // 1. ขอ Presigned URL
      _updateAttachmentLoading('กำลังเตรียมไฟล์สำหรับอัปโหลด...');
      final urlResponse = await http.post(
        Uri.parse('$backendBaseUrl/api/materials/upload-url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fileName': fileName, 'contentType': contentType}),
      );

      if (urlResponse.statusCode != 200) {
        throw Exception(
          'ไม่สามารถสร้าง Upload URL ได้ (${urlResponse.statusCode})',
        );
      }

      final Map<String, dynamic> urlData =
          jsonDecode(urlResponse.body) as Map<String, dynamic>;

      if (urlData['success'] != true) {
        throw Exception(urlData['message'] ?? 'ไม่สามารถสร้าง Upload URL ได้');
      }

      final uploadUrl = urlData['uploadUrl']?.toString();
      final storageKey = urlData['storageKey']?.toString();

      if (uploadUrl == null || uploadUrl.isEmpty) {
        throw Exception('Backend ไม่ได้ส่ง uploadUrl กลับมา');
      }

      if (storageKey == null || storageKey.isEmpty) {
        throw Exception('Backend ไม่ได้ส่ง storageKey กลับมา');
      }

      // 2. Upload ไป Backblaze B2
      _updateAttachmentLoading('กำลังอัปโหลดไฟล์...');
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      );

      if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
        throw Exception('อัปโหลดไม่สำเร็จ (${uploadResponse.statusCode})');
      }

      // 3. Process / Extract Text
      _updateAttachmentLoading('กำลังอ่านเนื้อหาในไฟล์...');
      String extractedText = '';
      String aiStatus = 'อัปโหลดแล้ว';

      try {
        final processResponse = await http.post(
          Uri.parse('$backendBaseUrl/api/materials/process'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'storageKey': storageKey,
            'fileName': fileName,
            'contentType': contentType,
          }),
        );

        if (processResponse.statusCode == 200) {
          final processData =
              jsonDecode(processResponse.body) as Map<String, dynamic>;

          if (processData['success'] == true) {
            final extractedTextData = processData['extractedText'];

            if (extractedTextData is Map) {
              extractedText = extractedTextData['text']?.toString() ?? '';
            } else if (extractedTextData is String) {
              extractedText = extractedTextData;
            }

            if (extractedText.trim().isNotEmpty) {
              aiStatus = 'อ่านเนื้อหาแล้ว';
            }
          }
        }
      } catch (processError) {
        debugPrint('Process Error: $processError');
      }

      // 4. Save metadata ลง Firestore เหมือน files.dart
      _updateAttachmentLoading('กำลังบันทึกข้อมูล...');
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
        'aiStatus': aiStatus,
        'extractedTextLength': extractedText.length,
        'extractedText': extractedText,
      };

      await FirebaseFirestore.instance
          .collection('lesson_materials')
          .add(firestoreData);

      if (!mounted) return;

      setState(() {
        _isReadingFile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aiStatus == 'อ่านเนื้อหาแล้ว'
                ? 'อัปโหลด $fileName สำเร็จ และพร้อมให้ AI ใช้งานแล้ว'
                : 'อัปโหลด $fileName สำเร็จ แต่ยังไม่สามารถอ่านเนื้อหาได้',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // โหลดรายการใหม่ แล้วเปิดตัวเลือกให้เลือกไฟล์ที่เพิ่งอัปโหลดได้ทันที
      _updateAttachmentLoading('กำลังโหลดรายการไฟล์...');
      await _loadLessonMaterials();
      _hideAttachmentLoading();
      await _showLessonMaterialPicker();
    } catch (error) {
      debugPrint('Upload Lesson Material Error: $error');

      if (!mounted) return;

      _showFileError('ไม่สามารถอัปโหลดไฟล์ได้\n$error');
    } finally {
      if (mounted) {
        setState(() {
          _isReadingFile = false;
        });
        _hideAttachmentLoading();
      }
    }
  }

  String _getLessonMaterialExtension(String fileName) {
    final index = fileName.lastIndexOf('.');

    if (index == -1) {
      return '';
    }

    return fileName.substring(index + 1).toLowerCase();
  }

  String _getLessonMaterialFileType(String extension) {
    switch (extension) {
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

  String _getLessonMaterialContentType(String fileName) {
    switch (_getLessonMaterialExtension(fileName)) {
      case 'pdf':
        return 'application/pdf';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // ============================================================
  // แนบไฟล์แบบเดิมสำหรับ Chat ทั่วไป
  // ============================================================

  Future<void> _pickStandaloneChatFile() async {
    if (_isReadingFile || isSending) {
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;

      if (file.bytes == null || file.bytes!.isEmpty) {
        _showFileError('ไม่สามารถอ่านไฟล์ได้');
        return;
      }

      setState(() {
        _isReadingFile = true;
      });
      _showAttachmentLoading('กำลังอ่านไฟล์...');

      final String extension = file.extension?.toLowerCase() ?? '';

      String extractedText = '';

      if (extension == 'pdf') {
        _updateAttachmentLoading('กำลังอ่านข้อความจาก PDF...');
        extractedText = await _extractPdfText(file.bytes!);
      } else if (extension == 'txt' ||
          extension == 'md' ||
          extension == 'csv') {
        _updateAttachmentLoading('กำลังเตรียมข้อความ...');
        extractedText = utf8.decode(file.bytes!, allowMalformed: true);
      } else {
        _showFileError('ไฟล์ประเภท .$extension ยังไม่รองรับ');
        return;
      }

      if (extractedText.trim().isEmpty) {
        _showFileError('ไม่พบข้อความในไฟล์นี้');
        return;
      }

      if (!mounted) {
        return;
      }

      _updateAttachmentLoading('กำลังเตรียมข้อมูลสำหรับ AI...');

      setState(() {
        const int maxTextLength = 6000;

        String textForAI = extractedText;

        if (textForAI.length > maxTextLength) {
          textForAI = textForAI.substring(0, maxTextLength);

          debugPrint(
            'ไฟล์มีข้อความยาวเกินกำหนด '
            'ตัดเหลือ $maxTextLength ตัวอักษร',
          );
        }

        _chatUploadedFile = {
          'id': 'chat_upload_${DateTime.now().millisecondsSinceEpoch}',
          'fileName': file.name,
          'fileType': file.extension ?? '',
          'text': textForAI,
        };

        _isReadingFile = false;
      });

      debugPrint('==========================================');

      debugPrint('CHAT FILE UPLOAD');
      debugPrint('File name: ${file.name}');
      debugPrint('File type: $extension');
      debugPrint('Text length: ${extractedText.length}');

      debugPrint('==========================================');
    } catch (e) {
      debugPrint('อ่านไฟล์ไม่สำเร็จ: $e');

      if (!mounted) {
        return;
      }

      _showFileError('ไม่สามารถอ่านไฟล์ได้');
    } finally {
      if (mounted) {
        setState(() {
          _isReadingFile = false;
        });
        _hideAttachmentLoading();
      }
    }
  }

  // ============================================================
  // อ่านข้อความจาก PDF
  // ============================================================

  Future<String> _extractPdfText(Uint8List bytes) async {
    PdfDocument? document;

    try {
      document = PdfDocument(inputBytes: bytes);

      final StringBuffer buffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        final String text = PdfTextExtractor(
          document,
        ).extractText(startPageIndex: i, endPageIndex: i);

        if (text.trim().isNotEmpty) {
          buffer.writeln(text);
        }
      }

      return buffer.toString();
    } finally {
      document?.dispose();
    }
  }

  void _showFileError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // แสดงไฟล์ที่แนบจากหน้า Chat
  // ============================================================

  Widget _buildChatUploadedFile() {
    if (_chatUploadedFile == null) {
      return const SizedBox.shrink();
    }

    final String fileName =
        _chatUploadedFile!['fileName']?.toString() ?? 'ไฟล์';

    final String fileType =
        _chatUploadedFile!['fileType']?.toString().toUpperCase() ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _ChatColors.accentSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _ChatColors.accentBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _ChatColors.accent.withOpacity(0.25),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              fileType == 'PDF'
                  ? Icons.picture_as_pdf_rounded
                  : Icons.description_rounded,
              color: _ChatColors.cyan,
              size: 18,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'แนบไฟล์แล้ว · AI สามารถใช้เนื้อหาได้',
                  style: const TextStyle(color: Colors.white60, fontSize: 9.5),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: isSending
                ? null
                : () {
                    setState(() {
                      _chatUploadedFile = null;
                    });
                  },
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // โหลด Lesson Materials
  // ============================================================

  Future<void> _loadLessonMaterials() async {
    if (widget.subjectCode == null || widget.subjectCode!.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingMaterials = true;
    });

    try {
      debugPrint('========== LOAD LESSON MATERIALS ==========');

      debugPrint('subjectCode: ${widget.subjectCode}');

      final snapshot = await FirebaseFirestore.instance
          .collection('lesson_materials')
          .where('subjectCode', isEqualTo: widget.subjectCode)
          .get();

      final List<Map<String, dynamic>> materials = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final String aiStatus = data['aiStatus']?.toString() ?? '';

        final String fileName =
            data['fileName']?.toString() ??
            data['name']?.toString() ??
            'ไม่ทราบชื่อไฟล์';

        final String fileType = data['fileType']?.toString() ?? '';

        final dynamic rawExtractedText = data['extractedText'];

        String extractedText = '';

        if (rawExtractedText is String) {
          extractedText = rawExtractedText;
        } else if (rawExtractedText is Map) {
          extractedText = rawExtractedText['text']?.toString() ?? '';
        }

        debugPrint('ไฟล์: $fileName');
        debugPrint('aiStatus: $aiStatus');

        debugPrint(
          'extractedText type: '
          '${rawExtractedText.runtimeType}',
        );

        debugPrint(
          'extractedText length: '
          '${extractedText.length}',
        );

        if (aiStatus == 'อ่านเนื้อหาแล้ว' && extractedText.trim().isNotEmpty) {
          materials.add({
            'id': doc.id,
            'fileName': fileName,
            'text': extractedText,
            'fileType': fileType,
          });
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _lessonMaterials = materials;
        _isLoadingMaterials = false;
      });

      debugPrint(
        'โหลดเนื้อหาบทเรียนสำเร็จ: '
        '${materials.length} ไฟล์',
      );

      debugPrint('==========================================');
    } catch (e) {
      debugPrint('โหลด Lesson Materials ไม่สำเร็จ: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _lessonMaterials = [];
        _isLoadingMaterials = false;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      debugPrint('========== LOAD CHAT HISTORY ==========');

      final bool isClassroom =
          widget.subjectCode != null && widget.subjectCode!.isNotEmpty;

      debugPrint(
        'Chat type: '
        '${isClassroom ? 'classroom' : 'general'}',
      );

      debugPrint('subjectCode: ${widget.subjectCode}');

      debugPrint('sessionId: ${widget.sessionId}');

      final conversations = await _historyService.getConversations();

      if (conversations.isEmpty) {
        debugPrint('ยังไม่มีประวัติการสนทนา');

        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
          });
        }

        return;
      }

      QueryDocumentSnapshot<Map<String, dynamic>>? matchedConversation;

      for (final conversation in conversations) {
        final data = conversation.data();

        final String type = data['type']?.toString() ?? '';

        final String conversationSubjectCode =
            data['subjectCode']?.toString() ?? '';

        final String conversationSessionId =
            data['sessionId']?.toString() ?? '';

        if (!isClassroom) {
          if (type == 'general') {
            matchedConversation = conversation;
            break;
          }
        } else {
          if (type != 'classroom') {
            continue;
          }

          if (conversationSubjectCode != widget.subjectCode) {
            continue;
          }

          if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
            if (conversationSessionId != widget.sessionId) {
              continue;
            }
          }

          matchedConversation = conversation;
          break;
        }
      }

      if (matchedConversation == null) {
        debugPrint('ไม่พบ Conversation ที่ตรงกับ Chat ปัจจุบัน');

        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
          });
        }

        return;
      }

      _conversationId = matchedConversation.id;

      debugPrint('พบ Conversation: $_conversationId');

      final historyMessages = await _historyService.getMessages(
        _conversationId!,
      );

      debugPrint(
        'พบข้อความทั้งหมด: '
        '${historyMessages.length}',
      );

      if (!mounted) {
        return;
      }

      final List<ChatMessage> loadedMessages = [];

      for (final doc in historyMessages) {
        final data = doc.data();

        final String role = data['role']?.toString() ?? 'assistant';

        final String text = data['text']?.toString() ?? '';

        if (text.trim().isEmpty) {
          continue;
        }

        DateTime messageTime = DateTime.now();

        final timestamp = data['timestamp'];

        if (timestamp is Timestamp) {
          messageTime = timestamp.toDate();
        }

        loadedMessages.add(
          ChatMessage(isAI: role == 'assistant', text: text, time: messageTime),
        );
      }

      setState(() {
        _isLoadingHistory = false;

        if (loadedMessages.isNotEmpty) {
          messages.addAll(loadedMessages);
        }
      });

      debugPrint(
        'โหลดประวัติสำเร็จ: '
        '${loadedMessages.length} ข้อความ',
      );

      debugPrint('======================================');

      _scrollToBottom();
    } catch (e) {
      debugPrint('โหลดประวัติการสนทนาไม่สำเร็จ: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  // ============================================================
  // สร้าง Conversation ใน Firestore
  // ============================================================

  Future<void> _createConversationIfNeeded(String firstMessage) async {
    if (_conversationId != null) {
      debugPrint('มี Conversation อยู่แล้ว: $_conversationId');

      return;
    }

    final bool isClassroom =
        widget.subjectCode != null && widget.subjectCode!.isNotEmpty;

    debugPrint('========== CREATE CONVERSATION ==========');

    debugPrint('type: ${isClassroom ? 'classroom' : 'general'}');

    debugPrint('subjectCode: ${widget.subjectCode}');

    debugPrint('sessionId: ${widget.sessionId}');

    debugPrint('title: ${_makeTitle(firstMessage)}');

    _conversationId = await _historyService.createConversation(
      type: isClassroom ? 'classroom' : 'general',
      subjectCode: widget.subjectCode,
      sessionId: widget.sessionId,
      title: _makeTitle(firstMessage),
    );

    debugPrint(
      'สร้าง Conversation สำเร็จ! '
      'ID: $_conversationId',
    );

    debugPrint('==========================================');
  }

  // ============================================================
  // สร้างชื่อบทสนทนาจากคำถามแรก
  // ============================================================

  String _makeTitle(String text) {
    final cleanText = text.trim();

    if (cleanText.length <= 40) {
      return cleanText;
    }

    return '${cleanText.substring(0, 40)}...';
  }

  // ============================================================
  // ส่งข้อความ
  // ============================================================

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) {
      return;
    }

    if (isSending) {
      return;
    }

    final String userMessage = _controller.text.trim();

    final Map<String, dynamic>? attachedEmotionData = _emotionData != null
        ? Map<String, dynamic>.from(_emotionData!)
        : null;

    final List<Map<String, dynamic>> attachedLessonMaterials =
        _selectedLessonMaterials
            .map((material) => Map<String, dynamic>.from(material))
            .toList();

    final Map<String, dynamic>? attachedChatFile = _chatUploadedFile != null
        ? Map<String, dynamic>.from(_chatUploadedFile!)
        : null;

    setState(() {
      messages.add(
        ChatMessage(
          isAI: false,
          text: userMessage,
          time: DateTime.now(),

          emotionData: attachedEmotionData,

          lessonMaterials: attachedLessonMaterials,

          fileName: attachedChatFile?['fileName']?.toString(),

          fileType: attachedChatFile?['fileType']?.toString(),
        ),
      );

      isSending = true;
    });

    _controller.clear();

    _scrollToBottom();

    try {
      await _createConversationIfNeeded(userMessage);

      final List<Map<String, dynamic>> materialsForAI = [
        ...attachedLessonMaterials,
      ];

      if (attachedChatFile != null) {
        materialsForAI.add(attachedChatFile);
      }

      debugPrint('========== SEND MESSAGE ==========');

      debugPrint('Message: $userMessage');

      debugPrint(
        'Emotion attached: '
        '${attachedEmotionData != null}',
      );

      debugPrint(
        'Lesson materials: '
        '${attachedLessonMaterials.length}',
      );

      debugPrint(
        'Chat uploaded file: '
        '${attachedChatFile?['fileName'] ?? 'ไม่มี'}',
      );

      debugPrint('==================================');

      try {
        await _historyService.saveMessage(
          conversationId: _conversationId!,
          role: 'user',
          text: userMessage,
        );
      } catch (e) {
        debugPrint('บันทึกข้อความ User ไม่สำเร็จ: $e');
      }

      final String answer = await _chatService.sendMessage(
        message: userMessage,

        emotionData: attachedEmotionData,

        subjectCode: widget.subjectCode,

        lessonMaterials: materialsForAI,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        messages.add(
          ChatMessage(isAI: true, text: answer, time: DateTime.now()),
        );

        _emotionData = null;
        _chatUploadedFile = null;
        _selectedLessonMaterials.clear();
      });

      _scrollToBottom();

      try {
        await _historyService.saveMessage(
          conversationId: _conversationId!,
          role: 'assistant',
          text: answer,
        );
      } catch (e) {
        debugPrint('บันทึกคำตอบ AI ไม่สำเร็จ: $e');
      }
    } catch (e) {
      debugPrint('Chat Error: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        messages.add(
          ChatMessage(
            isAI: true,
            text:
                "ไม่สามารถเชื่อมต่อได้\n"
                "กรุณาลองใหม่อีกครั้ง",
            time: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  void _showAIModelPicker() {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xff1E1B2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====================================================
              // Header
              // ====================================================
              Row(
                children: [
                  const Icon(
                    Icons.smart_toy_rounded,
                    color: Color(0xff8B7CF6),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'เลือก AI สำหรับการสนทนา',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                'เลือกโมเดล AI ที่ต้องการใช้ในการตอบคำถาม',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),

              const SizedBox(height: 16),

              // ====================================================
              // GPT-OSS 20B
              // ====================================================
              _buildAIModelOption(
                model: 'gpt-oss-120b',
                name: 'GPT-OSS 120B',
                description: '',
                icon: Icons.psychology_rounded,
              ),

              const SizedBox(height: 8),

              // ====================================================
              // Gemini
              // ====================================================
              _buildAIModelOption(
                model: 'gemini',
                name: 'Gemini',
                description: 'โมเดล AI จาก Google',
                icon: Icons.auto_awesome_rounded,
              ),

              const SizedBox(height: 8),

              // ====================================================
              // Gemma
              // ====================================================
              _buildAIModelOption(
                model: 'gemma',
                name: 'Gemma',
                description: 'โมเดล AI ขนาดเล็กจาก Google',
                icon: Icons.smart_toy_rounded,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildAIModelOption({
  required String model,
  required String name,
  required String description,
  required IconData icon,
}) {
  final bool isSelected = _selectedModel == model;

  return InkWell(
    onTap: () {
      setState(() {
        _selectedModel = model;
      });

      Navigator.pop(context);

      debugPrint('Selected AI Model: $_selectedModel');
    },
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xff6C52E5).withOpacity(0.18)
            : const Color(0xff151222),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xff8B7CF6) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          // AI Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xff6C52E5).withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xff8B7CF6), size: 21),
          ),

          const SizedBox(width: 12),

          // Name + Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                ),
              ],
            ),
          ),

          // Check
          if (isSelected)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xff8B7CF6),
              size: 21,
            ),
        ],
      ),
    ),
  );
}

  // ============================================================
  // App Bar
  // ============================================================

  Widget _buildAppBar() {
    final subject = widget.subjectCode;

    final bool isClassroom =
        widget.subjectCode != null && widget.subjectCode!.isNotEmpty;

    String subtitle;

    if (subject != null && subject.isNotEmpty) {
      subtitle = 'วิเคราะห์อารมณ์ · $subject';
    } else if (isClassroom) {
      subtitle = 'ผู้ช่วยสอน · ${widget.subjectCode}';
    } else {
      subtitle = 'ผู้ช่วยสอนอัจฉริยะ';
    }

    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _SquareButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EmotiTeach AI',
                    style: TextStyle(
                      color: _ChatColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ChatColors.veryFaintText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_ChatColors.accent, _ChatColors.cyan],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Text('🤖', style: TextStyle(fontSize: 17)),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLessonMaterialSelector() {
    if (widget.subjectCode == null || widget.subjectCode!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isLoadingMaterials) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_lessonMaterials.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff1E1B2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: Color(0xff8B7CF6)),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  'เอกสารที่ใช้ในการวิเคราะห์',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text(
                '${_selectedLessonMaterials.length}/${_lessonMaterials.length}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'เลือกไฟล์ที่ต้องการให้ AI ใช้ในการวิเคราะห์',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),

          const SizedBox(height: 10),

          ..._lessonMaterials.map((material) {
            final isSelected = _selectedLessonMaterials.any(
              (selected) => selected['id'] == material['id'],
            );

            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: isSelected,
              activeColor: const Color(0xff6C52E5),
              checkColor: Colors.white,
              title: Text(
                material['fileName']?.toString() ?? 'ไม่ทราบชื่อไฟล์',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: Text(
                material['fileType']?.toString() ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedLessonMaterials.add(material);
                  } else {
                    _selectedLessonMaterials.removeWhere(
                      (selected) => selected['id'] == material['id'],
                    );
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // Lesson Material Status
  // ============================================================

  Widget _buildLessonMaterialStatus() {
    if (widget.subjectCode == null || widget.subjectCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    String text;

    if (_isLoadingMaterials) {
      text = 'กำลังโหลดเนื้อหาบทเรียน...';
    } else if (_lessonMaterials.isEmpty) {
      text = 'ยังไม่มีเนื้อหาบทเรียนที่พร้อมใช้กับ AI';
    } else {
      text =
          '📚 โหลดเนื้อหาบทเรียนแล้ว '
          '${_lessonMaterials.length} ไฟล์';
    }

    return Container(
      height: 38,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _ChatColors.subtleSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _ChatColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(
            _isLoadingMaterials ? Icons.sync_rounded : Icons.menu_book_rounded,
            size: 16,
            color: _ChatColors.cyan,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ChatColors.mutedText,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Chat List
  // ============================================================

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: MessageBubble(
            message: messages[index],
            primaryColor: _ChatColors.accent,
          ),
        );
      },
    );
  }

  // ============================================================
  // Sending Indicator
  // ============================================================

  Widget _buildSendingIndicator() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: _ChatColors.cyan,
            ),
          ),

          SizedBox(width: 9),

          Text(
            'กำลังวิเคราะห์ข้อมูล...',
            style: TextStyle(color: _ChatColors.mutedText, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Quick Chips
  // ============================================================

  Widget _buildQuickChips() {
    const chips = <Map<String, String>>[
      {'icon': '📊', 'label': 'แนบข้อมูลอารมณ์'},
      {'icon': '📎', 'label': 'แนบสื่อการสอน'},
      {'icon': '💡', 'label': 'ขอคำแนะนำ'},
      //{'icon': '🕐', 'label': 'คาบที่แล้ว'},
    ];

    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: chips.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 7);
        },
        itemBuilder: (context, index) {
          final chip = chips[index];

          return InkWell(
            onTap: () {
              _handleQuickAction(chip['label']!);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 31,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: _ChatColors.subtleSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _ChatColors.inputBorder),
              ),
              child: Row(
                children: [
                  Text(chip['icon']!, style: const TextStyle(fontSize: 12)),

                  const SizedBox(width: 5),

                  Text(
                    chip['label']!,
                    style: const TextStyle(
                      color: _ChatColors.mutedText,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // Quick Action
  // ============================================================

  void _handleQuickAction(String label) {
    if (label == 'แนบสื่อการสอน') {
      _pickChatFile();
      return;
    }

    if (label == 'แนบข้อมูลอารมณ์') {
      _showEmotionSelectionDialog();
      return;
    }

    String text = label;

    if (label == 'ขอคำแนะนำ') {
      text = 'ขอคำแนะนำในการปรับการสอนจากข้อมูลนี้';
    } else if (label == 'คาบที่แล้ว') {
      text = 'ช่วยเปรียบเทียบกับข้อมูลคาบที่แล้ว';
    }

    _controller.text = text;

    _controller.selection = TextSelection.collapsed(offset: text.length);
  }

  // ============================================================
  // Input Bar
  // ============================================================

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 9, 20, 12),
      decoration: const BoxDecoration(
        color: Color(0x08FFFFFF),
        border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
      ),
      child: Row(
        children: [
          _SquareButton(
            icon: Icons.smart_toy_rounded,
            onTap: _showAIModelPicker,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _ChatColors.inputSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _ChatColors.inputBorder),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _controller,
                enabled: !isSending,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  sendMessage();
                },
                style: const TextStyle(
                  color: _ChatColors.primaryText,
                  fontSize: 12.5,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'พิมพ์ข้อความ หรือแนบไฟล์...',
                  hintStyle: TextStyle(
                    color: Color(0x40FFFFFF),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 9),

          SizedBox(
            width: 36,
            height: 36,
            child: Material(
              color: isSending
                  ? _ChatColors.accent.withOpacity(0.45)
                  : _ChatColors.accent,
              borderRadius: BorderRadius.circular(11),
              shadowColor: _ChatColors.accent.withOpacity(0.4),
              elevation: 7,
              child: InkWell(
                onTap: isSending
                    ? null
                    : () {
                        sendMessage();
                      },
                borderRadius: BorderRadius.circular(11),
                child: const Icon(
                  Icons.send_rounded,
                  size: 16,
                  color: _ChatColors.primaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Scroll ลงล่าง
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildAttachmentLoadingOverlay() {
    if (!_isLoadingAttachment) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black.withOpacity(0.65),
          child: Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xff1E1B2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: _ChatColors.accent,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'กำลังโหลดข้อมูล',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _attachmentLoadingText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'กรุณารอสักครู่...',
                    style: TextStyle(color: Colors.white38, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ChatColors.background,

      resizeToAvoidBottomInset: true,

      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.15, -1.15),
            radius: 1.05,
            colors: [
              Color(0xFF31245C),
              Color(0xFF171329),
              _ChatColors.background,
            ],
            stops: [0, 0.40, 1],
          ),
        ),

        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(),

                  // if (widget.subjectCode != null &&
                  //     widget.subjectCode!.isNotEmpty)
                  //   _buildLessonMaterialSelector(),

                  //_buildLessonMaterialStatus(),
                  Expanded(child: _buildChatList()),

                  if (isSending) _buildSendingIndicator(),

                  _buildEmotionStatus(),

                  _buildChatUploadedFile(),

                  _buildQuickChips(),

                  _buildInputBar(),
                ],
              ),
              _buildAttachmentLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }
}

// ============================================================
// Square Button
// ============================================================

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: _ChatColors.subtleSurface,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Icon(icon, size: 18, color: _ChatColors.mutedText),
        ),
      ),
    );
  }
}


