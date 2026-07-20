import 'package:flutter/material.dart';
import 'dart:async';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../services/prompt_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> emotionData;

  const ChatScreen({super.key, required this.emotionData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool showContext = true;
  Timer? timer;

  final Color backgroundColor = const Color(0xff151222);
  final Color primaryColor = const Color(0xff6A5CFF);

  final List<ChatMessage> messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),

            if (showContext) _buildContextCard(),

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

            _buildInputBar(),
          ],
        ),
      ),
    );
  }

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

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "EmotiTeach AI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  widget.emotionData["subject"] ?? "วิชาภาษา C เบื้องต้น",

                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),

          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: primaryColor,
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

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ดึงข้อมูลอารมณ์เรียบร้อยแล้ว",

                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  "${widget.emotionData["students"] ?? 32} คน",

                  style: const TextStyle(color: Colors.white60, fontSize: 12),
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

        // ปุ่ม +
        IconButton(
          onPressed: () {
            // ยังไม่ใช้งาน
          },
          icon: const Icon(
            Icons.add,
            color: Colors.white70,
          ),
        ),

        // ช่องพิมพ์
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
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ปุ่มส่ง
        IconButton(
          onPressed: () async {
            await sendMessage();
          },
          icon: Icon(
            Icons.send,
            color: primaryColor,
          ),
        ),
      ],
    ),
  );
}



Future<void> sendMessage() async {
  print("กดส่งแล้ว");
  if (_controller.text.trim().isEmpty) return;

  String userMessage = _controller.text;

  // แสดงข้อความของผู้ใช้
  setState(() {
    messages.add(
      ChatMessage(
        isAI: false,
        text: userMessage,
        time: DateTime.now(),
      ),
    );
  });

  _controller.clear();

  // เลื่อนลงล่าง
  Future.delayed(const Duration(milliseconds: 100), () {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  });

  try {
    // สร้าง Prompt
    String prompt = PromptService.buildPrompt(
      emotionData: widget.emotionData,
      question: userMessage,
    );

    // ส่งไปหา Ollama
    String answer = await ChatService().sendMessage(prompt);

    // แสดงคำตอบ AI
    setState(() {
      messages.add(
        ChatMessage(
          isAI: true,
          text: answer,
          time: DateTime.now(),
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  } catch (e) {
    setState(() {
      messages.add(
        ChatMessage(
          isAI: true,
          text: "❌ ไม่สามารถเชื่อมต่อ Ollama ได้\n$e",
          time: DateTime.now(),
        ),
      );
    });
  }
}
  

  @override
  void dispose() {
    timer?.cancel();

    _controller.dispose();

    _scrollController.dispose();

    super.dispose();
  }
}
