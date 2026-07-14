import 'dart:async';
import 'package:flutter/material.dart';



class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> emotionData;

  const ChatScreen({
    super.key,
    required this.emotionData,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showContextCard = true;
  Timer? _hideCardTimer;

  @override
  void initState() {
    super.initState();
    _hideCardTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showContextCard = false;
        });
      }
    });
  }

  // สีหลักของแอพ
  static const Color bgColor = Color(0xFF0E0D18);
  static const Color cardColor = Color(0xFF1A1828);
  static const Color accentPurple = Color(0xFF6C52E5);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentGreen = Color(0xFF1BAF7A);

  // Mock messages — ทีหลังค่อยเปลี่ยนเป็น API จริง
  final List<Map<String, dynamic>> _messages = [
    {
      'isAI': true,
      'type': 'emotion_summary',
      'text': 'สวัสดีครับ ผมวิเคราะห์ข้อมูลอารมณ์คาบวันนี้เรียบร้อยแล้ว นี่คือสรุปครับ 👇',
      'emotions': [
        {'emoji': '😐', 'label': 'ก่อนเรียน', 'value': '6.0'},
        {'emoji': '😕', 'label': 'ระหว่างเรียน', 'value': '5.4'},
        {'emoji': '😊', 'label': 'หลังเรียน', 'value': '7.6'},
      ],
      'time': '09:41',
    },
    {
      'isAI': true,
      'type': 'suggestion',
      'text': 'สิ่งที่น่าสังเกต: อารมณ์ลดลงช่วงนาทีที่ 40–50 นักเรียนหลายคนรู้สึก "สับสน" อาจมาจากเนื้อหาที่เข้มข้นเกินไปในช่วงนั้น',
      'suggestions': [
        {'icon': Icons.pause_circle_outline, 'title': 'เพิ่ม Mini Break', 'desc': 'นาทีที่ 40 ประมาณ 3–5 นาที'},
        {'icon': Icons.track_changes, 'title': 'ทบทวนหัวข้อ', 'desc': 'ที่ทำให้นักเรียนสับสนก่อนคาบหน้า'},
      ],
      'time': '09:41',
    },
    {
      'isAI': false,
      'type': 'text_with_file',
      'text': 'ช่วยดูสื่อการสอนของฉันหน่อยได้ไหม ว่าควรปรับยังไงให้เหมาะกับนักเรียนมากขึ้น',
      'fileName': 'บทเรียน_C_บทที่3.pdf',
      'time': '09:41',
    },
    {
      'isAI': true,
      'type': 'file_analysis',
      'text': 'ได้รับไฟล์แล้วครับ วิเคราะห์เทียบกับข้อมูลอารมณ์เสร็จแล้ว',
      'fileName': 'บทเรียน_C_บทที่3.pdf',
      'fileMeta': 'วิเคราะห์แล้ว · 24 หน้า',
      'suggestions': [
        {'icon': Icons.edit_note, 'title': 'หน้า 8–12', 'desc': 'เนื้อหา Pointer เข้มข้น ควรเพิ่ม code ตัวอย่างง่ายๆ คั่นกลาง'},
        {'icon': Icons.image_outlined, 'title': 'เพิ่ม Diagram', 'desc': 'แสดง memory allocation จะลดความสับสนได้มาก'},
        {'icon': Icons.check_circle_outline, 'title': 'หน้า 1–7', 'desc': 'ดีแล้ว เหมาะกับระดับนักเรียน'},
      ],
      'time': '09:42',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _showContextCard ? 1.0 : 0.0,
                child: _showContextCard
                    ? _buildContextCard()
                    : const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: _buildChatList(),
            ),
            _buildQuickChips(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // ปุ่มย้อนกลับ
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
              ),
              child: const Icon(Icons.chevron_left, color: Colors.white54, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // ชื่อ + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EmotiTeach AI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                Text(
                  'วิเคราะห์อารมณ์ · ${widget.emotionData['subject'] ?? 'วิชาภาษา C เบื้องต้น'}',
                  style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3)),
                ),
              ],
            ),
          ),
          // Avatar AI
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [accentPurple, accentCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }

  // ── CONTEXT CARD (ดึงข้อมูลกราฟอัตโนมัติ) ───────────────
  Widget _buildContextCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: accentPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accentPurple.withOpacity(0.28), width: 0.5),
      ),
      child: Row(
        children: [
          const Text('📊', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ดึงข้อมูลกราฟอัตโนมัติ',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                Text(
                  '${widget.emotionData['date'] ?? '10 ม.ค. 2569'} · ${widget.emotionData['students'] ?? 32} คน · 3 ช่วงเวลา',
                  style: TextStyle(fontSize: 9.5, color: Colors.white.withOpacity(0.4)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentGreen.withOpacity(0.3), width: 0.5),
            ),
            child: const Text('✓ โหลดแล้ว',
              style: TextStyle(fontSize: 9, color: Color(0xFF3DD99A), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── CHAT LIST ─────────────────────────────────────────────
  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: msg['isAI'] ? _buildAIBubble(msg) : _buildUserBubble(msg),
        );
      },
    );
  }

  // ── AI BUBBLE ─────────────────────────────────────────────
  Widget _buildAIBubble(Map<String, dynamic> msg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Avatar
        Container(
          width: 28, height: 28,
          margin: const EdgeInsets.only(top: 2, right: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [accentPurple, accentCyan],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Center(child: Text('🤖', style: TextStyle(fontSize: 13))),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg['text'],
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85), height: 1.55),
                    ),
                    if (msg['type'] == 'emotion_summary') ...[
                      const SizedBox(height: 10),
                      _buildEmotionChips(msg['emotions']),
                    ],
                    if (msg['suggestions'] != null) ...[
                      const SizedBox(height: 10),
                      _buildSuggestionCards(msg['suggestions']),
                    ],
                    if (msg['type'] == 'file_analysis') ...[
                      const SizedBox(height: 9),
                      _buildFileBox(msg['fileName'], msg['fileMeta']),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(msg['time'],
                style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.2)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionChips(List emotions) {
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: emotions.map<Widget>((e) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e['emoji'], style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(e['label'], style: TextStyle(fontSize: 9.5, color: Colors.white.withOpacity(0.5))),
            const SizedBox(width: 4),
            Text(e['value'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSuggestionCards(List suggestions) {
    return Column(
      children: suggestions.map<Widget>((s) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(s['icon'] as IconData, size: 15, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.5),
                  children: [
                    TextSpan(text: '${s['title']}  ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    TextSpan(text: s['desc']),
                  ],
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildFileBox(String fileName, String meta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFEDA100).withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(child: Text('📄', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                Text(meta, style: TextStyle(fontSize: 9.5, color: Colors.white.withOpacity(0.3))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── USER BUBBLE ───────────────────────────────────────────
  Widget _buildUserBubble(Map<String, dynamic> msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.all(13),
        decoration: const BoxDecoration(
          color: accentPurple,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg['text'],
              style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.55),
            ),
            if (msg['fileName'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📄', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(msg['fileName'],
                      style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── QUICK CHIPS ───────────────────────────────────────────
  Widget _buildQuickChips() {
    final chips = [
      {'icon': '📊', 'label': 'ดูกราฟเพิ่ม'},
      {'icon': '📎', 'label': 'แนบสื่อใหม่'},
      {'icon': '💡', 'label': 'ขอคำแนะนำ'},
      {'icon': '🕐', 'label': 'คาบที่แล้ว'},
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () {
            // TODO: handle quick action
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
            ),
            child: Row(
              children: [
                Text(chips[i]['icon']!, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text(chips[i]['label']!,
                  style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.55)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── INPUT BAR ─────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07), width: 0.5)),
      ),
      child: Row(
        children: [
          // ปุ่มแนบไฟล์
          GestureDetector(
            onTap: () {
              // TODO: implement file picker
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.attach_file, size: 18, color: Colors.white.withOpacity(0.45)),
            ),
          ),
          const SizedBox(width: 9),
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 12.5, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อความ หรือแนบไฟล์...',
                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.25)),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          // ปุ่ม Send
          GestureDetector(
            onTap: () {
              // TODO: send message + call AI API
              if (_controller.text.isNotEmpty) {
                _controller.clear();
              }
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: accentPurple,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [BoxShadow(color: accentPurple.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.send, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hideCardTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}