// lib/core/models/detailsMdl.dart
class Details {
  final String category;
  final String examination;
  final String surveyType;
  final String containerInStatus;
  final String grade;
  final String cscAsp;
  final String doNo;
  final String doDate;
  final String description;
  final String condition; // ADDED: Field to hold the condition text

  Details({
    required this.category,
    required this.examination,
    required this.surveyType,
    required this.containerInStatus,
    required this.grade,
    required this.cscAsp,
    required this.doNo,
    required this.doDate,
    required this.description,
    required this.condition, // ADDED: To the constructor
  });
}