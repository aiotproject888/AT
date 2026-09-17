import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:firebase_database/firebase_database.dart';

import '../constants/app_colors.dart';

class EmotionSummaryWidget extends StatefulWidget {

  final String subjectCode;

  const EmotionSummaryWidget({

    super.key,

    required this.subjectCode,

  });

  @override

  State<EmotionSummaryWidget> createState() =>

      _EmotionSummaryWidgetState();

}

class _EmotionSummaryWidgetState extends State<EmotionSummaryWidget> {

  StreamSubscription<DatabaseEvent>? _emotionSubscription;

  Map<String, int> _emotionCounts = {};

  bool _isLoading = true;

  String _currentDateString() {

    final now = DateTime.now();

    return '${now.year.toString().padLeft(4, '0')}-'

        '${now.month.toString().padLeft(2, '0')}-'

        '${now.day.toString().padLeft(2, '0')}';

  }

  @override

  void initState() {

    super.initState();

    _startRealtimeListener();

  }

  @override

  void didUpdateWidget(covariant EmotionSummaryWidget oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (oldWidget.subjectCode != widget.subjectCode) {

      _startRealtimeListener();

    }

  }

  void _startRealtimeListener() {

    _emotionSubscription?.cancel();

    final date = _currentDateString();

    final beforeRef = FirebaseDatabase.instance.ref(

      'emotion_data/${widget.subjectCode}/before_class_$date',

    );

    final afterRef = FirebaseDatabase.instance.ref(

      'emotion_data/${widget.subjectCode}/after_class_$date',

    );

    // ฟังทั้ง before และ after

    _emotionSubscription = beforeRef.onValue.listen((_) {

      _loadTodayEmotion();

    });

    afterRef.onValue.listen((_) {

      _loadTodayEmotion();

    });

    _loadTodayEmotion();

  }

  Future<void> _loadTodayEmotion() async {

    try {

      final date = _currentDateString();

      final beforeSnapshot = await FirebaseDatabase.instance

          .ref(

            'emotion_data/${widget.subjectCode}/before_class_$date',

          )

          .get();

      final afterSnapshot = await FirebaseDatabase.instance

          .ref(

            'emotion_data/${widget.subjectCode}/after_class_$date',

          )

          .get();

      DatabaseEvent? selectedEvent;

      Map<String, dynamic>? beforeData;

      Map<String, dynamic>? afterData;

      if (beforeSnapshot.exists && beforeSnapshot.value is Map) {

        beforeData = Map<String, dynamic>.from(

          beforeSnapshot.value as Map,

        );

      }

      if (afterSnapshot.exists && afterSnapshot.value is Map) {

        afterData = Map<String, dynamic>.from(

          afterSnapshot.value as Map,

        );

      }

      // ถ้ามี after ให้ใช้ after

      // ถ้ายังไม่มี after ให้ใช้ before

      final Map<String, dynamic>? selectedData =

          afterData != null && afterData.isNotEmpty

              ? afterData

              : beforeData;

      if (selectedData == null || selectedData.isEmpty) {

        if (!mounted) return;

        setState(() {

          _emotionCounts = {};

          _isLoading = false;

        });

        return;

      }

      final Map<String, int> counts = {};

      for (final item in selectedData.values) {

        if (item is! Map) continue;

        final record = Map<String, dynamic>.from(item);

        final emotion =

            record['emotion_name'] ??

            record['emotion'] ??

            'ไม่ระบุ';

        final counterValue = record['counter'];

        int counter = 1;

        if (counterValue is int) {

          counter = counterValue;

        } else if (counterValue is num) {

          counter = counterValue.toInt();

        }

        counts[emotion.toString()] =

            (counts[emotion.toString()] ?? 0) + counter;

      }

      if (!mounted) return;

      setState(() {

        _emotionCounts = counts;

        _isLoading = false;

      });

    } catch (e) {

      debugPrint(

        'โหลด Emotion ของ ${widget.subjectCode} ไม่สำเร็จ: $e',

      );

      if (!mounted) return;

      setState(() {

        _emotionCounts = {};

        _isLoading = false;

      });

    }

  }

  @override

  void dispose() {

    _emotionSubscription?.cancel();

    super.dispose();

  }

