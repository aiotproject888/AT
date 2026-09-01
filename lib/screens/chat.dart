import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/chat_history_service.dart';
import '../models/chat_message.dart';
import '../widgets/message_bubble.dart';

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

  const ChatScreen({
    super.key,
    this.emotionData,
    this.subjectCode,
    this.sessionId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ============================================================
  // Chatbot
  // ============================================================

  final ChatService _chatService = ChatService();

  // ============================================================
  // Firestore Chat History
  // ============================================================

  final ChatHistoryService _historyService = ChatHistoryService();

  final List<ChatMessage> messages = [];

  bool isSending = false;

  // ============================================================
  // ID ของบทสนทนาใน Firestore
  // ============================================================

  String? _conversationId;

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

    setState(() {
      messages.add(
        ChatMessage(
          isAI: false,
          text: userMessage,
          time: DateTime.now(),
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
      // บันทึกข้อความ User ลง Firestore
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
      // ส่งคำถามไป Backend
      //
      // ส่วนนี้ใช้ Logic ของข้อ 1 เหมือนเดิม
      // ==========================================================

      final String answer = await _chatService.sendMessage(
        message: userMessage,
        emotionData: widget.emotionData,
      );

      // ==========================================================
      // แสดงคำตอบ AI
      // ==========================================================

      if (!mounted) return;

      setState(() {
        messages.add(
          ChatMessage(
            isAI: true,
            text: answer,
            time: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();

      // ==========================================================
      // บันทึกคำตอบ AI ลง Firestore
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

      if (!mounted) return;

      setState(() {
        messages.add(
          ChatMessage(
            isAI: true,
            text: "ไม่สามารถเชื่อมต่อได้",
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
    final subject = widget.emotionData?['subject']?.toString();

    final subtitle = subject == null || subject.isEmpty
        ? 'ผู้ช่วยสอนอัจฉริยะ'
        : 'วิเคราะห์อารมณ์ · $subject';

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
                  colors: [
                    _ChatColors.accent,
                    _ChatColors.cyan,
                  ],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Text(
                '🤖',
                style: TextStyle(fontSize: 17),
              ),
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
  // ไม่กระทบ Logic เดิม
  // ============================================================

  Widget _buildContextCard() {
    final data = widget.emotionData!;

    final date = data['date']?.toString() ?? 'ไม่ระบุวันที่';
    final students = data['students']?.toString() ?? '0';

    return Container(
      height: 59,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _ChatColors.accentSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _ChatColors.accentBorder,
        ),
      ),
      child: Row(
        children: [
          const Text(
            '📊',
            style: TextStyle(fontSize: 20),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ดึงข้อมูลกราฟอัตโนมัติ',
                  style: TextStyle(
                    color: _ChatColors.primaryText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'คาบ $date · $students คน',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ChatColors.faintText,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _ChatColors.greenSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _ChatColors.greenBorder,
              ),
            ),
            child: const Text(
              '✓ โหลดแล้ว',
              style: TextStyle(
                color: _ChatColors.greenText,
                fontSize: 9,
                fontWeight: FontWeight.w500,
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
            style: TextStyle(
              color: _ChatColors.mutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Quick Chips
  //
  // เป็น UI เพิ่มเข้ามาเท่านั้น
  // ไม่ไปยุ่งกับระบบส่งข้อความเดิม
  // ============================================================

  Widget _buildQuickChips() {
    const chips = <Map<String, String>>[
      {
        'icon': '📊',
        'label': 'ดูกราฟเพิ่ม',
      },
      {
        'icon': '📎',
        'label': 'แนบสื่อใหม่',
      },
      {
        'icon': '💡',
        'label': 'ขอคำแนะนำ',
      },
      {
        'icon': '🕐',
        'label': 'คาบที่แล้ว',
      },
    ];

    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 4,
        ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
              ),
              decoration: BoxDecoration(
                color: _ChatColors.subtleSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _ChatColors.inputBorder,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    chip['icon']!,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),

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
  //
  // แค่เติมข้อความลงช่อง Input
  // ยังไม่ได้เปลี่ยน Logic Chatbot
  // ============================================================

  void _handleQuickAction(String label) {
    if (label == 'แนบสื่อใหม่') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาเชื่อม File Picker ก่อนใช้งาน',
          ),
        ),
      );

      return;
    }

    String text = label;

    if (label == 'ดูกราฟเพิ่ม') {
      text = 'ช่วยวิเคราะห์ข้อมูลกราฟอารมณ์เพิ่มเติม';
    } else if (label == 'ขอคำแนะนำ') {
      text = 'ขอคำแนะนำในการปรับการสอนจากข้อมูลนี้';
    } else if (label == 'คาบที่แล้ว') {
      text = 'ช่วยเปรียบเทียบกับข้อมูลคาบที่แล้ว';
    }

    _controller.text = text;

    _controller.selection = TextSelection.collapsed(
      offset: text.length,
    );
  }

  // ============================================================
  // Input Bar
  // ============================================================

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        9,
        20,
        12,
      ),
      decoration: const BoxDecoration(
        color: Color(0x08FFFFFF),
        border: Border(
          top: BorderSide(
            color: Color(0x12FFFFFF),
          ),
        ),
      ),
      child: Row(
        children: [
          // ======================================================
          // Attach Button
          // ======================================================

          _SquareButton(
            icon: Icons.attach_file_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'กรุณาเชื่อม File Picker ก่อนใช้งาน',
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 9),

          // ======================================================
          // Text Field
          // ======================================================

          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: _ChatColors.inputSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _ChatColors.inputBorder,
                ),
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

              shadowColor:
                  _ChatColors.accent.withOpacity(0.4),

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
            stops: [
              0,
              0.40,
              1,
            ],
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),

              // Context Card
              if (widget.emotionData != null)
                _buildContextCard(),

              // Chat
              Expanded(
                child: _buildChatList(),
              ),

              // Sending Indicator
              if (isSending)
                _buildSendingIndicator(),

              // Quick Chips
              _buildQuickChips(),

              // Input
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

  const _SquareButton({
    required this.icon,
    required this.onTap,
  });

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

          child: Icon(
            icon,
            size: 18,
            color: _ChatColors.mutedText,
          ),
        ),
      ),
    );
  }
}