import 'package:flutter/material.dart';
import 'dart:ui';

import '/models/subject.dart';
import '/widgets/subjects_card.dart';
import '/screens/chat.dart';
import '/services/subject_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  List<Subject> subjects = [];

  final SubjectService _subjectService = SubjectService();

  @override
  void initState() {
    super.initState();

    loadSubjects();
  }

  Future<void> loadSubjects() async {
    try {
      final data = await _subjectService.getSubjects();

      setState(() {
        subjects = data;
      });
    } catch (e) {
      print('เกิดข้อผิดพลาดในการโหลดรายวิชา: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff151222),

      floatingActionButton: currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 138, 131, 216),
              elevation: 0,
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) {
                    return AddSubjectDialog(
                      onAdd: (subject) {
                        setState(() {
                          subjects.add(subject);
                        });
                      },
                    );
                  },
                );
              },

              child: const Icon(Icons.add, color: Colors.white, size: 45),
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xff171522),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,

        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          } else {
            setState(() {
              currentIndex = index;
            });
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: "วิชา",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "แชทบอท",
          ),
        ],
      ),

      body: currentIndex == 0
          ? SafeArea(
              child: Column(
                children: [
                  //HEADER
                  //================ HEADER =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 25),

                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xff4935A8),
                          Color(0xff30235F),
                          Color(0xff171522),
                        ],
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// ชื่อหน้า + รูปโปรไฟล์
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "รายวิชาของฉัน",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(height: 5),

                                  Text(
                                    "ยินดีต้อนรับ, อ.เอ็ม",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        /// Search Box
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),

                            child: Container(
                              height: 56,

                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.08),

                                borderRadius: BorderRadius.circular(30),

                                border: Border.all(color: Colors.white12),
                              ),

                              child: const TextField(
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),

                                decoration: InputDecoration(
                                  border: InputBorder.none,

                                  hintText: "ค้นหารายวิชา",

                                  hintStyle: TextStyle(color: Colors.white54),

                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Colors.white70,
                                  ),

                                  contentPadding: EdgeInsets.only(top: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  //Body
                  //================ BODY =================
                  Expanded(
                    child: subjects.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      size: 45,
                                      color: Colors.white70,
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  const Text(
                                    "ยังไม่มีรายวิชา",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  const Text(
                                    "กดปุ่ม + เพื่อเพิ่มรายวิชา\nแล้วเริ่มติดตามอารมณ์ของผู้เรียน",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                            children: [
                              /// หัวข้อ
                              Row(
                                children: [
                                  const Text(
                                    "รายวิชาทั้งหมด",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const Spacer(),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),

                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withOpacity(.25),
                                      borderRadius: BorderRadius.circular(30),
                                    ),

                                    child: Text(
                                      "${subjects.length} วิชา",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              ...subjects.map(
                                (subject) => Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: SubjectCard(subject: subject),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            )
          : const ChatScreen(),
    );
  }
}

//เพิ่มรายวิชาใหม่

class AddSubjectDialog extends StatefulWidget {
  final Function(Subject) onAdd;

  const AddSubjectDialog({super.key, required this.onAdd});

  @override
  State<AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<AddSubjectDialog> {
  final nameController = TextEditingController();
  final yearController = TextEditingController();
  final semesterController = TextEditingController();
  final codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xff343046),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),

      child: Padding(
        padding: const EdgeInsets.all(25),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "เพิ่มรายวิชาใหม่",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "กรอกข้อมูลวิชาที่ต้องการเพิ่ม",
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),

              const SizedBox(height: 25),

              const Text("ชื่อวิชา*", style: TextStyle(color: Colors.white70)),

              const SizedBox(height: 8),

              _TextField(controller: nameController),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "ปีการศึกษา*",
                          style: TextStyle(color: Colors.white70),
                        ),

                        const SizedBox(height: 8),

                        _TextField(controller: yearController),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "เทอม*",
                          style: TextStyle(color: Colors.white70),
                        ),

                        const SizedBox(height: 8),

                        _TextField(controller: semesterController),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text("รหัสวิชา*", style: TextStyle(color: Colors.white70)),

              const SizedBox(height: 8),

              _TextField(controller: codeController),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Subject subject = Subject(
                      subjectName: nameController.text.trim(),
                      year: yearController.text.trim(),
                      semester: semesterController.text.trim(),
                      subjectCode: codeController.text.trim(),
                    );

                    try {
                      // บันทึกข้อมูลลง Firebase
                      await SubjectService().createSubject(subject);

                      // อัปเดตข้อมูลในหน้าแอป
                      widget.onAdd(subject);

                      // ปิด Dialog
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      print('เกิดข้อผิดพลาดในการบันทึกวิชา: $e');
                    }
                  },

                  icon: const Icon(Icons.add, color: Colors.black),

                  label: const Text(
                    "เพิ่มรายวิชา",
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,

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
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;

  const _TextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black),

      decoration: InputDecoration(
        filled: true,

        fillColor: const Color.fromARGB(255, 255, 255, 255),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),

          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