  String _getEmoji(String emotion) {

    switch (emotion) {

      case "รู้สึกสนใจ":

        return "😊";

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

  @override

  Widget build(BuildContext context) {

    if (_isLoading) {

      return const SizedBox(

        height: 62,

        child: Center(

          child: SizedBox(

            width: 18,

            height: 18,

            child: CircularProgressIndicator(

              strokeWidth: 2,

              color: AppColors.accent,

            ),

          ),

        ),

      );

    }

    if (_emotionCounts.isEmpty) {

      return const _NoDataWidget();

    }

    return _buildEmotionSummary();

  }

  Widget _buildEmotionSummary() {

    final total = _emotionCounts.values.fold<int>(

      0,

      (sum, value) => sum + value,

    );

    if (total == 0) {

      return const _NoDataWidget();

    }

    final sortedEmotions = _emotionCounts.entries.toList()

      ..sort((a, b) => b.value.compareTo(a.value));

    final topEmotion = sortedEmotions.first;

    final topPercent =

        ((topEmotion.value / total) * 100).round();

    // แสดงอารมณ์รองได้สูงสุด 3 อารมณ์

    final otherEmotions = sortedEmotions.skip(1).take(3).toList();

    return Row(

      crossAxisAlignment: CrossAxisAlignment.center,

      children: [

        // ==========================

        // อารมณ์หลัก

        // ==========================

        SizedBox(

          width: 92,

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Text(

                _getEmoji(topEmotion.key),

                style: const TextStyle(

                  fontSize: 25,

                ),

              ),

              const SizedBox(height: 2),

              Text(

                topEmotion.key,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                textAlign: TextAlign.center,

                style: const TextStyle(

                  color: AppColors.primaryText,

                  fontSize: 11,

                  fontWeight: FontWeight.w500,

                ),

              ),

              const SizedBox(height: 2),

              Text(

                '$topPercent% มากที่สุด',

                style: const TextStyle(

                  color: AppColors.lightSecondaryText,

                  fontSize: 9,

                ),

              ),

            ],

          ),

        ),

        // เส้นแบ่ง

        Container(

          width: 1,

          height: 48,

          color: AppColors.surfaceBorder,

        ),

        const SizedBox(width: 12),

        // ==========================

        // Emotion รอง

        // ==========================

        Expanded(

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              ...otherEmotions.map((entry) {

                final percent =

                    ((entry.value / total) * 100).round();

                return Padding(

                  padding: const EdgeInsets.symmetric(

                    vertical: 3,

                  ),

                  child: Row(

                    children: [

                      SizedBox(

                        width: 22,

                        child: Text(

                          _getEmoji(entry.key),

                          style: const TextStyle(

                            fontSize: 13,

                          ),

                        ),

                      ),

                      const SizedBox(width: 4),

                      Expanded(

                        child: ClipRRect(

                          borderRadius:

                              BorderRadius.circular(10),

                          child: LinearProgressIndicator(

                            value: entry.value / total,

                            minHeight: 5,

                            backgroundColor:

                                AppColors.navigationBorder,

                            valueColor:

                                const AlwaysStoppedAnimation<

                                    Color>(

                              AppColors.accent,

                            ),

                          ),

                        ),

                      ),

                      const SizedBox(width: 7),

                      SizedBox(

                        width: 27,

                        child: Text(

                          '$percent%',

                          textAlign: TextAlign.right,

                          style: const TextStyle(

                            color: AppColors.lightSecondaryText,

                            fontSize: 9,

                          ),

                        ),

                      ),

                    ],

                  ),

                );

              }),

            ],

          ),

        ),

      ],

    );

  }

}

class _NoDataWidget extends StatelessWidget {

  const _NoDataWidget();

  @override

  Widget build(BuildContext context) {

    return const SizedBox(

      height: 62,

      child: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Text(

              'ยังไม่มีข้อมูล',

              style: TextStyle(

                color: AppColors.secondaryText,

                fontSize: 14,

                fontWeight: FontWeight.w500,

              ),

            ),

            SizedBox(height: 2),

            Text(

              'รอการประเมิน',

              style: TextStyle(

                color: AppColors.lightMutedText,

                fontSize: 10,

              ),

            ),

          ],

        ),

      ),

    );

  }

}













class EmotionDonutChart extends StatelessWidget {

  final Map<String, int> emotionData;

  const EmotionDonutChart({

    super.key,

    required this.emotionData,

  });

  Color _getEmotionColor(String emotion) {

  switch (emotion) {

    case 'รู้สึกสนใจ':

      return AppColors.emotionInterested; // ส้ม

    case 'รู้สึกตื่นเต้น':

      return AppColors.emotionExcited; // แดง

    case 'รู้สึกสนุกสนาน':

      return AppColors.emotionFun; // เหลือง

    case 'รู้สึกเฉยๆ':

      return AppColors.emotionNeutral; // เทา

    case 'รู้สึกเบื่อหน่าย':

      return AppColors.emotionBored; // น้ำตาล

    case 'รู้สึกกลัว':

      return AppColors.emotionAfraid; // น้ำเงินเข้ม

    case 'รู้สึกวิตกกังวล':

      return AppColors.emotionAnxious; // ม่วง

    case 'รู้สึกเครียด':

      return AppColors.emotionStressed; // เขียวเข้มอมเทา

    default:

      return AppColors.emotionNeutral; // ไม่ระบุ

  }

}

  @override

  Widget build(BuildContext context) {

    if (emotionData.isEmpty) {

      return const Center(

        child: Text(

          'รอการประเมิน',

          style: TextStyle(

            color: AppColors.lightMutedText,

            fontSize: 14,

          ),

        ),

      );

    }

    final total = emotionData.values.fold<int>(

      0,

      (sum, value) => sum + value,

    );

    final sections = <PieChartSectionData>[];





    emotionData.forEach((emotion, count) {

      sections.add(

        PieChartSectionData(

          value: count.toDouble(),

          title: '$count คน',

          radius: 55,

          titleStyle: const TextStyle(

            color: AppColors.onAccent,

            fontSize: 11,

            fontWeight: FontWeight.bold,

          ),

         color: _getEmotionColor(emotion),

        ),

      );

    });

    return Row(

      children: [

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

                    Container(

                      width: 10,

                      height: 10,

                      decoration: BoxDecoration(

                        color: _getEmotionColor(entry.key),

                        shape: BoxShape.circle,

                      ),

                    ),

                    const SizedBox(width: 8),

                    Expanded(

                      child: Text(

                        entry.key,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(

                          color: AppColors.secondaryText,

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

}