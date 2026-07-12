import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EmotionSummaryWidget extends StatelessWidget {
  const EmotionSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref("emotionData");

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.snapshot.value == null) {
          return const _NoDataWidget();
        }

        final root =
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

        Map<String, dynamic>? emotionData;

        // ถ้ามี after ให้ใช้ after
        if (root["after"] != null &&
            (root["after"] as Map).isNotEmpty) {
          emotionData =
              Map<String, dynamic>.from(root["after"]);
        }
        // ถ้ายังไม่มี after ให้ใช้ before
        else if (root["before"] != null &&
            (root["before"] as Map).isNotEmpty) {
          emotionData =
              Map<String, dynamic>.from(root["before"]);
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

        double percent =
            (topCount / total) * 100;

        String emoji = _getEmoji(topEmotion);

        return Column(
          children: [

            Text(
              emoji,
              style: const TextStyle(
                fontSize: 45,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              topEmotion,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),

            Text(
              "${percent.toStringAsFixed(0)}% มากที่สุด",
              style: const TextStyle(
                color: Colors.white54,
              ),
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

        Text(
          "🙂",
          style: TextStyle(fontSize: 45),
        ),

        SizedBox(height: 5),

        Text(
          "ยังไม่มีข้อมูล",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),

        Text(
          "รอการประเมิน",
          style: TextStyle(
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}