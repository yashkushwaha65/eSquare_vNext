// lib/core/models/survey_attachment_mdl.dart

class SurveyAttachment {
  final String docName;
  final String filePath;
  final String filePath1; // Added this field
  final String containerNo;
  final String fileName;
  final String fileDesc;

  SurveyAttachment({
    required this.docName,
    required this.filePath,
    required this.filePath1, // Added to constructor
    required this.containerNo,
    required this.fileName,
    required this.fileDesc,
  });

  factory SurveyAttachment.fromJson(Map<String, dynamic> json) {
    return SurveyAttachment(
      docName: json['DocName'] as String,
      filePath: json['FilePath'] as String,
      filePath1: json['FilePath1'] as String, // Mapped from JSON
      containerNo: json['ContainerNo'] as String,
      fileName: json['FileName'] as String,
      fileDesc: json['FileDesc'] as String,
    );
  }
}