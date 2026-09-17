import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class EmotionPieChart extends StatelessWidget {
  final Map<String, int> emotions;

  const EmotionPieChart({
    super.key,
    required this.emotions,
  });

  @override
  Widget build(BuildContext context) {
    if (emotions.isEmpty) {
      return const Center(
        child: Text(
          "ยังไม่มีข้อมูล",
          style: TextStyle(color: AppColors.primaryText),
        ),
      );
    }

    final colors = [
      AppColors.pieGreen,
      AppColors.pieOrange,
      AppColors.pieBlue,
      AppColors.pieGrey,
      AppColors.pieYellow,
      AppColors.pieRed,
      AppColors.piePurple,
      AppColors.pieBrown,
    ];

    int i = 0;

    return PieChart(
      PieChartData(
        sections: emotions.entries.map((e) {
          return PieChartSectionData(
            color: colors[i++ % colors.length],
            value: e.value.toDouble(),
            title: e.value.toString(),
            radius: 70,
            titleStyle: const TextStyle(
              color: AppColors.onAccent,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
    );
  }
}