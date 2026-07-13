import 'package:flutter/material.dart';
import '/models/subjects.dart';
import '/widgets/subjects_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  List<Subject> subjects = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff151222),

      floatingActionButton: FloatingActionButton(
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
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        backgroundColor: const Color(0xff171522),

        selectedItemColor: Colors.white,

        unselectedItemColor: Colors.white54,

        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: "วิชา",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "แชทบอท",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "บัญชี",
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            //---------------- HEADER ----------------//
            Container(
              width: double.infinity,

              padding: const EdgeInsets.only(
                left: 25,
                right: 25,
                top: 25,
                bottom: 35,
              ),

              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xff4C3AA8),
                    Color(0xff34256F),
                    Color(0xff241D54),
                  ],

                ),
                
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "รายวิชาของฉัน",

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 34,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "ยินดีต้อนรับ , อ.สมชาย",

                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),

                  const SizedBox(height: 28),

                  Container(
                    height: 60,

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff68618C), Color(0xff575070)],
                      ),
                      
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: const TextField(
                      style: TextStyle(color: Colors.white),

                      decoration: InputDecoration(
                        border: InputBorder.none,

                        hintText: "ค้นหารายวิชา",

                        hintStyle: TextStyle(color: Colors.white60),

                        prefixIcon: Icon(Icons.search, color: Colors.white70),
                      ),
                    ),

                    
                  ),
                ],
              ),
            ),

            //---------------- BODY ----------------//
            Expanded(
              child: subjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: const [
                          SizedBox(height: 18),

                          Text(
                            "ยังไม่มีรายวิชา",

                            style: TextStyle(
                              color: Colors.white38,

                              fontSize: 32,

                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 10),

                          Text(
                            "กดปุ่ม + เพื่อเพิ่มรายวิชา",

                            style: TextStyle(
                              color: Colors.white24,

                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: subjects.length,

                      itemBuilder: (context, index) {
                        Subject subject = subjects[index];

                        return SubjectCard(subject: subjects[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
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
                  onPressed: () {
                    Subject subject = Subject(
                      subjectName: nameController.text,
                      year: yearController.text,
                      semester: semesterController.text,
                      subjectCode: codeController.text,
                    );

                    widget.onAdd(subject);

                    Navigator.pop(context);
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
