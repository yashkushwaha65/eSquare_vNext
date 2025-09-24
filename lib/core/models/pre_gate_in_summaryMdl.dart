// lib/core/models/pre_gate_in_summaryMdl.dart

import 'package:esquare/core/models/survey_attachment_mdl.dart';

class PreGateInSummary {
  final int srNo;
  final int surveyID;
  final String containerNo;
  final String containerType;
  final String vehicleNo;
  final double grossWt;
  final double tareWt;
  final double payLoad;
  final int size;
  final String lineName;
  final String surveyDate;
  final String isoCode;
  final String category;
  final String surveyType;
  final String containerStatus;
  final String condition;
  final int mfgYear;
  final String mfgMonth;
  final String surveyNo;
  final String addedBy;
  final List<SurveyAttachment> attachments;

  PreGateInSummary({
    required this.srNo,
    required this.surveyID,
    required this.containerNo,
    required this.containerType,
    required this.vehicleNo,
    required this.grossWt,
    required this.tareWt,
    required this.payLoad,
    required this.size,
    required this.lineName,
    required this.surveyDate,
    required this.isoCode,
    required this.category,
    required this.surveyType,
    required this.containerStatus,
    required this.condition,
    required this.mfgYear,
    required this.mfgMonth,
    required this.surveyNo,
    required this.addedBy,
    this.attachments = const [],
  });

  factory PreGateInSummary.fromJson(Map<String, dynamic> json) {
    return PreGateInSummary(
      srNo: json['SRNo'] as int,
      surveyID: json['SurveyID'] as int,
      containerNo: json['ContainerNo'] as String,
      containerType: json['ContainerType'] as String,
      vehicleNo: json['VehicleNo'] as String,
      grossWt: (json['GrossWt'] as num).toDouble(),
      tareWt: (json['TareWt'] as num).toDouble(),
      payLoad: (json['PayLoad'] as num).toDouble(),
      size: json['Size'] as int,
      lineName: json['LineName'] as String,
      surveyDate: json['SurveyDate'] as String,
      isoCode: json['ISOCode'] as String,
      category: json['Category'] as String,
      surveyType: json['SurveyType'] as String,
      containerStatus: json['ContainerStatus'] as String,
      condition: json['Condition'] as String,
      mfgYear: json['MFGYear'] as int,
      mfgMonth: json['MFGMonth'] as String,
      surveyNo: json['SurveyNo'] as String,
      addedBy: json['AddedBy'] as String,
      attachments: [], // Correctly initialized
    );
  }

  PreGateInSummary copyWith({
    int? srNo,
    int? surveyID,
    String? containerNo,
    String? containerType,
    String? vehicleNo,
    double? grossWt,
    double? tareWt,
    double? payLoad,
    int? size,
    String? lineName,
    String? surveyDate,
    String? isoCode,
    String? category,
    String? surveyType,
    String? containerStatus,
    String? condition,
    int? mfgYear,
    String? mfgMonth,
    String? surveyNo,
    String? addedBy,
    List<SurveyAttachment>? attachments,
  }) {
    return PreGateInSummary(
      srNo: srNo ?? this.srNo,
      surveyID: surveyID ?? this.surveyID,
      containerNo: containerNo ?? this.containerNo,
      containerType: containerType ?? this.containerType,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      grossWt: grossWt ?? this.grossWt,
      tareWt: tareWt ?? this.tareWt,
      payLoad: payLoad ?? this.payLoad,
      size: size ?? this.size,
      lineName: lineName ?? this.lineName,
      surveyDate: surveyDate ?? this.surveyDate,
      isoCode: isoCode ?? this.isoCode,
      category: category ?? this.category,
      surveyType: surveyType ?? this.surveyType,
      containerStatus: containerStatus ?? this.containerStatus,
      condition: condition ?? this.condition,
      mfgYear: mfgYear ?? this.mfgYear,
      mfgMonth: mfgMonth ?? this.mfgMonth,
      surveyNo: surveyNo ?? this.surveyNo,
      addedBy: addedBy ?? this.addedBy,
      attachments: attachments ?? this.attachments,
    );
  }
}
