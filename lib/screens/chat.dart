import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/chat_history_service.dart';
import '../models/chat_message.dart';
//import '../services/prompt_service.dart';
import '../widgets/message_bubble.dart';

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

  // Chatbot
  final ChatService _chatService = ChatService();

  // Firestore Chat History
  final ChatHistoryService _historyService = ChatHistoryService();

  final Color backgroundColor = const Color(0xff151222);
  final Color primaryColor = const Color(0xff6A5CFF);

  final List<ChatMessage> messages = [];

  bool isSending = false;

  // ============================================================
  // ID ของบทสนทนาใน Firestore
  //
  // จะสร้างครั้งเดียวเมื่อผู้ใช้ส่งข้อความครั้งแรก
  // แล้วใช้ ID เดิมไปตลอดการสนทนา
  // ============================================================
  String? _conversationId;

  @override
  void initState() {
    super.initState();

    //ข้อความเริ่มต้นของระบบ ไม่ใช่การสนทนาจริงไม่มีการบันทึกลง Firestore
    messages.add(
      ChatMessage(
        isAI: true,
        text:
            "สวัสดีครับ 👋 ยินดีต้อนรับสู่ EmotiTeach AI\nมีอะไรให้ผมช่วยไหมครับ?",
        time: DateTime.now(),
      ),
    );
  }

  // สร้าง Conversation ใน Firestore
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

  // สร้างชื่อบทสนทนาจากคำถามแรก
  String _makeTitle(String text) {
    final cleanText = text.trim();

    if (cleanText.length <= 40) {
      return cleanText;
    }

    return '${cleanText.substring(0, 40)}...';
  }

  //ส่งข้อความ
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
        ChatMessage(isAI: false, text: userMessage, time: DateTime.now()),
      );

      isSending = true;
    });

    _controller.clear();

    scrollToBottom();

    try {
      await _createConversationIfNeeded(userMessage);

      try {
        await _historyService.saveMessage(
          conversationId: _conversationId!,
          role: 'user',
          text: userMessage,
        );
      } catch (e) {
        debugPrint('บันทึกข้อความ User ไม่สำเร็จ: $e');
      }

      // 3. ส่งคำถามไป Backend
      String answer = await _chatService.sendMessage(
        message: userMessage,
        emotionData: widget.emotionData,
      );

      // แสดงคำตอบ AI
      setState(() {
        messages.add(
          ChatMessage(isAI: true, text: answer, time: DateTime.now()),
        );
      });

      scrollToBottom();

      // ทำการบันทึกคำตอบลง Firestore
      try {
        await _historyService.saveMessage(
          conversationId: _conversationId!,
          role: 'assistant',
          text: answer,
        );
      } catch (e) {
        // Firestore มีปัญหา
        // แต่ Chatbot ยังแสดงคำตอบได้ตามปกติ
        debugPrint('บันทึกคำตอบ AI ไม่สำเร็จ: $e');
      }
    } catch (e) {
      debugPrint('Chat Error: $e');

      setState(() {
        messages.add(
          ChatMessage(
            isAI: true,
            text: "ไม่สามารถเชื่อมต่อได้",
            time: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  // ============================================================
  // App Bar
  // ============================================================

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "EmotiTeach AI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xff6A5CFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text("🤖", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Context ข้อมูล Emotion
  // ============================================================

  Widget _buildContextCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(),
    );
  }

  // ============================================================
  // Input Bar
  // ============================================================

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add, color: Colors.white70),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xff24223A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "พิมพ์ข้อความ...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) {
                  sendMessage();
                },
              ),
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            onPressed: isSending
                ? null
                : () {
                    sendMessage();
                  },
            icon: Icon(
              Icons.send,
              color: isSending ? Colors.white30 : primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Scroll ลงล่าง
  // ============================================================

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),

            // แสดง Context เฉพาะเมื่อมีข้อมูล Emotion
            if (widget.emotionData != null) _buildContextCard(),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(
                    message: messages[index],
                    primaryColor: primaryColor,
                  );
                },
              ),
            ),

            if (isSending)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "กำลังวิเคราะห์ข้อมูล...",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }
}
