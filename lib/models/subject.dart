class Subject {
  final String subjectCode;
  final String subjectName;
  final String year;
  final String semester;

  Subject({

    required this.subjectCode,
    required this.subjectName,
    required this.year,
    required this.semester
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'year': year,
      'semester': semester
    };
  }
}