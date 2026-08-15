import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home.dart';

class _FigmaColors {
  // Values read from Figma frame 93:1768.
  static const background = Color(0xFF0E0D18);
  static const accent = Color(0xFF7C5FE6);
  static const white = Color(0xFFFFFFFF);
  static const textMuted = Color(0x73FFFFFF); // white 45%

  static const chipBackground = Color(0x1A6C52E5); // #6C52E5 10%
  static const chipBorder = Color(0x406C52E5); // #6C52E5 25%

  static const fieldBackground = Color(0x33D9D9D9); // #D9D9D9 20%
  static const fieldBorder = Color(0x26FFFFFF); // white 15%
  static const inputBackground = Color(0x80FFFFFF); // white 50%

  // Colors sampled from the two blurred decorative layers in the frame.
  static const purpleGlow = Color(0x6B5A46C7);
  static const blueGlow = Color(0x4D2D5979);
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const double _figmaWidth = 393;
  static const double _figmaSafeHeight = 817;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _FigmaColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _FigmaColors.background,
        body: LayoutBuilder(
          builder: (context, screenConstraints) {
            final backgroundScale = screenConstraints.maxWidth / _figmaWidth;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: _FigmaColors.background),
                ),
                _backgroundGlow(
                  left: -13 * backgroundScale,
                  top: -140 * backgroundScale,
                  size: 420 * backgroundScale,
                  color: _FigmaColors.purpleGlow,
                ),
                _backgroundGlow(
                  left: 213 * backgroundScale,
                  top: 60 * backgroundScale,
                  size: 280 * backgroundScale,
                  color: _FigmaColors.blueGlow,
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final scale = math.min(
                          1.0,
                          constraints.maxWidth / _figmaWidth,
                        );

                        return Center(
                          child: SizedBox(
                            width: constraints.maxWidth,
                            height: _figmaSafeHeight * scale,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: _figmaWidth,
                                height: _figmaSafeHeight,
                                child: _buildFigmaLayout(context),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _backgroundGlow({
    required double left,
    required double top,
    required double size,
    required Color color,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: color.a * 0.35),
                Colors.transparent,
              ],
              stops: const [0.0, 0.48, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFigmaLayout(BuildContext context) {
    return Stack(
      children: [
        // Logo: Figma y 106, minus the 35 px status bar.
        Positioned(
          left: 145,
          top: 71,
          width: 99,
          height: 91,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 91,
                height: 91,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _FigmaColors.accent.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _FigmaColors.accent.withValues(alpha: 0.025),
                  border: Border.all(
                    color: _FigmaColors.accent.withValues(alpha: 0.28),
                  ),
                ),
              ),
              SizedBox(
                width: 61,
                height: 61,
                child: Image.asset(
                  'assets/images/emotiteach_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),

        Positioned(
          left: 129,
          top: 180,
          width: 131,
          height: 33,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _FigmaColors.chipBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _FigmaColors.chipBorder),
            ),
            child: const Text(
              'E-Tutor AI',
              style: TextStyle(
                color: _FigmaColors.accent,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.6,
              ),
            ),
          ),
        ),

        Positioned(
          left: 0,
          right: 0,
          top: 237,
          child: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                color: _FigmaColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.64,
              ),
              children: [
                TextSpan(text: 'Emoti'),
                TextSpan(
                  text: 'Teach',
                  style: TextStyle(color: _FigmaColors.accent),
                ),
              ],
            ),
          ),
        ),

        const Positioned(
          left: 0,
          right: 0,
          top: 279,
          child: Text(
            'AI-powered intelligent teaching assistant',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _FigmaColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
            ),
          ),
        ),

        Positioned(
          left: 160,
          top: 325,
          width: 70,
          height: 1,
          child: ColoredBox(
            color: _FigmaColors.white.withValues(alpha: 0.45),
          ),
        ),

        const Positioned(
          left: 24,
          right: 24,
          top: 359,
          child: Text(
            'ออกแบบมาเพื่อช่วยให้ผู้สอนเข้าใจอารมณ์\n'
            'ของนักเรียนและสนับสนุนการบริหารจัดการการเรียนการสอน\n'
            'ให้มีประสิทธิภาพยิ่งขึ้น',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _FigmaColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ),

        const Positioned(
          left: 46,
          top: 452,
          width: 300,
          height: 71,
          child: _FigmaInputField(
            icon: Icons.person_outline,
            hintText: 'ชื่อผู้ใช้',
          ),
        ),

        const Positioned(
          left: 46,
          top: 535,
          width: 300,
          height: 71,
          child: _FigmaInputField(
            icon: Icons.lock_outline,
            hintText: 'รหัสผ่าน',
            obscureText: true,
          ),
        ),

        Positioned(
          right: 55,
          top: 605,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'ลืมรหัสผ่าน?',
                style: TextStyle(
                  color: _FigmaColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),

        Positioned(
          left: 98,
          top: 652,
          width: 199,
          height: 37,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              elevation: 0,
              backgroundColor: _FigmaColors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 22,
                  child: Text(
                    '→',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          left: 0,
          right: 0,
          top: 768,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ยังไม่มีบัญชี?  ',
                style: TextStyle(
                  color: _FigmaColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'สมัครสมาชิก',
                  style: TextStyle(
                    color: _FigmaColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FigmaInputField extends StatelessWidget {
  const _FigmaInputField({
    required this.icon,
    required this.hintText,
    this.obscureText = false,
  });

  final IconData icon;
  final String hintText;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _FigmaColors.fieldBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _FigmaColors.fieldBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            icon,
            color: _FigmaColors.white.withValues(alpha: 0.82),
            size: 24,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: SizedBox(
              height: 33,
              child: TextField(
                obscureText: obscureText,
                cursorColor: _FigmaColors.accent,
                style: const TextStyle(
                  color: Color(0xFF28262E),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: Color(0x8A28262E),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: _FigmaColors.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: _FigmaColors.white,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: _FigmaColors.white,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: _FigmaColors.accent,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}
