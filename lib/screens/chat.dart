import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
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
  // ============================================================
  // Emotion Data
  //
  // มีเฉพาะกรณีเข้ามาจากห้องเรียน
  // General Chat สามารถเป็น null ได้
  // ============================================================

  // ============================================================
  // Subject Code
  //
  // มีเฉพาะกรณีเข้ามาจากรายวิชา
  // ============================================================

  final String? subjectCode;

  // ============================================================
  // Session ID
  // ============================================================

  final String? sessionId;

  const ChatScreen({super.key, this.subjectCode, this.sessionId});

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

  // ============================================================
  // Conversation ID
  // ============================================================

  String? _conversationId;

  // ============================================================
  // Lesson Materials
  //
  // เก็บเนื้อหาบทเรียนที่อ่านจาก Firestore
  //
  // ตัวอย่าง:
  //
  // [
  //   {
  //     "id": "...",
  //     "fileName": "bayesian.pdf",
  //     "text": "...",
  //     "fileType": "application/pdf"
  //   }
  // ]
  // ============================================================

  List<Map<String, dynamic>> _lessonMaterials = [];
  List<Map<String, dynamic>> _selectedLessonMaterials = [];

  bool _isLoadingMaterials = false;

  // ============================================================
  // Chat Uploaded File
  //
  // ไฟล์ที่ผู้ใช้แนบจากหน้า Chat โดยตรง
  // ============================================================

  Map<String, dynamic>? _chatUploadedFile;

  bool _isReadingFile = false;

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
    _loadChatHistory();

    if (widget.subjectCode != null && widget.subjectCode!.isNotEmpty) {
      _loadLessonMaterials();
    }
  }

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

      if (file.bytes == null) {
        _showFileError('ไม่สามารถอ่านไฟล์ได้');
        return;
      }

      setState(() {
        _isReadingFile = true;
      });

      final String extension = file.extension?.toLowerCase() ?? '';

      String extractedText = '';

      // ==========================================================
      // PDF
      // ==========================================================

      if (extension == 'pdf') {
        extractedText = await _extractPdfText(file.bytes!);
      }
      // ==========================================================
      // TXT / MD / CSV
      // ==========================================================
      else if (extension == 'txt' || extension == 'md' || extension == 'csv') {
        extractedText = utf8.decode(file.bytes!, allowMalformed: true);
      }
      // ==========================================================
      // ไม่รองรับ
      // ==========================================================
      else {
        _showFileError('ไฟล์ประเภท .$extension ยังไม่รองรับ');

        return;
      }

      // ==========================================================
      // ตรวจว่ามีข้อความจริง
      // ==========================================================

      if (extractedText.trim().isEmpty) {
        _showFileError('ไม่พบข้อความในไฟล์นี้');

        return;
      }

      // ==========================================================
      // เก็บไฟล์ที่อัปโหลด
      // ==========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        // จำกัดข้อความที่ส่งให้ AI เพื่อไม่ให้ Request ใหญ่เกิน Groq TPM
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

      setState(() {
        _isReadingFile = false;
      });

      _showFileError('ไม่สามารถอ่านไฟล์ได้');
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

        // ==========================================================
        // AI Status
        // ==========================================================

        final String aiStatus = data['aiStatus']?.toString() ?? '';

        // ==========================================================
        // File Name
        // ==========================================================

        final String fileName =
            data['fileName']?.toString() ??
            data['name']?.toString() ??
            'ไม่ทราบชื่อไฟล์';

        // ==========================================================
        // File Type
        // ==========================================================

        final String fileType = data['fileType']?.toString() ?? '';

        // ==========================================================
        // อ่าน extractedText
        //
        // รองรับทั้ง 2 รูปแบบ
        //
        // แบบที่ 1:
        // extractedText: "เนื้อหา..."
        //
        // แบบที่ 2:
        // extractedText:
        // {
        //   text: "เนื้อหา...",
        //   type: "pdf"
        // }
        // ==========================================================

        final dynamic rawExtractedText = data['extractedText'];

        String extractedText = '';

        if (rawExtractedText is String) {
          extractedText = rawExtractedText;
        } else if (rawExtractedText is Map) {
          extractedText = rawExtractedText['text']?.toString() ?? '';
        }

        // ==========================================================
        // Debug
        // ==========================================================

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

        // ==========================================================
        // เอาเฉพาะไฟล์ที่อ่านเนื้อหาแล้ว
        // และมีข้อความจริง
        // ==========================================================

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

  // ============================================================
  // โหลดประวัติการสนทนา
  // ============================================================

  // ============================================================
  // โหลดประวัติการสนทนา
  // ============================================================

  Future<void> _loadChatHistory() async {
    try {
      debugPrint('========== LOAD CHAT HISTORY ==========');

      final bool isClassroom =
          widget.subjectCode != null && widget.subjectCode!.isNotEmpty;

      debugPrint('Chat type: ${isClassroom ? 'classroom' : 'general'}');

      debugPrint('subjectCode: ${widget.subjectCode}');

      debugPrint('sessionId: ${widget.sessionId}');

      // ==========================================================
      // ดึง Conversation ทั้งหมด
      // ==========================================================

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

      // ==========================================================
      // หา Conversation ที่ตรงกับ Chat ปัจจุบัน
      // ==========================================================

      QueryDocumentSnapshot<Map<String, dynamic>>? matchedConversation;

      for (final conversation in conversations) {
        final data = conversation.data();

        final String type = data['type']?.toString() ?? '';

        final String conversationSubjectCode =
            data['subjectCode']?.toString() ?? '';

        final String conversationSessionId =
            data['sessionId']?.toString() ?? '';

        // ========================================================
        // GENERAL CHAT
        // ========================================================

        if (!isClassroom) {
          if (type == 'general') {
            matchedConversation = conversation;
            break;
          }
        }
        // ========================================================
        // CLASSROOM CHAT
        // ========================================================
        else {
          // ต้องเป็น classroom เท่านั้น
          if (type != 'classroom') {
            continue;
          }

          // subjectCode ต้องตรงกับห้องที่กำลังเปิด
          if (conversationSubjectCode != widget.subjectCode) {
            continue;
          }

          // ======================================================
          // ถ้ามี sessionId
          // ให้ตรวจ sessionId ด้วย
          // ======================================================

          if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
            if (conversationSessionId != widget.sessionId) {
              continue;
            }
          }

          matchedConversation = conversation;
          break;
        }
      }

      // ==========================================================
      // ไม่พบ Conversation
      // ==========================================================

      if (matchedConversation == null) {
        debugPrint('ไม่พบ Conversation ที่ตรงกับ Chat ปัจจุบัน');

        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
          });
        }

        return;
      }

      // ==========================================================
      // เก็บ Conversation ID
      // ==========================================================

      _conversationId = matchedConversation.id;

      debugPrint('พบ Conversation: $_conversationId');

      // ==========================================================
      // ดึง Messages
      // ==========================================================

      final historyMessages = await _historyService.getMessages(
        _conversationId!,
      );

      debugPrint('พบข้อความทั้งหมด: ${historyMessages.length}');

      if (!mounted) {
        return;
      }

      // ==========================================================
      // แปลง Firestore → ChatMessage
      // ==========================================================

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

      // ==========================================================
      // แสดงประวัติ
      //
      // สำคัญ:
      // ไม่ clear messages
      //
      // เพราะเราต้องการให้ข้อความ Welcome
      // ยังคงอยู่ด้านบน
      // ==========================================================

      setState(() {
        _isLoadingHistory = false;

        if (loadedMessages.isNotEmpty) {
          messages.addAll(loadedMessages);
        }
      });

      debugPrint('โหลดประวัติสำเร็จ: ${loadedMessages.length} ข้อความ');

      debugPrint('======================================');

      // ==========================================================
      // เลื่อนไปล่างสุด
      // ==========================================================

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

    debugPrint('สร้าง Conversation สำเร็จ! ID: $_conversationId');

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

    // ==========================================================
    // เก็บข้อมูลที่แนบไว้ ณ ตอนกดส่ง
    //
    // สำคัญ:
    // ต้อง copy ออกมาก่อน
    // เพราะหลังส่งสำเร็จเราจะล้าง attachment
    // ==========================================================

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

    // ==========================================================
    // เพิ่มข้อความ User ลงหน้าจอ
    // พร้อมข้อมูลที่แนบ
    // ==========================================================

    setState(() {
      messages.add(
        ChatMessage(
          isAI: false,
          text: userMessage,
          time: DateTime.now(),

          // Emotion ที่แนบ
          emotionData: attachedEmotionData,

          // ไฟล์ที่เลือกจาก Lesson Material
          lessonMaterials: attachedLessonMaterials,

          // ไฟล์ที่แนบจากปุ่ม Attach
          fileName: attachedChatFile?['fileName']?.toString(),
          fileType: attachedChatFile?['fileType']?.toString(),
        ),
      );

      isSending = true;
    });

    _controller.clear();

    _scrollToBottom();

    try {
      // ==========================================================
      // สร้าง Conversation
      // ==========================================================

      await _createConversationIfNeeded(userMessage);

      // ==========================================================
      // รวมไฟล์ที่จะส่งให้ AI
      // ==========================================================

      final List<Map<String, dynamic>> materialsForAI = [
        ...attachedLessonMaterials,
      ];

      if (attachedChatFile != null) {
        materialsForAI.add(attachedChatFile);
      }

      // ==========================================================
      // Debug
      // ==========================================================

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

      // ==========================================================
      // บันทึกข้อความ User
      //
      // ตอนนี้เก็บข้อความก่อน
      // ส่วน attachment แสดงในหน้า Chat
      // ==========================================================

      try {
        await _historyService.saveMessage(
          conversationId: _conversationId!,
          role: 'user',
          text: userMessage,
        );
      } catch (e) {
        debugPrint('บันทึกข้อความ User ไม่สำเร็จ: $e');
      }

      // ==========================================================
      // ส่งไป Backend
      // ==========================================================

      final String answer = await _chatService.sendMessage(
        message: userMessage,

        // ส่ง Emotion เฉพาะตอนที่แนบ
        emotionData: attachedEmotionData,

        subjectCode: widget.subjectCode,

        // ส่งเฉพาะไฟล์ที่แนบ/เลือก
        lessonMaterials: materialsForAI,
      );

      // ==========================================================
      // แสดงคำตอบ AI
      // ==========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        messages.add(
          ChatMessage(isAI: true, text: answer, time: DateTime.now()),
        );

        // ========================================================
        // ล้าง Attachment หลังส่งสำเร็จ
        //
        // เพื่อให้ข้อความถัดไปไม่ส่งข้อมูลเดิมซ้ำ
        // ========================================================

        _emotionData = null;
        _chatUploadedFile = null;
        _selectedLessonMaterials.clear();
      });

      _scrollToBottom();

      // ==========================================================
      // บันทึกคำตอบ AI
      // ==========================================================

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

            // ======================================================
            // AI Icon
            // ======================================================
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

  // ============================================================
  // Context Card
  //
  // แสดงเฉพาะกรณีมี emotionData
  // ============================================================

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
  //
  // แสดงเมื่อเข้ามาจาก Subject
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
      {'icon': '🕐', 'label': 'คาบที่แล้ว'},
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
      _loadEmotionData();
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
          // ======================================================
          // Attach Button
          // ======================================================
          _SquareButton(icon: Icons.attach_file_rounded, onTap: _pickChatFile),

          const SizedBox(width: 9),

          // ======================================================
          // Text Field
          // ======================================================
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

          // ======================================================
          // Send Button
          // ======================================================
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
          child: Column(
            children: [
              // ==================================================
              // App Bar
              // ==================================================
              _buildAppBar(),

              // ==================================================
              // Emotion Context
              //
              // แสดงเฉพาะ Classroom ที่มี Emotion Data
              // ==================================================
              if (widget.subjectCode != null && widget.subjectCode!.isNotEmpty)
                _buildLessonMaterialSelector(),

              // ==================================================
              // Lesson Material Status
              //
              // แสดงเฉพาะตอนมี Subject
              // ==================================================
              _buildLessonMaterialStatus(),

              // ==================================================
              // Chat
              // ==================================================
              Expanded(child: _buildChatList()),

              // ==================================================
              // Sending Indicator
              // ==================================================
              if (isSending) _buildSendingIndicator(),
              _buildEmotionStatus(),
              _buildQuickChips(),
              _buildChatUploadedFile(),
              _buildInputBar(),
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
