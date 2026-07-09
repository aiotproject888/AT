import 'package:flutter/material.dart';

Widget _beforeStudyCard(){

return Container(

padding: const EdgeInsets.all(18),

decoration: BoxDecoration(

color: const Color(0xff2A263D),

borderRadius: BorderRadius.circular(25),

),

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: [

Text(

"ก่อนเรียน",

style: TextStyle(

color: Colors.white,

fontWeight: FontWeight.bold,

fontSize: 20,

),

),

SizedBox(height:20),

SizedBox(

height:220,

child: DoughnutChart(),

),

SizedBox(height:20),

SizedBox(

height:220,

child: EmotionBarChart(),

),

],

),

);

}