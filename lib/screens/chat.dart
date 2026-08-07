import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../services/prompt_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  // ข้อมูลอารมณ์จะถูกส่งเข้ามาเฉพาะตอนที่มาจาก Dashboard
  final Map<String, dynamic>? emotionData;

  const ChatScreen({super.key, this.emotionData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Color backgroundColor = const Color(0xff151222);
  final Color primaryColor = const Color(0xff6A5CFF);

  final List<ChatMessage> messages = [];

  bool isSending = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),

            // แสดง Context เฉพาะเมื่อมีข้อมูลอารมณ์
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

  //App Bar

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

  // Context ข้อมูล Emotion

  Widget _buildContextCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text("📊", style: TextStyle(fontSize: 20)),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ข้อมูลอารมณ์ของรายวิชา",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  "AI สามารถนำข้อมูลนี้ไปใช้ในการวิเคราะห์ได้",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),

          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

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

  //ส่งข้อความ

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) {
      return;
    }

    if (isSending) {
      return;
    }

    String userMessage = _controller.text.trim();

    // แสดงข้อความของผู้ใช้
    setState(() {
      messages.add(
        ChatMessage(isAI: false, text: userMessage, time: DateTime.now()),
      );

      isSending = true;
    });

    _controller.clear();

    scrollToBottom();

    try {
      String prompt;

      //ถ้ามีข้อมูล Emotion
      if (widget.emotionData != null) {
        prompt = PromptService.buildPrompt(
          emotionData: widget.emotionData!,
          question: userMessage,
        );
      }
      // ถ้าไม่มีข้อมูล Emotion
      else {
        prompt = PromptService.buildNormalPrompt(question: userMessage);
      }

      // ส่ง Prompt ไป Ollama
      String answer = await ChatService().sendMessage(prompt);

      // แสดงคำตอบ AI
      setState(() {
        messages.add(
          ChatMessage(isAI: true, text: answer, time: DateTime.now()),
        );
      });

      scrollToBottom();
    } catch (e) {
      setState(() {
        messages.add(
          ChatMessage(
            isAI: true,
            text: "ไม่สามารถเชื่อมต่อกับ Ollama ได้",
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
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }
}
