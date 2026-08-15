import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EmotionPieChart extends StatelessWidget {

  final Map<String,int> emotions;

  const EmotionPieChart({
    super.key,
    required this.emotions,
  });

  @override
  Widget build(BuildContext context) {

    if(emotions.isEmpty){
      return const Center(
        child: Text(
          "ยังไม่มีข้อมูล",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final colors=[
      Colors.green,
      Colors.orange,
      Colors.blue,
      Colors.grey,
      Colors.yellow,
      Colors.red,
      Colors.purple,
      Colors.brown
    ];

    int i=0;

    return PieChart(

      PieChartData(

        sections:

        emotions.entries.map((e){

          return PieChartSectionData(

            color:colors[i++%colors.length],

            value:e.value.toDouble(),

            title:e.value.toString(),

            radius:70,

            titleStyle:const TextStyle(
              color:Colors.white,
              fontWeight:FontWeight.bold,
            ),

          );

        }).toList(),

      ),

    );

  }

}