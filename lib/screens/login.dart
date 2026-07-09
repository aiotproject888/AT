import 'package:flutter/material.dart';
import '/screens/home.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff2A1D63),
              Color(0xff0D0B1A),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 40),

                //------------------ LOGO ------------------
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.psychology_alt,
                    color: Color(0xffB388FF),
                    size: 60,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.deepPurple,
                    ),
                  ),
                  child: const Text(
                    "E-Tutor AI",
                    style: TextStyle(
                      color: Color(0xffB388FF),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Emoti",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: "Teach",
                        style: TextStyle(
                          color: Color(0xff8E5BFF),
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "AI-powered intelligent teaching assistant",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 25),

                Container(
                  width: 80,
                  height: 2,
                  color: Colors.white24,
                ),

                const SizedBox(height: 30),

                const Text(
                  "ออกแบบมาเพื่อช่วยให้ผู้สอนเข้าใจอารมณ์\nของนักเรียนและสนับสนุนการบริหารจัดการเรียนการสอน\nให้มีประสิทธิภาพยิ่งขึ้น",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),

                const SizedBox(height: 50),

                //---------------- USERNAME ----------------

                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "ชื่อผู้ใช้",
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.white70,
                    ),
                    filled: true,
                    fillColor: Colors.white12,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 22,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                //---------------- PASSWORD ----------------

                TextField(
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "รหัสผ่าน",
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.white70,
                    ),
                    filled: true,
                    fillColor: Colors.white12,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 22,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "ลืมรหัสผ่าน?",
                      style: TextStyle(
                        color: Color(0xff8E5BFF),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                //---------------- LOGIN BUTTON ----------------

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: 
                  ElevatedButton.icon(
                    onPressed: () {Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );},
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.black,
                    ),
                    label: const Text(
                      "เข้าสู่ระบบ",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "ยังไม่มีบัญชี? ",
                      style: TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        "สมัครสมาชิก",
                        style: TextStyle(
                          color: Color(0xff8E5BFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}