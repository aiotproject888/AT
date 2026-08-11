import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';

class EmotionSummaryWidget extends StatelessWidget {
  const EmotionSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference ref = FirebaseDatabase.instance.ref("emotionData");

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const _NoDataWidget();
        }

        final root = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );

        Map<String, dynamic>? emotionData;

        // ถ้ามี after ให้ใช้ after
        if (root["after"] != null && (root["after"] as Map).isNotEmpty) {
          emotionData = Map<String, dynamic>.from(root["after"]);
        }
        // ถ้ายังไม่มี after ให้ใช้ before
        else if (root["before"] != null && (root["before"] as Map).isNotEmpty) {
          emotionData = Map<String, dynamic>.from(root["before"]);
        }

        if (emotionData == null) {
          return const _NoDataWidget();
        }

        Map<String, int> counter = {};

        for (var item in emotionData.values) {
          final value = Map<String, dynamic>.from(item);

          String emotion = value["emotion"] ?? "ไม่ระบุ";

          counter[emotion] = (counter[emotion] ?? 0) + 1;
        }

        String topEmotion = "";
        int topCount = 0;

        counter.forEach((emotion, count) {
          if (count > topCount) {
            topEmotion = emotion;
            topCount = count;
          }
        });

        int total = emotionData.length;

        double percent = (topCount / total) * 100;

        String emoji = _getEmoji(topEmotion);

        return Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 45)),

            const SizedBox(height: 5),

            Text(
              topEmotion,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),

            Text(
              "${percent.toStringAsFixed(0)}% มากที่สุด",
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        );
      },
    );
  }

  String _getEmoji(String emotion) {
    switch (emotion) {
      case "รู้สึกสนใจ":
        return "🧐";

      case "รู้สึกตื่นเต้น":
        return "🤩";

      case "รู้กสึกสนุกสนาน":
        return "😄";

      case "รู้สึกเฉยๆ":
        return "😐";

      case "รู้สึกวิตกกังวล":
        return "😟";

      case "รู้สึกเครียด":
        return "🤯";

      case "รู้สึกเบื่อหน่าย":
        return "😒";

      case "รู้สึกกลัว":
        return "😨";

      default:
        return "🙂";
    }
  }
}

class _NoDataWidget extends StatelessWidget {
  const _NoDataWidget();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text("🙂", style: TextStyle(fontSize: 45)),

        SizedBox(height: 5),

        Text(
          "ยังไม่มีข้อมูล",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),

        Text("รอการประเมิน", style: TextStyle(color: Colors.white54)),
      ],
    );
  }
}

class EmotionDonutChart extends StatelessWidget {
  final Map<String, int> emotionData;

  const EmotionDonutChart({super.key, required this.emotionData});

  static const Color purple = Color(0xff7C5CFC);
  static const Color blue = Color(0xff4F8CFF);
  static const Color pink = Color(0xffD66BFF);

  @override
  Widget build(BuildContext context) {
    if (emotionData.isEmpty) {
      return const Center(
        child: Text(
          'ไม่มีข้อมูล',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    final total = emotionData.values.fold<int>(0, (sum, value) => sum + value);

    final sections = <PieChartSectionData>[];

    final colors = [
      purple,
      blue,
      pink,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.cyan,
      Colors.yellow,
    ];

    int index = 0;

    emotionData.forEach((emotion, count) {
      final percentage = (count / total) * 100;

      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          title: '${percentage.round()}%',
          radius: 55,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          color: colors[index % colors.length],
        ),
      );

      index++;
    });

    return Row(
      children: [
        // =========================
        // Donut Chart
        // =========================
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 190,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // =========================
        // Emoji Legend
        // =========================
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: emotionData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // จุดสี
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color:
                            colors[emotionData.keys.toList().indexOf(
                                  entry.key,
                                ) %
                                colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ชื่ออารมณ์
                    Expanded(
                      child: Text(
                        entry.key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // =========================
  // Emoji ของแต่ละ Emotion
  // =========================

  String _getEmotionEmoji(String emotion) {
    switch (emotion) {
      case "รู้สึกสนใจ":
        return "🧐";

      case "รู้สึกตื่นเต้น":
        return "🤩";

      case "รู้สึกสนุกสนาน":
        return "😄";

      case "รู้สึกเฉยๆ":
        return "😐";

      case "รู้สึกวิตกกังวล":
        return "😟";

      case "รู้สึกเครียด":
        return "🤯";

      case "รู้สึกเบื่อหน่าย":
        return "😒";

      case "รู้สึกกลัว":
        return "😨";

      default:
        return "🙂";
    }
  }
}
