import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class EmotionBarChart extends StatelessWidget {
  final Map<String, int> emotions;

  const EmotionBarChart({
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

    int x = 0;

    return BarChart(
      BarChartData(
        barGroups: emotions.entries.map((e) {
          return BarChartGroupData(
            x: x++,
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                color: AppColors.accent,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}